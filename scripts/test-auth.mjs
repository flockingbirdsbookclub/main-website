// End-to-end sign-in checks against a running site and the STAGING project.
//
//   node --env-file=.env.local scripts/test-auth.mjs [base url]
//
// Creates throwaway accounts at example.test, signs them in with links made
// by the secret key (so no email is sent), checks who can reach what, then
// deletes everything it made. Never point it at production.
import { createClient } from "@supabase/supabase-js";

const BASE = process.argv[2] ?? "http://localhost:3100";
const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
if (!url?.includes("eqanskhfqaxtbxhdafiw")) throw new Error("Only run this against the staging project.");
const admin = createClient(url, process.env.SUPABASE_SECRET_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

const STAFF = "e2e-staff@example.test";
const MEMBER = "e2e-member@example.test";
const STRANGER = "e2e-stranger@example.test";
let failures = 0;

function check(cond, name) {
  console.log(`${cond ? "ok  " : "FAIL"}  ${name}`);
  if (!cond) failures++;
}

// A tiny browser: keeps cookies, doesn't follow redirects.
class Browser {
  jar = new Map();
  async go(path, init = {}) {
    const res = await fetch(BASE + path, {
      ...init,
      redirect: "manual",
      headers: { ...(init.headers ?? {}), cookie: [...this.jar].map(([k, v]) => `${k}=${v}`).join("; ") },
    });
    for (const c of res.headers.getSetCookie()) {
      const [pair] = c.split(";");
      const i = pair.indexOf("=");
      const name = pair.slice(0, i);
      const value = pair.slice(i + 1);
      if (value === "" || /max-age=0/i.test(c)) this.jar.delete(name);
      else this.jar.set(name, value);
    }
    return { status: res.status, location: res.headers.get("location") ?? "", text: await res.text() };
  }
}

async function signInLink(email, next) {
  const { data, error } = await admin.auth.admin.generateLink({ type: "magiclink", email });
  if (error) throw error;
  return `/auth/confirm?token_hash=${data.properties.hashed_token}&type=magiclink&next=${encodeURIComponent(next)}`;
}

async function cleanup() {
  const { data } = await admin.auth.admin.listUsers({ perPage: 200 });
  for (const u of data?.users ?? []) {
    if (u.email?.endsWith("@example.test")) await admin.auth.admin.deleteUser(u.id);
  }
  await admin.from("profiles").delete().like("email", "%@example.test");
  await admin.from("staff_invites").delete().like("email", "%@example.test");
}

try {
  await cleanup();

  // Signed out
  const visitor = new Browser();
  let r = await visitor.go("/admin");
  check(r.status === 307 && r.location.includes("/login?next=%2Fadmin"), "signed out: /admin sends you to sign in");
  r = await visitor.go("/account");
  check(r.status === 307 && r.location.includes("/login?next=%2Faccount"), "signed out: /account sends you to sign in");
  r = await visitor.go("/login");
  check(r.status === 200 && r.text.includes("Email me a sign-in link"), "the sign-in page loads");
  check(/noindex/.test(r.text), "the sign-in page is hidden from search engines");
  r = await visitor.go("/");
  check(r.status === 200 && r.text.includes("Member sign in"), "the homepage links to sign in");

  // Staff: invited, signs in, reaches /admin
  await admin.from("staff_invites").insert({ email: STAFF, role: "admin" });
  await admin.auth.admin.createUser({ email: STAFF, email_confirm: true });
  const staff = new Browser();
  r = await staff.go(await signInLink(STAFF, "/admin"));
  check(r.status === 307 && r.location.endsWith("/admin"), "staff: the email link signs you in and goes to /admin");
  r = await staff.go("/admin");
  check(r.status === 200 && r.text.includes("signed in as <!-- -->an admin"), "staff: /admin opens, showing the role");
  r = await staff.go("/login");
  check(r.status === 307, "staff: the sign-in page skips ahead when already signed in");
  r = await staff.go("/auth/signout", { method: "POST" });
  check(r.status === 303 && new URL(r.location).pathname === "/", "sign out goes back to the homepage");
  r = await staff.go("/admin");
  check(r.status === 307 && r.location.includes("/login"), "after signing out, /admin asks you to sign in again");

  // Member with a profile, not staff
  await admin.from("profiles").insert({ email: MEMBER, slug: "e2e-member", full_name: "Test Member", status: "submitted" });
  await admin.auth.admin.createUser({ email: MEMBER, email_confirm: true });
  const { data: linked } = await admin.from("profiles").select("user_id").eq("email", MEMBER).single();
  check(Boolean(linked?.user_id), "member: the profile is linked to the login on first sign-in");
  const member = new Browser();
  await member.go(await signInLink(MEMBER, "/account"));
  r = await member.go("/account");
  check(r.status === 200 && r.text.includes("Hello, Test"), "member: /account shows their profile");
  r = await member.go("/admin");
  check(r.status === 307 && r.location.includes("/account?notice=not-staff"), "member: /admin is refused");

  // Signed in, but no profile and no invite
  await admin.auth.admin.createUser({ email: STRANGER, email_confirm: true });
  const stranger = new Browser();
  await stranger.go(await signInLink(STRANGER, "/account"));
  r = await stranger.go("/account");
  check(r.status === 200 && r.text.includes("No profile yet"), "stranger: /account says there is no profile");
  r = await stranger.go("/admin");
  check(r.status === 307 && r.location.includes("not-staff"), "stranger: /admin is refused");

  // Bad links
  r = await new Browser().go("/auth/confirm?token_hash=not-a-real-token&type=magiclink&next=%2Fadmin");
  check(r.status === 307 && r.location.includes("/login?error=link"), "a broken link explains itself on the sign-in page");
  const evil = new Browser();
  r = await evil.go(await signInLink(STAFF, "//evil.example"));
  check(r.status === 307 && new URL(r.location).host === new URL(BASE).host,
        "a link can't send you to another website after signing in");
  const reused = await signInLink(MEMBER, "/account");
  await new Browser().go(reused);
  r = await new Browser().go(reused);
  check(r.location.includes("/login?error=link"), "a sign-in link works only once");
} finally {
  await cleanup();
  const { data } = await admin.auth.admin.listUsers({ perPage: 200 });
  check(!(data?.users ?? []).some((u) => u.email?.endsWith("@example.test")), "cleanup: test accounts deleted");
}

console.log(failures ? `\n${failures} check(s) failed.` : "\nAll sign-in checks passed.");
process.exit(failures ? 1 : 0);
