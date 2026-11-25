"use server";

import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { safeNext } from "@/lib/auth";

export type SignInState =
  | { stage: "email"; error?: string; email?: string }
  | { stage: "code"; email: string; next: string; error?: string };

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// Only people the club already knows get a login: a member whose profile
// staff created, or someone with a staff invite. Everyone else gets the same
// reply, so this form can't be used to find out who is a member.
async function isKnown(email: string): Promise<boolean> {
  const admin = createAdminClient();
  const [profile, invite] = await Promise.all([
    admin.from("profiles").select("id").eq("email", email).is("archived_at", null).maybeSingle(),
    admin.from("staff_invites").select("email").eq("email", email).maybeSingle(),
  ]);
  return Boolean(profile.data || invite.data);
}

// Public sign-up is switched off in Supabase, so a known person's login
// account is made here the first time they ask for a link. Making it links
// their profile and any staff invite (the on_auth_user_created trigger).
async function ensureLoginAccount(email: string): Promise<void> {
  const admin = createAdminClient();
  const { error } = await admin.auth.admin.createUser({ email, email_confirm: true });
  if (error && error.code !== "email_exists" && error.status !== 422) throw error;
}

async function siteOrigin(): Promise<string> {
  const h = await headers();
  const origin = h.get("origin");
  if (origin) return origin;
  const host = h.get("x-forwarded-host") ?? h.get("host");
  const proto = h.get("x-forwarded-proto") ?? "https";
  return `${proto}://${host}`;
}

export async function requestSignIn(_prev: SignInState, formData: FormData): Promise<SignInState> {
  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  const next = safeNext(formData.get("next"));

  if (!EMAIL.test(email)) {
    return { stage: "email", email, error: "Enter the email address you gave the club." };
  }

  if (await isKnown(email)) {
    await ensureLoginAccount(email);
    const supabase = await createClient();
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: {
        shouldCreateUser: false,
        emailRedirectTo: `${await siteOrigin()}/auth/confirm?next=${encodeURIComponent(next)}`,
      },
    });
    if (error) {
      if (error.status === 429) {
        return { stage: "email", email, error: "Too many tries. Wait a minute, then ask for a new link." };
      }
      return { stage: "email", email, error: "We couldn't send the email just now. Try again in a minute." };
    }
  }

  return { stage: "code", email, next };
}

export async function verifyCode(_prev: SignInState, formData: FormData): Promise<SignInState> {
  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  const token = String(formData.get("code") ?? "").replace(/\s+/g, "");
  const next = safeNext(formData.get("next"));

  if (!/^[0-9]{6,10}$/.test(token)) {
    return { stage: "code", email, next, error: "The code is the 6 digits in the email." };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.verifyOtp({ email, token, type: "email" });
  if (error) {
    return {
      stage: "code",
      email,
      next,
      error: "That code didn't work. It may have expired: ask for a new one below.",
    };
  }

  redirect(next);
}
