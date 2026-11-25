# Project scope: flockingbirdsbookclub.com

A living document. It records what the website is for, what is in scope, what has been
built, and what comes next. When scope changes, change this file in the same commit as
the work, or before the work starts.

The database design for everything here is in [`DATA_MODEL.md`](DATA_MODEL.md).

Last updated: 25 November 2026

---

## How to use this document

- **Adding scope.** Add a row to [Scope backlog](#scope-backlog) with status `Proposed`.
  Once it is agreed, give it a phase in [Roadmap](#roadmap) and mark it `Planned`. If it
  needs data, add it to `DATA_MODEL.md` too.
- **Finishing a phase.** Only when its [phase gate](#phase-gate) passes. Mark it `Done`,
  add a line to [Done so far](#done-so-far) with the date and commit, and move anything
  left over to [Open items](#open-items).
- **Dropping scope.** Do not delete it. Move it to [Out of scope](#out-of-scope) with one
  line on why, so nobody proposes it again without knowing the history.
- **Log every change** in the [Change log](#change-log) at the bottom.

Status words: `Done`, `In progress`, `Next`, `Planned`, `Proposed`, `Blocked`.

How to edit the site day to day (colours, copy, where each piece of content lives) is in
[`CLAUDE.md`](../CLAUDE.md). This file covers what to build and why.

---

## What the site is for

Flocking Birds is a Nairobi book club for working professionals, organised into small
reading groups called flocks. The website's jobs, in order:

1. **Get people to join a flock.** Every "Join the flock" button opens the join form.
2. **Get people to the next Social.** RSVP goes to WhatsApp and is saved to Netlify Forms.
3. **Show the members and their work.** The Show Your Work Mural, member articles, the
   leaderboard.
4. **Keep members learning between books.** Games, and the "What bird are you?" test.
5. **Show what the club reads and who it works with.** The current book, the shelf,
   partners, past Socials, merch.

### Who uses it

- **Visitors** deciding whether to join or come to a Social.
- **Members**, who sign in with an email link to edit their profile and write articles.
- **Staff**: the club maintainers, who are not developers. They run everything through
  `/admin`, without editing code or waiting for a deploy.

---

## Features

| # | Feature | What it is | Phase |
|---|---|---|---|
| 1 | **Admin site** | `/admin` for staff: the next Social, books, partners, settings, photos, the approval queue, points, merch, games | 7, then each feature adds its screens |
| 2 | **Show Your Work Mural** | Member directory at `/members`. Flock leaders first, then members. Each profile has a photo, flock, profession, something fun, ways to connect, and group photos they're tagged in. Members fill in their own profile at `/account`; staff approve it | 10 |
| 3 | **Merch store** | Catalogue at `/merch`, in drops with a deadline and minimum run, Cotton Bureau style. "Order" goes to the partner store that prints and ships. Our own preorder can be switched on per product | 13 |
| 4 | **Leaderboard** | Flocks and members score points by category, per season (usually one book). Staff award points; some are automatic (attended a Social, published an article). At `/leaderboard`, and on profiles and flock pages | 12 |
| 5 | **Games** | Learning games at `/games`. First, "What bird are you?": a four-colour personality test that emails the result. Then quizzes about each book | 14 |
| 6 | **Past Socials** | A page per Social at `/socials/[slug]`: recap, speakers, poster, photos, the book | 9 |
| 7 | **Blog** | Members write articles at `/blog/[slug]`, attributed to their profile and built to share. Staff review before publishing. Can also link to pieces published elsewhere | 11 |

---

## Decisions

These are settled. Reopen one only with a reason that was not known at the time.

| Decision | Why |
|---|---|
| **Next.js (App Router, TypeScript)** | Shared components replace copy-pasted HTML, and it pairs with an admin area |
| **Hosted on Netlify** | Free plan allows commercial use (merch counts). Vercel's free plan does not. No DNS change |
| **Repository is public** | Netlify's free plan only builds private repositories for one Git contributor. No secrets live in the code |
| **Supabase for data, files and logins** | One service for the database, image storage and logins |
| **Two Supabase projects: staging and production** | Test data never touches the live database |
| **Staff log in individually** | Each change can be traced to a person. Roles: admin and editor |
| **Members log in with an email link** | No passwords to forget. Needed so profiles and articles are tied to a person |
| **Staff approve member content** | Profiles, profile changes and articles go public only after review |
| **Members choose who sees each contact link** | Public or members-only, per link. Phone and email default to members-only. Fits Kenya's Data Protection Act 2019 |
| **Leaderboard ranks flocks and members** | Points are a ledger of entries, never edited, so every total can be explained |
| **Merch: our catalogue, partner fulfilment** | The partner prints and ships. Our own preorder stays possible per product |
| **Email through a transactional provider** | Resend recommended. Sends bird-test results and login links from our own domain |
| **Plain CSS with the brand tokens** | No CSS library or UI kit |
| **Join form is a Google Form** | Set once, today in `lib/join.ts`, later in `settings` |
| **RSVP and partner enquiries go to WhatsApp** | How members already talk to the club. Each RSVP is also saved |
| **Empty content hides its section** | No "TO DO" boxes on the live site |
| **All work goes through `staging`** | See [Branching and release](#branching-and-release) |

---

## Branching and release

**`main` is the live site.** Every push to it deploys flockingbirdsbookclub.com.

**`staging` collects the work from every phase.** Nothing merges from `staging` to `main`
until every phase is finished, tested by both the developer and the club, and has no
known bugs.

- A phase that touches the database, logins or many files gets its own branch,
  `phase-N-name`, cut from `staging` and merged back by pull request.
- Small phases and docs go straight onto `staging`.
- Each branch has its own Netlify test link (branch deploys and deploy previews), using
  the staging Supabase project.
- **Urgent live fixes** (for example the Social details) go on a short `hotfix-*` branch
  from `main`, merged only with the club's approval, then merged into `staging` too so
  the two don't drift.

### Phase gate

A phase is done only when all of these hold. Then, and only then, the next one starts.

1. Its **goal** below is met and every **acceptance check** passes.
2. The developer has run the build, lint, the access-rule tests, and browser checks at
   320, 390, 768 and 1280px, on the staging link.
3. The club has tested it on the staging link and signed off.
4. The bugs found are fixed and checked again.

The result goes in [Done so far](#done-so-far).

---

## Roadmap

| Phase | What | Branch | Status |
|---|---|---|---|
| 1 to 4 | Next.js rebuild matching the old site | `rebuild-nextjs` | Done |
| 4b | Homepage clean-up for Social 4.0 | `rebuild-nextjs` | Done |
| Go-live | Rebuild live on flockingbirdsbookclub.com | `main` | Done |
| Docs | Scope, data model, branching | `staging` | Done |
| 5 | Supabase: schema, access rules, storage, seed data | `phase-5-supabase` | **Next** |
| 6 | Logins for staff and members | `phase-6-auth` | Planned |
| 7 | Admin core | `phase-7-admin` | Planned |
| 8 | Homepage reads from Supabase | `phase-8-live-data` | Planned |
| 9 | Past Socials | `staging` | Planned |
| 10 | Show Your Work Mural | `phase-10-mural` | Planned |
| 11 | Blog | `phase-11-blog` | Planned |
| 12 | Leaderboard | `phase-12-leaderboard` | Planned |
| 13 | Merch store | `phase-13-merch` | Planned |
| 14 | Games and the bird test | `phase-14-games` | Planned |
| 15 | Final check and release to `main` | `staging` | Planned |

Why this order:
- Past Socials comes early because the content exists and it needs no member logins.
- The mural comes before the blog because articles are attributed to profiles.
- The leaderboard comes after both, because it awards points for them.

Older commit messages call the merch page assembly "Phase 5". It is part of Phase 4 here.

### Phase goals and acceptance checks

**5. Supabase.** *Goal: every table in `DATA_MODEL.md` exists, is locked down, and holds
today's content.*
- Migrations in `supabase/migrations/` create the whole schema from empty, and run again
  without errors.
- Access-rule tests pass for a signed-out visitor, a member and a staff user. A
  signed-out client can't write to any table, or read members-only links, drafts or
  `audit_log`.
- Storage buckets exist with their rules. Uploads over 5 MB or of the wrong type are
  refused.
- Seed data matches the live homepage: Social 4.0, Social 3.0, the books, partners and
  flocks.
- Staging and production projects are both set up. Keys are only in Netlify environment
  variables.

**6. Logins.** *Goal: staff and members can sign in, and each sees only what they
should.*
- An email link signs a member in, and their profile is matched by email.
- `/admin` refuses anyone not in `staff_roles`. `/account` refuses anyone signed out.
- Sessions last: you are still signed in after closing the browser and coming back a
  week later, and signing out works.
- Login emails come from our domain, not Supabase's default sender.

**7. Admin core.** *Goal: staff can run the homepage content without code.*
- Staff can create, edit and publish a Social, a book and reading cycle, a partner, and
  settings.
- Image uploads need alt text, and are resized.
- The approval queue lists submitted profiles and articles.
- Every write appears in `audit_log`.

**8. Homepage on live data.** *Goal: an admin edit shows on the homepage with no deploy.*
- The homepage reads from Supabase and looks the same as before at every breakpoint.
- Changing the Social date in `/admin` updates the hero, the stat tile, the nav, the
  Social section, the RSVP message and the footer.
- A list with no published rows renders nothing.
- If Supabase is slow or down, the page still loads with a sensible fallback.

**9. Past Socials.** *Goal: every past Social has its own page.*
- `/socials` lists past Socials. `/socials/social-3` shows the recap, Kalekye Mumo and
  the photos.
- When a Social's date passes, it moves from "next" to "past" on its own.
- Each page has its own title and share preview.

**10. Show Your Work Mural.** *Goal: members can show up on the mural, safely.*
- A member fills in their photo, flock, profession, fun fact and links at `/account`.
- The profile appears only after staff approve it. Changes are reviewed again.
- The mural shows leaders first, then members.
- Members-only links are hidden from signed-out visitors, including in the page source.
- Group photos appear on a profile only after the member approves the tag.

**11. Blog.** *Goal: members publish articles that are attributed to them and share well.*
- A member writes, saves a draft and submits. Staff publish or return it with a note.
- Each article shows its author's profile and has its own share preview.
- Publishing adds the author's points.

**12. Leaderboard.** *Goal: flock and member standings anyone can trust.*
- Staff award points by category. Automatic points arrive once and only once.
- Standings per season match the sum of the entries.
- Champions show from `awards`, replacing the hardcoded block.

**13. Merch store.** *Goal: members can browse drops and order.*
- Drops show their deadline and how close each item is to its minimum run.
- Partner-store products link out correctly. Preorder products keep today's WhatsApp
  and M-Pesa flow.
- Totals and deposits are calculated on the server.

**14. Games.** *Goal: the bird test works end to end, and new games are content, not
code.*
- Someone takes the test, gets their bird on screen and by email within a minute.
- Answer weights never reach the browser.
- Marketing consent is a separate box, unticked by default.
- A staff member can add a book quiz from `/admin` without a code change.

**15. Final check and release.** *Goal: `staging` is ready to replace `main`.*
- Full check against `CLAUDE.md`: breakpoints, contrast, voice, 44px targets.
- Production Supabase seeded, keys set in Netlify, and the end-to-end admin flow tested.
- The club signs off on the whole of `staging`. One pull request merges it into `main`.

### Phase 4b: homepage clean-up (done)

- Every button goes somewhere real. No links to `#`.
- Next Social updated to **BookClub Social 4.0, Surrounded by Idiots edition**: Saturday
  5 December, 12 to 6 PM, Golden Tulip Westlands, KES 2,000 including buffet lunch, with
  the poster.
- "Join the flock" is the gold button everywhere. "RSVP for Social 4.0" is the secondary.
- Real book covers, with "Buy from Kibanga Books" links where Kibanga stocks the book.
- Three real partners: Kibanga Books (10% off for members), Book Embossers, Punny Crafts.
- Social 3.0 recap in the gallery. Merch off the homepage. Posts and testimonials hidden.
- Design pass: sentence case, focus rings that pass contrast, buttons named for what they do.

---

## Done so far

| Date | What | Commit |
|---|---|---|
| 15 to 18 Sep 2026 | Original two-page static site, texture, icons, `CLAUDE.md` | `db60749` to `f34b22b` |
| 24 Nov 2026 | Phases 1 to 4: Next.js rebuild matching the old site | `e68dfff` to `a0fcec8` |
| 24 Nov 2026 | Phase 4b: homepage clean-up for Social 4.0 | `ca391f2` |
| 24 Nov 2026 | Join buttons to the Google Form, Social 3.0 recap trimmed | `a2ac62f` |
| 24 Nov 2026 | Design passes: sentence case, focus rings, action names | `9a795df`, `912197f` |
| 24 Nov 2026 | Node 22 pinned for Netlify builds | `7877a88` |
| 24 Nov 2026 | Rebuild merged to `main` and **live on flockingbirdsbookclub.com** | `ab0cd41`, `3908eb8` |
| 24 Nov 2026 | Security headers on every page | `71e7b56` |
| 25 Nov 2026 | Lazy-loaded images, lighter poster, merch timer fix | `5f6d0dc` |
| 25 Nov 2026 | RSVP and partner WhatsApp number changed to 254716681166 | `7dc8c3f` |
| 25 Nov 2026 | Scope for seven new features, data model, `staging` branch | on `staging` |

Checked on the live site after go-live: both pages load, old `.html` addresses redirect,
the not-found page works, all homepage images load, security headers are present, and
`__forms.html` is served for Netlify Forms.

---

## Open items

Things waiting on someone, not blocked work.

### Needed for Phase 5

| Item | Waiting on | Notes |
|---|---|---|
| Two Supabase projects (staging, production) | Club | Send the URL and anon key for each. The service role keys go only into Netlify env vars |
| Staff emails, and who is admin or editor | Club | |
| Netlify branch deploys for `staging`, and deploy previews | Club | Site configuration, then Build & deploy, then Branches and deploy contexts |

### Needed later

| Item | Waiting on | Phase |
|---|---|---|
| Email provider account (Resend), and DNS records on the domain | Club | 6 |
| Consent wording for profiles and photo tags | Club | 10 |
| Whether a member's flock history is public | Club | 10 |
| Scoring categories and points | Club | 12 |
| The partner merch store, and its links | Club | 13 |
| Bird names for red, yellow, green and blue | Club | 14 |
| Bird test questions. Our own wording, based on the four-colour model, not copied from the book | Club and dev | 14 |

### Live site

| Item | Waiting on | Notes |
|---|---|---|
| Test RSVP appears in Netlify Forms | Club | Send one, check Netlify, delete it |
| Merch page WhatsApp number | Club | `/merch` still uses 254723906069 |
| M-Pesa till number for the Social | Club | Goes in the RSVP note |
| Kibanga link for The Innovation Stack | Club | |
| Websites for Book Embossers and Punny Crafts | Club | Instagram until then |
| `share-card.jpg`, 1200x630 | Club | Shared links show no preview image without it |
| Delete the old `index.html`, `merch.html`, `404.html` | Dev | Reference only now |

---

## Scope backlog

New ideas go here first. Agree them, then give them a phase.

| Idea | Status | Notes |
|---|---|---|
| Switch images to `next/image` | Proposed | Worth it once images come from Supabase Storage |
| Flock pages, `/flocks/[slug]` | Proposed | The data model already supports it |
| | | |

---

## Out of scope

| Item | Why |
|---|---|
| Moving to Vercel | Free plan forbids commercial use. Pro costs about USD 20 a month |
| Public sign-up | Members are added by staff and claim their profile by email |
| Taking card payments on the site | M-Pesa by WhatsApp works, and partner stores handle their own checkout |
| Made-up testimonials, posts or profiles | Real content only, with permission |

---

## Risks

- **Access rules.** A mistake could let anyone edit content or see members' contact
  details. Write and test the rules in Phase 5, before any screen exists.
- **Personal data.** Member profiles, contacts and quiz emails fall under Kenya's Data
  Protection Act 2019. Collect only what is shown, record consent, and let members
  remove their profile.
- **Moderation.** Members write public content. Nothing goes live without staff review.
- **Email delivery.** Without proper DNS records, results and login links land in spam.
- **Upload checks.** Image type and size are checked on the server.
- **Login sessions.** Test coming back a week later, not only the first login.
- **Long-lived staging.** The longer `staging` runs, the further it drifts from `main`.
  Merge every hotfix back into `staging` straight away.
- **Free plan limits.** Supabase pauses idle free projects (add a keep-alive ping).
  Netlify's free plan has build-minute limits, and branch deploys use them.

---

## Change log

| Date | Change |
|---|---|
| 25 Nov 2026 | Document created. Roadmap, decisions and done list carried over from the rebuild plan |
| 25 Nov 2026 | Added seven features: admin, mural, merch store, leaderboard, games, past Socials, blog. Added `DATA_MODEL.md`. Roadmap re-sequenced to Phases 5 to 15 with goals and checks. Members now log in, so "member accounts" left Out of scope. Added the staging branch workflow and phase gate |
