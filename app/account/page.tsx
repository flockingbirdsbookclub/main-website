import type { Metadata } from "next";
import Link from "next/link";
import { getStaffRole, requireUser } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { DeskHeader } from "@/components/layout/DeskHeader";

export const metadata: Metadata = {
  title: "Your account · Flocking Birds Book Club",
  robots: { index: false },
};

const STATUS_TEXT: Record<string, string> = {
  draft: "Not sent for review yet.",
  submitted: "With the team for review.",
  published: "On the mural.",
  rejected: "Sent back with a note from the team.",
};

export default async function AccountPage({
  searchParams,
}: {
  searchParams: Promise<{ notice?: string }>;
}) {
  const user = await requireUser("/account");
  const [{ notice }, role, supabase] = await Promise.all([searchParams, getStaffRole(), createClient()]);

  // Columns are named: profiles holds emails, which select * is refused.
  const { data: profile } = await supabase
    .from("profiles")
    .select("slug, full_name, status")
    .eq("user_id", user.id)
    .maybeSingle();

  return (
    <>
      <DeskHeader title="Your account" email={user.email} />
      <main className="desk">
        <div className="wrap">
          {notice === "not-staff" ? (
            <p className="desk-notice" role="status">
              That part of the site is for the team. Here is your own account instead.
            </p>
          ) : null}

          <h1>{profile ? `Hello, ${profile.full_name.split(" ")[0]}` : "You're signed in"}</h1>

          {profile ? (
            <section className="desk-card">
              <h2>Your profile</h2>
              <p>
                <b>{profile.full_name}</b>. {STATUS_TEXT[profile.status] ?? ""}
              </p>
              <p className="desk-soon">
                Editing your photo, profession, fun fact and links arrives with the Show Your Work
                Mural.
              </p>
            </section>
          ) : (
            <section className="desk-card">
              <h2>No profile yet</h2>
              <p>
                We don&apos;t have a member profile for {user.email}. If you&apos;re in a flock, ask
                your flock leader to add you.
              </p>
            </section>
          )}

          {role ? (
            <section className="desk-card">
              <h2>Team</h2>
              <p>You&apos;re signed in as {role === "admin" ? "an admin" : "an editor"}.</p>
              <Link className="btn btn-dark" href="/admin">
                Go to the admin area
              </Link>
            </section>
          ) : null}
        </div>
      </main>
    </>
  );
}
