# Mind Vision Power Portal (Vercel starter)

This is a fresh portal project inspired by the uploaded Mind Vision Power backup structure and requested workflows. It does **not** overwrite or modify the existing Hostinger site.

## What is included
- Separate `/admin/login` and `/student/login` routes.
- Admin dashboard UI for student management, course folders, uploads and KYC review.
- Student dashboard UI and KYC form.
- Supabase Auth + database schema with role-aware Row Level Security policies.
- Private `course-files` storage bucket.
- Admin-created student accounts through a server-side API (service key never goes to the browser).
- Student ID generation, account status and temporary blocking fields.

## Important setup before deployment
This repository is a deployable application scaffold, not a live configured service. You must create a Supabase project and configure its keys. No real admin credentials are embedded in the code.

1. Create a Supabase project.
2. Open SQL Editor and run `supabase/schema.sql`.
3. In Supabase Authentication, create your first admin user with a strong password.
4. In SQL Editor, promote that user's profile to admin:
   `update public.profiles set role = 'admin' where id = (select id from auth.users where email = 'YOUR_ADMIN_EMAIL');`
5. Add the three environment variables from `.env.example` to Vercel Project Settings → Environment Variables.
6. Deploy the GitHub repository to Vercel.
7. Create student users from the Admin → Students page.

## Routes
- `/admin/login`
- `/admin`
- `/student/login`
- `/student`
- `/student/kyc`

## Payments
Payment is deliberately **not marked paid automatically** in this starter. A real Razorpay integration requires your Razorpay Key ID/Secret and a server-side webhook that verifies the signature before setting `payment_status='paid'`. Never trust a browser success message. Add credentials only in Vercel environment variables, never in GitHub.

## KYC and privacy
The requested PAN and bank account fields are sensitive. This starter stores them in a restricted KYC table with RLS that limits reads to the student who owns the record and admins. Before collecting real KYC, add an encryption-at-rest strategy or use a compliant KYC provider, publish a privacy notice, define retention/deletion rules, and restrict staff access. Do not use real personal data in testing.

## Video storage
Course files use a private Supabase Storage bucket. For production video libraries, consider a dedicated video streaming provider (e.g. Mux or Cloudflare Stream) rather than serving large raw video files directly from a general-purpose bucket. The starter upload UI is intended for ordinary course files and modest uploads.

## Device access
No device fingerprint or single-device lock is implemented. Sessions are not restricted by device count. Protect admin accounts with strong passwords and MFA in Supabase.

## Existing website
The old Hostinger backup is not copied wholesale into this new project because it contains WordPress core, plugins, configuration files and potentially private credentials. This app is a clean rebuild of the requested portal workflows; the old site remains untouched.
