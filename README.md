# Flocking Birds website

**[flockingbirdsbookclub.com](https://flockingbirdsbookclub.com)**

The website for Flocking Birds, a Nairobi book club. It has a homepage, with the next
Social, the current read, the shelf and partners, and a merch preorder page at `/merch`.

Built with Next.js and hosted on Netlify. `main` is the live site; new work is tested on
`staging` first (see Deploying below).

| Read this | For |
|---|---|
| [`docs/PROJECT_SCOPE.md`](docs/PROJECT_SCOPE.md) | What the project covers, what is done, what comes next, and open items. A living document |
| [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md) | The database design for the admin area, member mural, blog, leaderboard, merch and games |
| [`CLAUDE.md`](CLAUDE.md) | How to change the site without breaking the brand: colours, type, layout, voice, and where each piece of content lives |

---

## Run it on your computer

You need Node.js 22 (the version is pinned in `.nvmrc`).

```bash
npm install      # once
npm run dev      # then open http://localhost:3000
```

Before pushing, check that it builds. Netlify runs the same command, and a failed build
does not go live:

```bash
npm run build
```

---

## What is where

```
app/page.tsx           the homepage, and the content on it (event, books, partners)
app/merch/page.tsx     the merch preorder page, its products and settings
app/not-found.tsx      the page shown for an address that does not exist
app/layout.tsx         shared page head: fonts, share tags, favicons
app/globals.css        the one stylesheet, including the brand colours
components/            the building blocks: buttons, nav, footer, cards, the RSVP form
lib/                   settings used in several places (see below)
public/                images, favicons, robots.txt, sitemap.xml, __forms.html
docs/                  project scope
netlify.toml           Netlify build settings, headers and caching
next.config.ts         redirects from the old .html addresses, security headers
scripts/               one-off image migration script from the rebuild
index.html, merch.html, 404.html   the old static site, kept for reference only
```

### Common changes

| To change | Edit |
|---|---|
| The next Social: date, time, venue, price, poster | `app/page.tsx`, the `event` object |
| Current book and shelf, covers, buy links | `app/page.tsx`, `currentBook` and `shelfBooks` |
| Partners | `app/page.tsx`, `partners` |
| Join form link (every "Join the flock" button) | `lib/join.ts` |
| WhatsApp number for RSVPs and partner enquiries | `lib/whatsapp.ts` |
| Merch products, prices, deadline, deposit, order number | `app/merch/page.tsx` |
| Nav and footer links | `lib/navigation.ts` |

The full list, and the steps for moving on to the next Social, are in `CLAUDE.md`.
Once the admin area is built (see the roadmap in `docs/PROJECT_SCOPE.md`), most of these
move out of code and into forms.

---

## Deploying

Netlify builds from this repository.

| Branch | What it is |
|---|---|
| `main` | **The live site.** Every push deploys flockingbirdsbookclub.com |
| `staging` | Where all new work collects and gets tested, on its own Netlify link |
| `phase-N-name` | A larger phase, cut from `staging` and merged back by pull request |
| `hotfix-*` | An urgent live fix, cut from `main`, then merged into `staging` too |

Nothing merges from `staging` to `main` until every phase is tested and signed off. The
rules are under "Branching and release" in `docs/PROJECT_SCOPE.md`.

If a build fails, the live site stays on the last good version and the error shows in
the Netlify **Deploys** tab. Any earlier deploy can be restored from there.

Do not drag folders onto Netlify. The repository is the only source of what is live.

**Domain.** `flockingbirdsbookclub.com` already points at Netlify, and HTTPS is automatic.
Nothing to set up.

**Forms.** RSVPs and merch orders are saved in the Netlify **Forms** tab, as well as
being sent on WhatsApp. That depends on `public/__forms.html`. Do not delete it.

**Secrets.** This repository is public. Never commit keys or passwords. When Supabase is
added, its keys go into Netlify's environment variables, not into the code.
