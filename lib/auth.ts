import "server-only";
import { cache } from "react";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

// Who is signed in, checked properly: getClaims() verifies the session's
// signature, unlike reading the cookie. Pages and actions in /admin and
// /account call these; proxy.ts only does a quick cookie check.
// cache() means each request asks Supabase once, however many components ask.

export type SignedInUser = { id: string; email: string };
export type StaffRole = "admin" | "editor";

export const getSignedInUser = cache(async (): Promise<SignedInUser | null> => {
  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();
  const claims = data?.claims;
  if (!claims?.sub) return null;
  return { id: claims.sub, email: typeof claims.email === "string" ? claims.email : "" };
});

// Staff can read their own row in staff_roles; nobody else's.
export const getStaffRole = cache(async (): Promise<StaffRole | null> => {
  const user = await getSignedInUser();
  if (!user) return null;
  const supabase = await createClient();
  const { data } = await supabase.from("staff_roles").select("role").eq("user_id", user.id).maybeSingle();
  return (data?.role as StaffRole | undefined) ?? null;
});

/** Only lets signed-in people through. */
export async function requireUser(next: string): Promise<SignedInUser> {
  const user = await getSignedInUser();
  if (!user) redirect(`/login?next=${encodeURIComponent(next)}`);
  return user;
}

/** Only lets staff through. A signed-in member who isn't staff goes to their account. */
export async function requireStaff(next: string): Promise<{ user: SignedInUser; role: StaffRole }> {
  const user = await requireUser(next);
  const role = await getStaffRole();
  if (!role) redirect("/account?notice=not-staff");
  return { user, role };
}

/** A path inside this site to go to after signing in. Anything else becomes /account. */
export function safeNext(value: unknown): string {
  if (typeof value !== "string") return "/account";
  if (!value.startsWith("/") || value.startsWith("//") || value.startsWith("/\\")) return "/account";
  return value;
}
