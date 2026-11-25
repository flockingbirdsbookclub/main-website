import type { Metadata } from "next";
import { requireStaff } from "@/lib/auth";
import { DeskHeader } from "@/components/layout/DeskHeader";

export const metadata: Metadata = {
  title: "Admin · Flocking Birds Book Club",
  robots: { index: false },
};

// Everything under /admin is for staff. This check runs on the server for
// every admin page; the database's access rules check again on every read
// and write, so a page that forgets can't leak anything.
export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const { user } = await requireStaff("/admin");
  return (
    <>
      <DeskHeader title="Admin" email={user.email} />
      <main className="desk">
        <div className="wrap">{children}</div>
      </main>
    </>
  );
}
