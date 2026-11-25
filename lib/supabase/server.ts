import "server-only";
import { cookies } from "next/headers";
import { createServerClient } from "@supabase/ssr";
import { supabasePublishableKey, supabaseUrl } from "./config";

// A Supabase client for Server Components, Server Actions and Route Handlers,
// acting as whoever is signed in (or as a visitor). Make a new one for each
// request; never share one between requests.
export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(supabaseUrl(), supabasePublishableKey(), {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet) {
        try {
          cookiesToSet.forEach(({ name, value, options }) => cookieStore.set(name, value, options));
        } catch {
          // Server Components can't set cookies. proxy.ts refreshes the
          // session on every signed-in route, so this is safe to ignore.
        }
      },
    },
  });
}
