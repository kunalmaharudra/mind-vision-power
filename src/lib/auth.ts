import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
export async function requireRole(role:"admin"|"student"){
 const supabase=await createClient();
 const {data:{user}}=await supabase.auth.getUser();
 if(!user) redirect(role==="admin"?"/admin/login":"/student/login");
 const {data:profile}=await supabase.from("profiles").select("role,status,full_name,student_code,blocked_until").eq("id",user.id).single();
 if(!profile || profile.role!==role) redirect(role==="admin"?"/admin/login":"/student/login");
 if(profile.status!=="active" || (profile.blocked_until && new Date(profile.blocked_until)>new Date())) redirect(role==="admin"?"/admin/login?error=access":"/student/login?error=access");
 return {supabase,user,profile};
}
