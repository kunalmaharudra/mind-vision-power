
create extension if not exists pgcrypto;

create type public.app_role as enum ('admin','student');
create type public.account_status as enum ('active','inactive','deleted');
create type public.kyc_state as enum ('not_submitted','pending','approved','rejected');
create type public.review_state as enum ('pending','approved','rejected');

create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 role public.app_role not null default 'student',
 student_code text unique,
 full_name text,
 email text,
 phone text,
 status public.account_status not null default 'active',
 blocked_until timestamptz,
 kyc_status public.kyc_state not null default 'not_submitted',
 created_at timestamptz not null default now()
);

create table public.courses (
 id uuid primary key default gen_random_uuid(),
 title text not null,
 description text,
 thumbnail_path text,
 published boolean not null default false,
 created_by uuid references public.profiles(id),
 created_at timestamptz not null default now()
);

create table public.course_files (
 id uuid primary key default gen_random_uuid(),
 course_id uuid not null references public.courses(id) on delete cascade,
 file_name text not null,
 storage_path text not null,
 mime_type text,
 size_bytes bigint,
 uploaded_by uuid references public.profiles(id),
 created_at timestamptz not null default now()
);

create table public.enrollments (
 id uuid primary key default gen_random_uuid(),
 student_id uuid not null references public.profiles(id) on delete cascade,
 course_id uuid not null references public.courses(id) on delete cascade,
 created_at timestamptz not null default now(),
 unique(student_id,course_id)
);

-- NOTE: sensitive KYC fields are access-restricted by RLS. For production, add
-- application-level field encryption or use a compliant KYC vendor before collecting real data.
create table public.student_kyc (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null unique references public.profiles(id) on delete cascade,
 pan_number text not null,
 bank_account text not null,
 ifsc text not null,
 address text not null,
 review_status public.review_state not null default 'pending',
 reviewed_by uuid references public.profiles(id),
 reviewed_at timestamptz,
 created_at timestamptz not null default now()
);

create table public.login_events (
 id uuid primary key default gen_random_uuid(),
 user_id uuid references public.profiles(id) on delete set null,
 event_type text not null,
 created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.profiles where id=auth.uid() and role='admin' and status='active'); $$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public
as $$
begin
 insert into public.profiles(id,full_name,email,phone,role)
 values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),new.email,new.raw_user_meta_data->>'phone','student')
 on conflict(id) do nothing;
 return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.courses enable row level security;
alter table public.course_files enable row level security;
alter table public.enrollments enable row level security;
alter table public.student_kyc enable row level security;
alter table public.login_events enable row level security;

create policy "profiles self read or admin" on public.profiles for select using (id=auth.uid() or public.is_admin());
create policy "profiles self update limited" on public.profiles for update using (id=auth.uid()) with check (id=auth.uid());
create policy "admin manage profiles" on public.profiles for all using (public.is_admin()) with check (public.is_admin());

create policy "students read published courses and admins all" on public.courses for select using (published=true or public.is_admin());
create policy "admins manage courses" on public.courses for all using (public.is_admin()) with check (public.is_admin());

create policy "admins manage course files" on public.course_files for all using (public.is_admin()) with check (public.is_admin());
create policy "enrollments own or admin" on public.enrollments for select using (student_id=auth.uid() or public.is_admin());
create policy "admins manage enrollments" on public.enrollments for all using (public.is_admin()) with check (public.is_admin());

create policy "kyc owner insert read update or admin" on public.student_kyc for all using (user_id=auth.uid() or public.is_admin()) with check (user_id=auth.uid() or public.is_admin());
create policy "login events own or admin" on public.login_events for select using (user_id=auth.uid() or public.is_admin());

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('course-files','course-files',false,52428800,array['video/mp4','video/webm','application/pdf','image/jpeg','image/png','image/webp'])
on conflict(id) do nothing;

create policy "admins upload course files" on storage.objects for insert to authenticated with check (bucket_id='course-files' and public.is_admin());
create policy "admins read course files" on storage.objects for select to authenticated using (bucket_id='course-files' and public.is_admin());
