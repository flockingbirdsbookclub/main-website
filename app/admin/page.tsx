import Link from "next/link";
import { requireStaff } from "@/lib/auth";

export default async function AdminHome() {
  const { role } = await requireStaff("/admin");

  return (
    <>
      <h1>Admin</h1>
      <p className="desk-lede">
        You&apos;re signed in as {role === "admin" ? "an admin" : "an editor"}.
      </p>
      <section className="desk-card">
        <h2>Coming next</h2>
        <p>
          The screens for the next Social, books, partners, settings and photos arrive in the next
          phase. Until then, content is still edited in the code.
        </p>
        <Link className="btn btn-line" href="/account">
          Your account
        </Link>
      </section>
    </>
  );
}
