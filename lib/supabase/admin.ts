import "server-only";
import { createClient } from "@supabase/supabase-js";
import { supabaseUrl } from "./config";

// A Supabase client with the secret key. It bypasses every access rule, so:
// - only server code may import it (the "server-only" import enforces that),
// - use it only after checking who is asking,
// - never pass what it returns straight to the browser.
//
// Used for creating login accounts for known members and staff, and later
// for writes the browser must not make directly (RSVPs, orders, game results).
export function createAdminClient() {
  const secret = process.env.SUPABASE_SECRET_KEY;
  if (!secret) throw new Error("SUPABASE_SECRET_KEY is not set. See .env.example.");
  return createClient(supabaseUrl(), secret, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
