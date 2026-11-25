import Link from "next/link";

// The bar across the top of /account and /admin: the mark, where you are,
// and sign out. Sign out is a POST form, so nothing can trigger it by accident.
export function DeskHeader({ title, email }: { title: string; email: string }) {
  return (
    <header className="desk-head">
      <div className="wrap desk-bar">
        <Link className="desk-mark" href="/" prefetch={false} aria-label="Back to the Flocking Birds site">
          <img src="/favicon.png" alt="" width={36} height={36} />
          <span>{title}</span>
        </Link>
        <div className="desk-who">
          <span className="desk-email">{email}</span>
          <form action="/auth/signout" method="post">
            <button className="btn btn-line" type="submit">
              Sign out
            </button>
          </form>
        </div>
      </div>
    </header>
  );
}
