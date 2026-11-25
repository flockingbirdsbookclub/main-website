import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getSignedInUser, safeNext } from "@/lib/auth";
import { SignInForm } from "./SignInForm";

export const metadata: Metadata = {
  title: "Sign in · Flocking Birds Book Club",
  robots: { index: false },
};

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ next?: string; error?: string }>;
}) {
  const { next: rawNext, error } = await searchParams;
  const next = safeNext(rawNext);

  if (await getSignedInUser()) redirect(next);

  return (
    <main className="gate">
      <div className="gate-box">
        <img src="/favicon.png" alt="" width={64} height={64} />
        <h1>Sign in</h1>
        <p>For members and the team. We email you a link and a code, no password needed.</p>
        <SignInForm next={next} linkFailed={error === "link"} />
      </div>
    </main>
  );
}
