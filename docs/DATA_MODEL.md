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

- **Keys.** `id uuid primary key default gen_random_uuid()`. Join tables use the pair of ids as their key.
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
- **Fixed states** such as `status` are `check` constraints on `text` columns. Lists
  that grow are lookup tables (see below).
- **No JSON for data.** Anything with structure is columns and rows. See
  [Normalisation](#normalisation).
- **Indexes** on every foreign key, on `slug`, and on `(status, sort_order)` for public
  lists.

### Normalisation

The schema is in third normal form: every fact is stored once, in the table it belongs
to.

- **Shared things are their own table.** A venue, a speaker, an author or a swatch
  colour used by many rows is one row that the others point at. Renaming Golden Tulip
  is one change, not one per Social.
- **Lists are rows, not JSON.** Merch options and their values, answer scores, and the
  answers someone gave are tables. Apart from the `data` field below, only two JSON
  columns exist: `audit_log.diff` (a record of changes to any table) and
  `profiles.pending_changes` (a parked copy of a member's edits, waiting for review).
- **Totals are worked out, not stored.** Order totals, deposits, standings, bird test
  scores and the shelf are views over the rows they come from, so they can't disagree.
- **Kept on purpose: snapshots of the moment.** An order line keeps the price paid. An
  order keeps the deposit percentage that applied. An RSVP keeps the name and phone it
  was sent with. These record what happened, which later edits must not rewrite.
- **Vocabularies that grow are lookup tables:** `link_kinds`, `partner_kinds`,
  `event_kinds`, `merch_categories`, `merch_colours`. Adding one is a new row, made in
  the admin area, with no migration. Fixed workflow states (`status`) stay as checks.
- **Optional relationships use their own tables**, such as `book_authors` and
  `book_purchase_links`, so "one" can become "many" without a migration.

### The `data` field

The main tables have a `data` column: a JSON object for extra details that don't deserve
a column yet. Examples are a Social's dress code, a partner's discount code, or a
product's care instructions. Adding a key needs no migration.

| Rule | Why |
|---|---|
| Always a JSON object, `{}` by default, at most 32 KB | Enforced by a check on every table |
| As public as its row | Anyone who can read the row can read its `data`. Nothing private goes in it |
| Promote a key to a column once a page filters, sorts or joins on it, or it must always be there | Columns get a type, a check, an index and a place in the tests. JSON gets none of those |
| Bookkeeping stays in columns: `id`, `created_at`, `updated_at`, `status`, `archived_at` | These are sorted, filtered and kept correct by triggers on every query |
| Members can't change `profiles.data`; staff can | It's for things like a "founding member" badge |
| Changes to `data` are in the audit log | Like any other column |

Tables with `data`: `media`, `profiles`, `flocks`, `personality_types`, `partners`,
`authors`, `books`, `reading_cycles`, `venues`, `events`, `speakers`, `event_rsvps`,
`albums`, `testimonials`, `articles`, `seasons`, `awards`, `merch_drops`,
`merch_products`, `merch_variants`, `merch_orders`, `games`, `game_attempts`.
The page views (`event_cards`, `next_event`, `past_events`, `book_cards`, `current_reads`,
`shelf`, `mural_entries`, `merch_variant_cards`) include it.

Join tables, lookup tables, the points ledger, `site_settings` and the staff tables have
no `data`. They stay strict on purpose.

To read a key in the app: `next_event?select=heading,data->>dress_code`.

### Adding a field

1. Write a new migration, `supabase/migrations/<timestamp>_<what>.sql`, with
   `alter table ... add column ...`. Never edit a migration that has reached
   production.
2. Give the column a type and a `check` if it has rules. Give it a `default`, or make it
   nullable, so existing rows stay valid.
3. If a page reads it through a view, add it to that view in the same migration
   (`create or replace view`, with the new column added at the end).
4. If it is visible to the public, check the column grant. `profiles` and
   `game_options` use column-level grants, so a new column there is hidden until it is
   added to the grant.
5. Add it to this file and, if it has access rules, a check to
   `supabase/tests/access_test.sql`. Run `npm run test:db`.

---

## How it fits together

```
 auth.users ── staff_roles            link_kinds
     │                                    │
  profiles ──┬── profile_links ───────────┘
     │       ├── flock_memberships ── flocks
     │       ├── photo_tags ── media ── (every image, once)
     │       ├── articles ── article_tags ── tags
     │       ├── score_entries ── score_categories, seasons ── reading_cycles
     │       └── game_attempts ── game_attempt_answers ── game_options ── game_option_scores
     │                                                        │
     │                                   games ── game_questions          personality_types
     │
  events ── venues            books ── book_authors ── authors
   │  ├── event_speakers ── speakers     ├── book_purchase_links ── partners ── partner_kinds
   │  ├── event_rsvps                    └── reading_cycles
   │  └── albums ── album_photos
   └── event_kinds

  merch_drops ── merch_products ── merch_options ── merch_option_values ── merch_colours
                      │  └── merch_variants ── merch_variant_values
                      └── merch_categories
  merch_orders ── merch_order_items ── merch_variants

  site_settings (one row)     testimonials     audit_log
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
| `kind` | text → `link_kinds.key` | |
| `value` | text | URL, address or number |
| `visibility` | `public`, `members` | Starts as the kind's `default_visibility` |
| `sort_order` | int | |

### `link_kinds`

`key` (`linkedin`, `instagram`, `x`, `website`, `email`, `phone`, `whatsapp`), `label`,
`default_visibility` (members-only for email, phone and WhatsApp), `sort_order`. Adding
TikTok is one row.

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

The database functions `private.is_staff()` and `private.is_admin()` read this table and
are used in the access rules. Helpers live in the `private` schema, which the API doesn't
expose, so they can't be called over HTTP.

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

### `venues`

| Column | Type | Notes |
|---|---|---|
| `slug`, `name` | text | "Golden Tulip Westlands" |
| `address` | text, null | |
| `map_url` | text, null | |
| `partner_id` | uuid → `partners`, null | When the venue is also a partner |

### `event_kinds`

`key`, `label`. Starts with `social`. A flock meet-up or a workshop is a new row.

### `events`

Every Social, past and future. Replaces the `event` object in `app/page.tsx`.

| Column | Type | Notes |
|---|---|---|
| `slug` | text | `social-4`, used for `/socials/[slug]` |
| `kind` | text → `event_kinds.key` | Defaults to `social` |
| `number` | text | "4.0" |
| `heading` | text | "BookClub Social 4.0" |
| `edition` | text, null | "Surrounded by Idiots edition" |
| `tagline`, `description` | text, null | |
| `starts_at`, `ends_at` | timestamptz | Nairobi time. The page formats "Saturday 5 December" and "12:00–6:00 PM" from these |
| `venue_id` | uuid → `venues`, null | |
| `price_kes` | int, null | |
| `price_note` | text, null | "covers a buffet lunch" |
| `who`, `bring` | text | |
| `poster_media_id` | uuid → `media`, null | |
| `book_id` | uuid → `books`, null | The book the Social reviews |
| `recap_title`, `recap_body` | text, null | Written after the Social, for its page |
| `status` | `draft`, `published` | |

- **Next Social:** the earliest published Social that hasn't ended (`next_event`).
- **Past Socials:** published Socials that have ended, newest first (`past_events`).
- The short label ("5 Dec") and pill text are worked out from `starts_at`, so they can't
  disagree with the date.

### `speakers` and `event_speakers`

A speaker is a person who may speak at several Socials.

| `speakers` column | Type | Notes |
|---|---|---|
| `slug`, `name` | text | "Kalekye Mumo" |
| `title`, `organisation`, `bio` | text, null | "Communications coach", "Own Your Mic Programs, KM Network" |
| `photo_media_id` | uuid → `media`, null | |
| `profile_id` | uuid → `profiles`, unique, null | If the speaker is a member |

`event_speakers`: `event_id`, `speaker_id` (primary key on both), `talk_title`,
`sort_order`.

### `event_rsvps`

A copy of each RSVP. The Netlify Forms record and the WhatsApp message carry on as well.

| Column | Type | Notes |
|---|---|---|
| `event_id` | uuid → `events` | |
| `profile_id` | uuid → `profiles`, null | Filled in when a signed-in member RSVPs |
| `name`, `phone`, `email` | text | As sent. Most people who RSVP have no profile |
| `guests` | int, 0 to 20 | "Just me" is 0, "Me + 1" is 1 |
| `member_status` | `member`, `first_time`, `returning`, null | |
| `attended` | bool, null | Ticked by staff on the day. Feeds automatic points |

---

## Books and reading

### `authors` and `book_authors`

`authors`: `slug`, `name`. `book_authors`: `book_id`, `author_id`, `position`, so Blue
Ocean Strategy shows "W. Chan Kim & Renée Mauborgne" in the right order.

### `books`

| Column | Type | Notes |
|---|---|---|
| `slug`, `title` | text | |
| `reading_weight` | `heavy`, `lighter`, null | The tag on the shelf |
| `blurb` | text, null | |
| `cover_media_id` | uuid → `media`, null | Missing cover shows the typographic fallback |

### `book_purchase_links`

Where to buy a book. Several shops per book.

| Column | Type | Notes |
|---|---|---|
| `book_id` | uuid → `books` | |
| `partner_id` | uuid → `partners`, null | "Buy from Kibanga Books" reads the partner's name |
| `url` | text | |
| `sort_order` | int | The first one is the main button |

### `reading_cycles`

When a book was or is being read.

| Column | Type | Notes |
|---|---|---|
| `book_id` | uuid → `books` | |
| `flock_id` | uuid → `flocks`, null | Null means the whole club |
| `starts_on`, `ends_on` | date, null | Null for older books whose dates were never recorded |
| `note` | text, null | |
| `sort_order` | int | Keeps undated shelf books in order |

- **Current read** (`current_reads`): the club-wide cycle that covers today.
- **Shelf** (`shelf`): books from past cycles, newest first.
- A flock reading something different gets its own row.

---

## Partners

### `partner_kinds`

`key`, `label`: bookshop, merch, gifting, venue, other.

### `partners`

| Column | Type | Notes |
|---|---|---|
| `slug`, `name` | text | |
| `kind` | text → `partner_kinds.key` | |
| `description` | text, null | "Embossed “From the library of” stamps" |
| `member_offer` | text, null | "10% off for members" |
| `image_media_id` | uuid → `media` | |
| `url` | text | |
| `is_active` | bool | |
| `sort_order` | int | |

The line under a partner's name is built from these: "Bookshop · 10% off for members".

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

Structured the way most shops are. A product has **options** (Colour, Size). Each option
has **values** (forest, M). Every combination someone can buy is a **variant**, and
orders point at variants. `merch_generate_variants(product_id)` creates the
combinations.

### Lookups

- `merch_categories`: `key`, `label`, such as T-shirt, Cap, Tote or Bookmarks.
- `merch_colours`: `key`, `label`, `hex`. The swatch colours, stored once for every
  product.

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
| `category` | text → `merch_categories.key` | |
| `name`, `description` | text | |
| `price_kes` | int | |
| `fulfilment` | `partner_store`, `preorder` | |
| `external_url` | text, null | Required when `fulfilment = partner_store` |
| `min_run` | int, null | Below this, the item is not printed and deposits are refunded |
| `status` | `draft`, `published` | |
| `sort_order` | int | |

### `merch_options` and `merch_option_values`

| `merch_options` column | Type | Notes |
|---|---|---|
| `product_id` | uuid → `merch_products` | |
| `label` | text | "Colour", unique per product |
| `is_swatch` | bool | Shown as colour dots |
| `sort_order` | int | |

| `merch_option_values` column | Type | Notes |
|---|---|---|
| `option_id` | uuid → `merch_options` | |
| `value` | text | "forest", "M", "Owl", unique per option |
| `colour_key` | text → `merch_colours.key`, null | For swatch values |
| `sort_order` | int | |

### `merch_variants` and `merch_variant_values`

| `merch_variants` column | Type | Notes |
|---|---|---|
| `product_id` | uuid → `merch_products` | |
| `sku` | text, unique, null | For the printer |
| `price_override_kes` | int, null | When 2XL costs more |
| `external_url` | text, null | A partner store link for this variant |
| `is_available` | bool | |

`merch_variant_values`: `variant_id`, `product_id`, `option_id`, `option_value_id`. Its
keys make sure the value belongs to the option, the option belongs to the variant's
product, and each variant has exactly one value per option.

### `merch_product_media`

`product_id`, `media_id`, `sort_order`.

### `merch_orders` and `merch_order_items`

Only used for `preorder` products.

| `merch_orders` column | Type | Notes |
|---|---|---|
| `drop_id` | uuid → `merch_drops` | |
| `profile_id` | uuid → `profiles`, null | |
| `name`, `phone` | text | As given. Most buyers have no profile |
| `flock_id` | uuid → `flocks`, null | Null for "not in a flock yet" |
| `deposit_pct` | int | The percentage that applied when ordering |
| `mpesa_code` | text, null | |
| `status` | `pending_deposit`, `deposit_paid`, `paid`, `collected`, `refunded`, `cancelled` | |

| `merch_order_items` column | Type | Notes |
|---|---|---|
| `order_id` | uuid → `merch_orders` | |
| `variant_id` | uuid → `merch_variants` | |
| `qty` | int | |
| `unit_price_kes` | int | The price when ordered, kept on purpose |

### Views

- `merch_variant_cards`: each variant with its price and a label, "forest / M".
- `merch_order_totals`: items, total and deposit per order, worked out from the lines.
- `merch_run_counts`: how many of each variant are reserved. This is the printer's list.
- `merch_product_progress(drop_id)`: public progress towards each minimum run, without
  showing any order.

---

## Games and the bird test

### `games`

| Column | Type | Notes |
|---|---|---|
| `slug`, `title` | text | `/games/[slug]` |
| `kind` | `personality`, `quiz`, `trivia` | |
| `description` | text | |
| `book_id` | uuid → `books`, null | A quiz about a book |
| `emails_result` | bool | |
| `time_limit_seconds` | int, null | |
| `status` | `draft`, `published` | |

### `game_questions`, `game_options` and `game_option_scores`

| Table | Columns |
|---|---|
| `game_questions` | `game_id`, `prompt`, `sort_order` |
| `game_options` | `question_id`, `label`, `is_correct` (quizzes), `sort_order` |
| `game_option_scores` | `option_id`, `personality_key`, `points`. How much an answer counts towards each colour |

Visitors and members can read questions and option labels. `is_correct` isn't granted to
them, and `game_option_scores` is staff-only. Staff read the correct answers with
`staff_game_options()`. The page sends back the chosen options, and the server works out
the result.

### `personality_types`

The four results of the bird test, editable by staff.

| Column | Type | Notes |
|---|---|---|
| `key` | `red`, `yellow`, `green`, `blue`, primary key | |
| `bird_name` | text | To be chosen by the club |
| `colour` | text | A brand token, for example `--terracotta` |
| `summary`, `strengths`, `blind_spots`, `how_to_work_with` | text | |
| `image_media_id` | uuid → `media`, null | |

### `game_attempts` and `game_attempt_answers`

| `game_attempts` column | Type | Notes |
|---|---|---|
| `game_id` | uuid → `games` | |
| `profile_id` | uuid → `profiles`, null | When a signed-in member takes it |
| `name` | text, null | |
| `email` | text | Where the result is sent |
| `result_key` | text → `personality_types.key`, null | The bird, for the bird test |
| `score` | int, null | For quizzes |
| `marketing_consent` | bool | Separate tick box. False unless ticked |
| `emailed_at` | timestamptz, null | Set when the email provider accepts the message |

`game_attempt_answers`: `attempt_id`, `question_id`, `option_id`, one row per question.
The keys make sure the option belongs to the question.

`personality_attempt_scores` (view) totals each colour for an attempt from its answers.
Attempts are written only by server code, and the public can't read them.

---

## Testimonials and settings

### `testimonials`

Real quotes only, collected with permission. Attributed either to a member's profile, or
to a name for someone without one, never both.

| Column | Type | Notes |
|---|---|---|
| `quote` | text | |
| `profile_id` | uuid → `profiles`, null | |
| `author_name` | text, null | Only when there is no profile |
| `author_flock_id` | uuid → `flocks`, null | Only when there is no profile |
| `consent_at` | timestamptz | Required before it can be published |
| `status` | `draft`, `published` | |
| `sort_order` | int | |

### `site_settings`

One row, one typed column per setting, each with its own check. A new setting is a new
column.

| Column | Type | Today in |
|---|---|---|
| `join_url` | https URL | `lib/join.ts` |
| `whatsapp_rsvp` | digits | `lib/whatsapp.ts` |
| `whatsapp_partners` | digits | `lib/whatsapp.ts` |
| `whatsapp_merch` | digits | `config.whatsapp` in `app/merch/page.tsx` |
| `currency` | 3 letters | |
| `merch_deposit_pct` | 0 to 100 | `config.depositPct` |
| `mpesa_till` | digits, null | Not set yet |

Readable by everyone, since every value appears on the site. Only admins change it.

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
| **Public** | `published`, unarchived rows of public content. `profile_links` with `visibility = public`. `site_settings`. Leaderboard views | Nothing directly. RSVPs, merch orders and game attempts go through server actions that check and save the input |
| **Member** (signed in, with a `published` or `submitted` profile) | Everything the public can, plus `profile_links` with `visibility = members`, their own drafts, their own game attempts and score entries | Their own `profiles` row and `profile_links`. Their own `articles` while `draft` or `submitted`. The `status` of `photo_tags` for themselves. They can't publish, change their own `status`, or touch `staff_roles` |
| **Editor** | Everything | All content tables. Approve and reject submissions |
| **Admin** | Everything, including `audit_log` | Everything editors can, plus `staff_roles`, `site_settings`, `score_entries` and `awards` |

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
| `event` in `app/page.tsx` | `events` row "social-4" at the `venues` row Golden Tulip Westlands, plus a past `events` row "social-3" with Kalekye Mumo in `speakers` |
| `currentBook`, `shelfBooks` | `books`, `authors`, `book_authors`, `book_purchase_links`, plus `reading_cycles` |
| `partners` | `partners` |
| `posts` (empty) | `articles` with `external_url` |
| `testimonials` (empty) | `testimonials` |
| Champions block | `flocks` (Kiambu Road, Thika Road Bears), plus `awards` |
| `products`, `config` in `app/merch/page.tsx` | `merch_drops`, `merch_products`, `merch_options`, `merch_option_values`, `merch_variants`, `site_settings` |
| `SWATCH_COLOURS` in `MerchProductCard.tsx` | `merch_colours` |
| `lib/join.ts`, `lib/whatsapp.ts` | `site_settings` |
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
signed-in stranger, two members, an editor and an admin, and makes 96 checks,
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

- **Helpers are in `private`.** `private.current_profile_id()`, `private.is_staff()` and
  the rest are for access rules and triggers. The functions the app may call are in
  `public`: `approve_profile_changes()`, `profile_private()`, `staff_game_options()` and
  `merch_product_progress()`.
- **Applying to a project.** `supabase link --project-ref <ref>` once (it asks for the
  database password), then `supabase db push --remote`. Add `--include-seed` the first
  time. Staff invites are added with SQL in the dashboard, never in a migration.

### Projects

| | Ref | Region |
|---|---|---|
| Staging | `eqanskhfqaxtbxhdafiw` | West EU (Ireland) |
| Production | `enpytoybafponfsjoild` | West EU (Ireland) |

Production gets the migrations only after staging passes the Phase 5 gate.

### Supabase advisors

After migration 9, Supabase's security and performance advisors show no errors. The
warnings left are deliberate: the four functions above are meant to be callable, and
some tables have several read rules side by side (public, members-only, your own).

### Views the pages read

`event_cards`, `next_event`, `past_events`, `book_cards`, `current_reads`, `shelf`,
`mural_entries`, `flock_standings`, `member_standings`, `merch_variant_cards`,
`merch_order_totals`, `merch_run_counts`, `personality_attempt_scores`. All use
`security_invoker`, so the access rules still apply. Every view lists its columns: Postgres
fixes a view's columns when it is created, so `select *` would miss columns added later.
