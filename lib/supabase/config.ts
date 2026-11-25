// Where the Supabase project lives. Set in .env.local for local work and in
// Netlify's environment variables for each deploy (staging and production
// point at different projects). See .env.example.
//
// The publishable key is safe in the browser: the database's access rules
// decide what it can do. The secret key is not, and is read only in
// lib/supabase/admin.ts.

export function supabaseUrl(): string {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!url) throw new Error("NEXT_PUBLIC_SUPABASE_URL is not set. See .env.example.");
  return url;
}

export function supabasePublishableKey(): string {
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  if (!key) throw new Error("NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY is not set. See .env.example.");
  return key;
}
