import { NextResponse, type NextRequest } from "next/server";
import { updateSession } from "@/lib/supabase/proxy";

// Runs before the signed-in parts of the site (see `matcher`), never on the
// public pages, so those stay static and fast.
//
// It does two things: keeps the login session fresh, and sends anyone who is
// not signed in from /admin or /account to the sign-in page. That second part
// is only a quick cookie check. Who may see what is decided again in
// lib/auth.ts and by the database's access rules.
export async function proxy(request: NextRequest) {
  const { response, signedIn } = await updateSession(request);
  const { pathname, search } = request.nextUrl;

  const needsSignIn = pathname.startsWith("/admin") || pathname.startsWith("/account");
  if (needsSignIn && !signedIn) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    url.search = `?next=${encodeURIComponent(pathname + search)}`;
    return NextResponse.redirect(url);
  }

  return response;
}

export const config = {
  matcher: ["/admin/:path*", "/account/:path*", "/login", "/auth/:path*"],
};
