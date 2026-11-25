# Data model

The Supabase database design for every feature in
[`PROJECT_SCOPE.md`](PROJECT_SCOPE.md). It covers today's content and all seven new
features, so Phase 5 creates one schema that later phases build on rather than rework.

The SQL is in `supabase/migrations/`, the starting content in `supabase/seed.sql`, and
the access-rule tests in `supabase/tests/access_test.sql`. When a migration changes a
table, change this file in the same commit. See [Building and testing](#building-and-testing).

Last updated: 25 November 2026

---

## Contents

1. [Conventions](#conventions)
2. [How it fits together](#how-it-fits-together)
3. [Identity: members, flocks, staff](#identity-members-flocks-staff)
4. [Media and photos](#media-and-photos)
5. [Socials](#socials)
6. [Books and reading](#books-and-reading)
7. [Partners](#partners)
8. [Leaderboard](#leaderboard)
9. [Blog](#blog)
10. [Merch](#merch)
11. [Games and the bird test](#games-and-the-bird-test)
12. [Testimonials and settings](#testimonials-and-settings)
13. [Audit log](#audit-log)
14. [Access rules](#access-rules)
15. [Storage buckets](#storage-buckets)
16. [Where today's content goes](#where-todays-content-goes)
17. [Building and testing](#building-and-testing)

---

## Conventions

These hold for every table unless a table says otherwise.

- **Keys.** `id uuid primary key default gen_random_uuid()`.
- **Timestamps.** `created_at` and `updated_at` (`timestamptz`), with `updated_at` set by a
  trigger.
- **Public rows** have a `slug` (unique, lowercase, hyphenated), a `status`, and
  `archived_at` for soft delete. Nothing public is hard-deleted, so old links keep working
  or can redirect.
- **Status.** Content that members or staff write moves `draft` → `submitted` →
  `published`, or to `rejected`. Content only staff write uses `draft` and `published`.
  The public can read only `published` rows with no `archived_at`.
- **Order.** Lists that staff arrange have `sort_order int`. "Featured" is a boolean flag,
  not a separate table.
- **Images** are rows in `media` and referenced by `*_media_id`. URLs are never copied
  into other tables, so replacing an image is one change.
- **Money** is whole Kenya shillings, `price_kes int`. No floats.
- **Enums** are Postgres `check` constraints on `text` columns, not Postgres enum types,
  so adding a value is a one-line migration.
- **Flexible bits** (merch options, game settings, answer weights) are `jsonb`. Anything
  we filter or join on gets a real column instead.
- **Indexes** on every foreign key, on `slug`, and on `(status, sort_order)` for public
  lists.

---

## How it fits together

```
                      staff_roles ── auth.users ── profiles ── profile_links
                                                     │   │
                               flock_memberships ────┘   ├── photo_tags ── media
                                     │                   ├── articles ── article_tags ── tags
                                  flocks                 ├── score_entries ── score_categories
                                     │                   └── game_attempts ── games
                                     │                                          ├── game_questions ── game_options
   events ── event_speakers          │                                          └── personality_types
     │  ├── event_rsvps              │
     │  └── albums ── album_photos ── media
     │
     ├── books ── reading_cycles ── seasons ── score_entries, awards
     │
   merch_drops ── merch_products ── merch_variants
                       │      └── merch_product_media ── media
                       └── merch_order_items ── merch_orders

   partners (books, merch, gifting, venues)      settings      testimonials      audit_log
```

---

## Identity: members, flocks, staff

### `profiles`

One row per member. A profile can exist before its owner signs in for the first time.
An admin creates it with the member's email, and it is linked to their login when they
first use an email link.

| Column | Type | Notes |
|---|---|---|
| `user_id` | uuid, unique, null | `auth.users.id` once claimed |
| `email` | text, unique | For claiming and login. Never shown publicly |
| `slug` | text, unique | `/members/[slug]` |
| `full_name` | text | |
| `photo_media_id` | uuid → `media` | |
| `profession` | text | |
| `fun_fact` | text | "Something fun about me" |
| `bio` | text, null | Short, optional |
| `personality_key` | text → `personality_types.key`, null | |
| `show_personality` | bool | Their bird shows on the mural only when true |
| `joined_on` | date | |
| `status` | `draft`, `submitted`, `published`, `rejected` | A member can only move it between `draft` and `submitted` |
| `pending_changes` | jsonb, null | A member's edits to a published profile wait here until staff approve them with `approve_profile_changes()`. The published version stays up meanwhile |
| `review_note` | text, null | Shown to the member if their profile is returned |
| `is_featured` | bool | |
| `sort_order` | int | |
| `consent_at` | timestamptz | When they agreed to be shown on the mural |

### `profile_links`

How fellow members can connect with this person.

| Column | Type | Notes |
|---|---|---|
| `profile_id` | uuid → `profiles` | |
| `kind` | `linkedin`, `instagram`, `x`, `website`, `email`, `phone`, `whatsapp` | |
| `value` | text | URL, address or number |
| `visibility` | `public`, `members` | Defaults to `members` for `email`, `phone`, `whatsapp`; `public` for the rest |
| `sort_order` | int | |

### `flocks`

| Column | Type | Notes |
|---|---|---|
| `slug`, `name` | text | "Kiambu Road", "Thika Road Bears", "Online flock" |
| `area` | text, null | |
| `meeting_rhythm` | text, null | "Every other Thursday" |
| `photo_media_id` | uuid → `media`, null | |
| `is_active` | bool | |
| `sort_order` | int | |

### `flock_memberships`

History, not a single column on the profile, so a member can change flocks and leaders
can change, without losing who led what and when.

| Column | Type | Notes |
|---|---|---|
| `profile_id` | uuid → `profiles` | |
| `flock_id` | uuid → `flocks` | |
| `role` | `leader`, `co_leader`, `member` | |
| `started_on` | date | |
| `ended_on` | date, null | Null means current |

A member has at most one current membership (unique partial index on `profile_id` where
`ended_on is null`).

**The mural order** (leaders first, then everyone else) is a query, not stored:
current `leader`, then `co_leader`, then featured members, then the rest by `sort_order`
and name. A view, `mural_entries`, gives the page one row per published profile with its
current flock and role.

### `staff_roles`

Who can use `/admin`. Kept apart from `profiles`, so a maintainer does not need a member
profile and nothing a member edits can make them staff.

| Column | Type | Notes |
|---|---|---|
| `user_id` | uuid → `auth.users`, primary key | |
| `role` | `admin`, `editor` | Editors manage content. Admins also manage staff, settings and points |

The database functions `is_staff()` and `is_admin()` read this table and are used in the
access rules.

### `staff_invites`

`email`, `role`. Someone whose email is here becomes staff the first time they sign in.
Nobody can read it through the API. **Staff emails are added in the Supabase dashboard,
never in this repository**, because the repository is public.

---

## Media and photos

### `media`

Every uploaded image, once.

| Column | Type | Notes |
|---|---|---|
| `bucket` | text | See [Storage buckets](#storage-buckets). `site` means a file already in the website's `public/` folder, with a path like `/images/books/x.jpg`, so today's images work before anything is uploaded |
| `path` | text | Unique with `bucket` |
| `alt` | text | Required. The upload form does not save without it |
| `width`, `height` | int | Saved on upload, so pages can reserve space and avoid layout jumps |
| `uploaded_by` | uuid → `auth.users` | |

### `albums` and `album_photos`

Group photos and fun times, whether from a Social or a flock meet-up.

| `albums` column | Type | Notes |
|---|---|---|
| `slug`, `title` | text | |
| `taken_on` | date | |
| `event_id` | uuid → `events`, null | A Social's album shows on its page |
| `flock_id` | uuid → `flocks`, null | A flock's album shows on its members' profiles |
| `cover_media_id` | uuid → `media`, null | |
| `status` | `draft`, `published` | |

| `album_photos` column | Type | Notes |
|---|---|---|
| `album_id` | uuid → `albums` | |
| `media_id` | uuid → `media` | |
| `caption` | text, null | |
| `sort_order` | int | |

### `photo_tags`

Puts a group photo on a member's profile. A photo appears on a profile only once the
member approves the tag.

| Column | Type | Notes |
|---|---|---|
| `media_id` | uuid → `media` | |
| `profile_id` | uuid → `profiles` | |
| `tagged_by` | uuid → `auth.users` | |
| `status` | `pending`, `approved`, `declined` | |

---

## Socials

### `events`

Every Social, past and future. Replaces the `event` object in `app/page.tsx`.

| Column | Type | Notes |
|---|---|---|
| `slug` | text | `social-4`, used for `/socials/[slug]` |
| `number` | text | "4.0" |
| `heading` | text | "BookClub Social 4.0" |
| `edition` | text, null | "Surrounded by Idiots edition" |
| `tagline` | text, null | |
| `starts_at`, `ends_at` | timestamptz | Nairobi time. The page formats "Saturday 5 December" and "12:00–6:00 PM" from these |
| `venue_name`, `venue_address` | text | |
| `price_kes` | int, null | |
| `price_note` | text, null | "Covers a buffet lunch" |
| `who`, `bring` | text | |
| `poster_media_id` | uuid → `media`, null | |
| `book_id` | uuid → `books`, null | The book the Social reviews |
| `recap_title`, `recap_body` | text, null | Written after the Social, for its page |
| `status` | `draft`, `published` | |

- **Next Social:** the earliest `published` event with `ends_at` in the future.
- **Past Socials:** `published` events with `ends_at` in the past, newest first.
- The short label ("5 Dec") and pill text are worked out from `starts_at`, so they can't
  disagree with the date.

### `event_speakers`

| Column | Type | Notes |
|---|---|---|
| `event_id` | uuid → `events` | |
| `name`, `title`, `organisation` | text | "Kalekye Mumo", "Communications coach", "Own Your Mic Programs, KM Network" |
| `talk_title` | text, null | "The art of communication" |
| `photo_media_id` | uuid → `media`, null | |
| `profile_id` | uuid → `profiles`, null | If the speaker is a member |
| `sort_order` | int | |

### `event_rsvps`

A copy of each RSVP. The Netlify Forms record and the WhatsApp message carry on as well.

| Column | Type | Notes |
|---|---|---|
| `event_id` | uuid → `events` | |
| `profile_id` | uuid → `profiles`, null | Filled in when a signed-in member RSVPs |
| `name`, `phone` | text | |
| `email` | text, null | |
| `party_size` | text | "Just me", "Me + 1" … |
| `member_status` | text | "Yes, I am in a flock" … |
| `attended` | bool, null | Ticked by staff on the day. Feeds automatic points |

---

## Books and reading

### `books`

| Column | Type | Notes |
|---|---|---|
| `slug`, `title`, `author` | text | |
| `cover_media_id` | uuid → `media`, null | Missing cover shows the typographic fallback |
| `purchase_url` | text, null | No buy link without it |
| `store_partner_id` | uuid → `partners`, null | "Buy from Kibanga Books" reads the partner's name |
| `blurb` | text, null | |

### `reading_cycles`

When a book was or is being read. Replaces the planned `kind: current | shelf` column.

| Column | Type | Notes |
|---|---|---|
| `book_id` | uuid → `books` | |
| `flock_id` | uuid → `flocks`, null | Null means the whole club |
| `starts_on`, `ends_on` | date, null | Null for older books whose dates were never recorded |
| `note` | text, null | |
| `sort_order` | int | Keeps undated shelf books in order |

- **Current read:** the club-wide cycle that covers today.
- **Shelf:** books from past cycles, most recent first.
- A flock reading something different gets its own row, so this scales past one book
  for everyone.

---

## Partners

### `partners`

| Column | Type | Notes |
|---|---|---|
| `slug`, `name` | text | |
| `kind` | `bookshop`, `merch`, `gifting`, `venue`, `other` | |
| `role` | text | The line under the name, "Bookshop · 10% off for members" |
| `member_offer` | text, null | "10% off for members" |
| `image_media_id` | uuid → `media` | |
| `url` | text | |
| `is_active` | bool | |
| `sort_order` | int | |

---

## Leaderboard

Flocks and members both score. Points are a ledger of entries, and the leaderboard is a
sum over that ledger, so a total can always be explained line by line.

### `seasons`

| Column | Type | Notes |
|---|---|---|
| `name` | text | "Surrounded by Idiots, Oct to Dec 2026" |
| `starts_on`, `ends_on` | date | |
| `reading_cycle_id` | uuid → `reading_cycles`, null | Usually one season per book |

### `score_categories`

| Column | Type | Notes |
|---|---|---|
| `slug`, `name` | text | |
| `description` | text | What earns it, shown on the leaderboard page |
| `applies_to` | `flock`, `member`, `both` | |
| `default_points` | int | |
| `is_automatic` | bool | True when the system awards it |
| `is_active` | bool | |

Starting categories, to confirm with the club: session attendance, challenge done,
hosted a session, brought someone new, attended a Social (automatic, from
`event_rsvps.attended`), article published (automatic, from `articles`).

### `score_entries`

| Column | Type | Notes |
|---|---|---|
| `season_id` | uuid → `seasons` | |
| `category_id` | uuid → `score_categories` | |
| `flock_id` | uuid → `flocks`, null | Exactly one of `flock_id` or `profile_id` is set (check constraint) |
| `profile_id` | uuid → `profiles`, null | |
| `points` | int | Can be negative, to correct a mistake |
| `note` | text, null | |
| `source` | `manual`, `automatic` | |
| `source_ref` | text, null | For automatic entries, for example `article:<id>`. Unique with `category_id`, so nothing is awarded twice |
| `awarded_by` | uuid → `auth.users`, null | |

Entries are never edited or deleted. A wrong entry is cancelled by a negative one.

### Views

- `flock_standings`: season, flock, total points, rank.
- `member_standings`: season, profile, current flock, total points, rank.

Both are views, so they never drift from the entries.

### `awards`

| Column | Type | Notes |
|---|---|---|
| `season_id` | uuid → `seasons` | |
| `title` | text | "Community champions" |
| `flock_id` / `profile_id` | uuid, one of them | |
| `awarded_on` | date | |
| `media_id` | uuid → `media`, null | Trophy photo |

Replaces the hardcoded "Previous champions: Thika Road Bears".

---

## Blog

### `articles`

Written by members, attributed to their profile, shareable in the spirit of showing your
work. It also takes over the planned `posts` table ("From the flock" links to pieces
published elsewhere).

| Column | Type | Notes |
|---|---|---|
| `slug` | text | `/blog/[slug]` |
| `author_profile_id` | uuid → `profiles` | |
| `title` | text | |
| `excerpt` | text | Used on cards and in share previews |
| `body` | text, null | Markdown. Null when `external_url` is set |
| `external_url` | text, null | A piece on LinkedIn or Medium, linked rather than copied |
| `cover_media_id` | uuid → `media`, null | Also the share image |
| `book_id` | uuid → `books`, null | When the article is about a book |
| `status` | `draft`, `submitted`, `published`, `rejected` | |
| `review_note` | text, null | Shown to the author if rejected |
| `submitted_at`, `published_at` | timestamptz | |
| `reviewed_by` | uuid → `auth.users`, null | |

When an article is published for the first time, a trigger adds an automatic
`score_entries` row for its author.

### `tags` and `article_tags`

`tags`: `slug`, `name`. `article_tags`: `article_id`, `tag_id`, primary key on both.

---

## Merch

Catalogue first, in the Cotton Bureau style: each drop is a campaign with a deadline and
a minimum run. A product either links to the partner store that prints and ships it, or
takes a preorder on our site, chosen per product.

### `merch_drops`

| Column | Type | Notes |
|---|---|---|
| `slug`, `name` | text | "The first drop" |
| `description` | text | |
| `opens_at`, `closes_at` | timestamptz | |
| `collect_event_id` | uuid → `events`, null | For preorders collected at a Social |
| `status` | `draft`, `published` | |

### `merch_products`

| Column | Type | Notes |
|---|---|---|
| `slug` | text | |
| `drop_id` | uuid → `merch_drops`, null | Null means always available |
| `partner_id` | uuid → `partners`, null | The merch partner |
| `kind` | text | "Tee", "Tote", "Mug" |
| `name`, `description` | text | |
| `price_kes` | int | |
| `fulfilment` | `partner_store`, `preorder` | |
| `external_url` | text, null | Required when `fulfilment = partner_store` |
| `min_run` | int, null | Below this, the item is not printed and deposits are refunded |
| `options` | jsonb | `[{"label":"Colour","swatch":true,"values":["forest","cream"]}, …]`, the same shape as `MerchOption` today |
| `status` | `draft`, `published` | |
| `sort_order` | int | |

### `merch_variants`

Only needed when a size or colour has its own price or its own partner-store link.

| Column | Type | Notes |
|---|---|---|
| `product_id` | uuid → `merch_products` | |
| `options` | jsonb | `{"Colour":"forest","Size":"M"}` |
| `price_override_kes` | int, null | |
| `external_url` | text, null | |

### `merch_product_media`

`product_id`, `media_id`, `sort_order`.

### `merch_orders` and `merch_order_items`

Only used for `preorder` products. Replaces the Netlify Forms copy as the record of
orders (the form stays as a backup).

| `merch_orders` column | Type | Notes |
|---|---|---|
| `drop_id` | uuid → `merch_drops` | |
| `profile_id` | uuid → `profiles`, null | |
| `name`, `phone` | text | |
| `flock_id` | uuid → `flocks`, null | |
| `total_kes`, `deposit_kes` | int | Worked out on the server, never trusted from the browser |
| `mpesa_code` | text, null | |
| `status` | `pending_deposit`, `deposit_paid`, `paid`, `collected`, `refunded`, `cancelled` | |

| `merch_order_items` column | Type | Notes |
|---|---|---|
| `order_id` | uuid → `merch_orders` | |
| `product_id` | uuid → `merch_products` | |
| `variant` | jsonb | The options chosen |
| `qty` | int | |
| `unit_price_kes` | int | Price at the time of ordering |

A view, `merch_run_counts`, totals the quantity per product and variant, so the club can
see whether each item has hit its minimum run, and the printer's size list is one query.

---

## Games and the bird test

### `games`

| Column | Type | Notes |
|---|---|---|
| `slug`, `title` | text | `/games/[slug]` |
| `kind` | `personality`, `quiz`, `trivia` | |
| `description` | text | |
| `book_id` | uuid → `books`, null | A quiz about a book |
| `config` | jsonb | For example time limits, or whether results are emailed |
| `status` | `draft`, `published` | |

### `game_questions` and `game_options`

| `game_questions` column | Type | Notes |
|---|---|---|
| `game_id` | uuid → `games` | |
| `prompt` | text | |
| `sort_order` | int | |

| `game_options` column | Type | Notes |
|---|---|---|
| `question_id` | uuid → `game_questions` | |
| `label` | text | |
| `weights` | jsonb | For the bird test, `{"red":2,"yellow":0,"green":1,"blue":0}`. For a quiz, `{"correct":true}` |
| `sort_order` | int | |

Weights are never sent to the browser. The `weights` column isn't granted to anyone
through the API; staff read it with `staff_game_options()`. The page sends back the chosen
option ids and the server works out the result.

### `personality_types`

The four results of the bird test, editable by staff.

| Column | Type | Notes |
|---|---|---|
| `key` | `red`, `yellow`, `green`, `blue`, primary key | |
| `bird_name` | text | To be chosen by the club |
| `colour` | text | A brand token, for example `--terracotta` |
| `summary`, `strengths`, `blind_spots`, `how_to_work_with` | text | |
| `image_media_id` | uuid → `media`, null | |

### `game_attempts`

| Column | Type | Notes |
|---|---|---|
| `game_id` | uuid → `games` | |
| `profile_id` | uuid → `profiles`, null | When a signed-in member takes it |
| `name` | text, null | |
| `email` | text | Where the result is sent |
| `answers` | jsonb | Option ids chosen |
| `result_key` | text, null | For the bird test |
| `scores` | jsonb | `{"red":9,"yellow":4,…}` or `{"correct":7,"total":10}` |
| `marketing_consent` | bool | Separate tick box. False unless ticked |
| `emailed_at` | timestamptz, null | Set when the email provider accepts the message |

Written only by a server action, which also sends the email. The public can't read this
table. A member can read their own attempts.

---

## Testimonials and settings

### `testimonials`

Real quotes only, collected with permission.

| Column | Type | Notes |
|---|---|---|
| `profile_id` | uuid → `profiles`, null | |
| `quote` | text | |
| `name` | text | |
| `flock_id` | uuid → `flocks`, null | |
| `consent_at` | timestamptz | Required before it can be published |
| `status` | `draft`, `published` | |
| `sort_order` | int | |

### `settings`

Values used in many places that staff may need to change.

| Column | Type | Notes |
|---|---|---|
| `key` | text, primary key | |
| `value` | jsonb | |
| `is_public` | bool | Readable by the public only when true |

Starting keys:
- `join_url`, today in `lib/join.ts`
- `whatsapp_rsvp`, today in `lib/whatsapp.ts`
- `whatsapp_merch`, today `config.whatsapp`
- `merch_deposit_pct`
- `currency`
- `mpesa_till`

---

## Audit log

### `audit_log`

Content moves out of git once it is in Supabase, so this is how the club sees who changed
what.

| Column | Type | Notes |
|---|---|---|
| `actor_id` | uuid → `auth.users`, null | |
| `table_name` | text | |
| `row_id` | uuid | |
| `action` | `insert`, `update`, `delete` | |
| `diff` | jsonb | Old and new values of the changed columns |
| `at` | timestamptz | |

Filled by a trigger on every content table. Readable by admins only. Never edited.

---

## Access rules

Row-level security is on for every table. Phase 5 writes the rules and tests each one
against three clients (signed out, a member, a staff user) before any screen uses them.

| Who | Can read | Can write |
|---|---|---|
| **Public** | `published`, unarchived rows of public content. `profile_links` with `visibility = public`. `settings` with `is_public`. Leaderboard views | Nothing directly. RSVPs, merch orders and game attempts go through server actions that check and save the input |
| **Member** (signed in, with a `published` or `submitted` profile) | Everything the public can, plus `profile_links` with `visibility = members`, their own drafts, their own game attempts and score entries | Their own `profiles` row and `profile_links`. Their own `articles` while `draft` or `submitted`. The `status` of `photo_tags` for themselves. They can't publish, change their own `status`, or touch `staff_roles` |
| **Editor** | Everything | All content tables. Approve and reject submissions |
| **Admin** | Everything, including `audit_log` | Everything editors can, plus `staff_roles`, `settings`, `score_entries` and `awards` |

Rules that need care:
- **Member edits re-enter review.** A trigger sets a member's profile back to `submitted`
  when they change a public field. The current published version stays up until staff
  approve the new one.
- **Contact details.** Contact links are never in the public mural view. The members-only
  view joins them only for signed-in members.
- **Service role key.** Bypasses all of this. It lives only in Netlify environment
  variables, is used only in server code, and is never sent to the browser.

---

## Storage buckets

| Bucket | Holds | Read | Write |
|---|---|---|---|
| `avatars` | Member photos | Public | The member (their own folder), staff |
| `covers` | Book covers | Public | Staff |
| `partners` | Partner cards | Public | Staff |
| `events` | Posters, speaker photos | Public | Staff |
| `albums` | Group photos | Public | Staff |
| `articles` | Article covers and images | Public | The author (their own folder), staff |
| `merch` | Product photos | Public | Staff |

Uploads are checked on the server: JPEG, PNG or WebP only, 5 MB at most, and resized to
a web copy, the same idea as today's `-web` files.

---

## Where today's content goes

Phase 5 seeds the database from what is in the code today, so the site looks the same
the day it switches over.

| Today | Becomes |
|---|---|
| `event` in `app/page.tsx` | `events` row "social-4", plus a past `events` row "social-3" with Kalekye Mumo in `event_speakers` |
| `currentBook`, `shelfBooks` | `books`, plus `reading_cycles` |
| `partners` | `partners` |
| `posts` (empty) | `articles` with `external_url` |
| `testimonials` (empty) | `testimonials` |
| Champions block | `flocks` (Kiambu Road, Thika Road Bears), plus `awards` |
| `products`, `config` in `app/merch/page.tsx` | `merch_drops`, `merch_products`, `settings` |
| `lib/join.ts`, `lib/whatsapp.ts` | `settings` |
| Images in `public/images/books`, `partners`, `social` | Storage buckets, plus `media` |

The texture, nav mark, favicons, hero collage and other fixed photos stay in `public/`.

---

## Building and testing

### Run the tests locally

```bash
scripts/test-db.sh
```

This builds the whole database from empty on a local Postgres (Postgres.app is enough,
on port 54329, and no Docker is needed). It then runs the seed twice, to prove it is safe
to re-run, and runs `supabase/tests/access_test.sql`. That file signs in as a visitor, a
signed-in stranger, two members, an editor and an admin, and checks over 60 things,
including:

- visitors can't write anything, or read emails, phone numbers, drafts, RSVPs, orders,
  quiz answers or the audit log
- members can't publish, feature themselves, edit someone else, or award points
- edits to a published profile wait for review
- automatic points arrive exactly once
- points can't be edited or deleted, even by the database owner

`supabase/tests/local_stub.sql` stands in for Supabase's `auth` and `storage` schemas.
Never run it against a real project.

### Rules for the app code

- **Name your columns when reading `profiles`.** `select *` is refused, because the
  table holds members' emails and the public grant leaves those out. Use
  `profile_private()` for the email and any parked edits.
- **RSVPs, merch orders and game attempts are written by server code** using the
  service role, after checking the input and working out totals. The browser can't
  insert into those tables.
- **Staff-only fields are guarded by triggers**, not only by the API. Even if a member
  sends `is_featured = true`, it is reset.

### Views the pages read

`next_event`, `past_events`, `current_reads`, `shelf`, `mural_entries`, `flock_standings`,
`member_standings`. All use `security_invoker`, so the access rules still apply.
