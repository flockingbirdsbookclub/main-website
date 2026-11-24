# Flocking Birds Book Club — working with this site

Claude reads this file automatically at the start of every session in this repo.
It exists so that anyone on the team can make changes without the site drifting.

**Read this before changing anything.**

---

## What this is

A two-page site for a Nairobi book club. Live at **flockingbirdsbookclub.com**,
hosted on Netlify, deployed automatically from this repository.

It is a **Next.js** app (App Router, TypeScript). It used to be two hand-written HTML
files with no build step; it was rebuilt so the pages share components and so content
can later be edited through an admin area instead of in code. The rebuild plan, with
its phases, is in the commit history (`Phase 1` to `Phase 5`). Supabase and the
`/admin` screens are not built yet. Until they are, all content is in the page files.

```
app/layout.tsx           shared <html>, <head>, fonts, default metadata
app/page.tsx             the landing page, with the next Social near the top
app/merch/page.tsx       print-to-order merch preorder page
app/not-found.tsx        not-found page
app/globals.css          the one stylesheet for every page, including the colour tokens
components/ui/           Button, Band, Card, PhotoSlot, TicksList
components/layout/       Nav, Footer (one of each, used on both pages)
components/content/      EventBanner (the Social + RSVP), BookCard, PartnerCard,
                         MerchShop, MerchProductCard
lib/                     navigation links, event helpers, WhatsApp links, Netlify Forms
public/                  images, favicons, and __forms.html (see Do not touch)
netlify.toml             Netlify config: build command, security headers, caching
next.config.ts           Next.js config, including redirects for the old .html addresses
index.html, merch.html,  the old static site. No longer served. Kept for reference
404.html                 until the rebuild is live, then delete them
```

To see it locally: `npm install` once, then `npm run dev` and open http://localhost:3000.
`npm run build` must pass before anything is pushed; Netlify runs the same command.

**Do not add a CSS library, a UI kit, an icon library or a second framework.** The
stylesheet is plain CSS on purpose, so the tokens below stay the only source of colour.
New UI is a component in `components/` built from what is already there.

---

## Colour

Use the CSS custom properties. Never hardcode a hex that is not in this table.

### Core

| Token | Hex | Use |
|---|---|---|
| `--nest` | `#0C4831` | Primary dark green. Main dark surfaces |
| `--deep` | `#083222` | Darker green. Footer, closing blocks, masthead |
| `--ivory` | `#F3EDE3` | Warm ivory. The light page ground |
| `--paper` | `#FAF6EE` | Slightly lighter ivory. Cards on the light ground |
| `--espresso` | `#462D1D` | Deep brown. From the logo |
| `--gold` | `#EFAE1E` | Mustard gold. The accent. Roughly 10% of any layout |
| `--terracotta` | `#C55B3D` | Warm red. Second accent, used sparingly |

### Support

| Token | Hex | Use |
|---|---|---|
| `--terracotta-text` | `#9D482D` | Terracotta darkened so small text passes contrast, including over the ivory texture |
| `--sage` | `#98B095` | Muted green. Small text on the dark green, dots, fills |
| `--teal` | `#214F54` | Deep teal. From the logo. Links, secondary surfaces |
| `--taupe` | `#8F7864` | From the logo. Paper, kraft, packaging |
| `--ink` | `#2E2118` | Body text on light grounds |
| `--ink-soft` | `#6B5B4C` | Secondary text |
| `--ink-faint` | `#695E55` | Captions. The lightest ink that still passes AA, including over the ivory texture |
| `--rule` | `#DED3C4` | Dividers |
| `--rule-soft` | `#EAE1D4` | Card borders |

### Greens derived from `--nest`

Do not invent new greens. These are the whole set:

| Hex | Use |
|---|---|
| `#083222` | Deep — footer, cover, CTA blocks |
| `#072D1E` | Darkest — masthead |
| `#134D36` / `#18503A` | Decorative circles |
| `#1C5340` | Card sitting on green |
| `#235843` | Photo-slot ground on green |
| `#31624D` | Border on a dark card |
| `#3F6C58` | Hairline rule on green |

### The plaster texture

Both pages carry a plaster wash. It is one greyscale image stored twice, as
`public/images/texture/tex.webp` at full strength and `tex-soft.webp` at 15 per cent.
`app/globals.css` points the CSS variables `--tex` and `--tex-soft` at them.

It works by `background-blend-mode: multiply`. The image sits in the element's own
background layer and is multiplied into the colour underneath it, so it can never
touch text, photos or anything else on top. Nothing needs a z-index.

To texture a new block, give it a background colour and add the class `tex`, or add
its selector to the texture rule at the bottom of the stylesheet.

Two things to know before you change it:

- On the greens the wash only **darkens** a dark ground, so every contrast ratio goes
  up. You cannot break contrast by adding it to a green block.
- On ivory it darkens a light ground, so contrast goes **down**. That is why it runs at
  15 per cent there, only on `body`, and only above 900px wide. `--ink-faint` and
  `--terracotta-text` were darkened to clear 4.5:1 even on the texture's darkest pixel.
  If you strengthen the ivory wash, recompute both.

### The bookmark

The vertical logo on its bookmark is the only mark in the nav. It links home.

- **Wide screens (1020px and up):** the bar becomes a three column grid, `1fr auto 1fr`.
  Two equal outer columns put the middle one dead centre, which is where the bookmark
  hangs. Three links sit left, three links and the "Join the flock" button sit right.
- **Below 1020px:** it moves to the top left and the links collapse into the menu button.
- It is `position: absolute`, so it can hang past the bar without making the bar taller.
- A few lines of JS add `.scrolled` to the header once the page moves. The bar and the
  bookmark then shrink **together**, 66px to 52px and 96px to 76px, so the overhang stays
  at about 45 per cent of the bar height either way. Shrink one without the other and the
  mark looks stranded. Remove the class entirely and the bookmark sits on top of the page
  as you scroll.

Both pages use the same `components/layout/Nav.tsx`. On the merch page the bookmark links
to the homepage instead of the top, and the menu ends with "Back to the homepage". The
merch page header is `header.head`, not bare `header`, because the nav is a `<header>` too
and the bare selector would clip the bookmark.

The bookmark is terracotta, not gold. Ivory on terracotta measures 3.05:1, which is fine
for a logotype (WCAG exempts them) but is **not** a pairing to reuse for real text.

### The hero headline

`<h1>` holds two sentences, each in its own `<span class="l">`. The span is `display:block`
with `text-wrap: balance`, so the headline always breaks **between** the sentences and each
one balances on its own. Do not put a `<br>` back in: a `<br>` forces one break but does
nothing to stop each half wrapping again, which is how it ended up as four ragged lines.

Two settings keep it to two lines from 480px to 1440px:

- `font-variation-settings: 'wdth' 106` — Archivo is an extended face and 118 was too wide
  for the hero column
- `font-size` tops out at `3.6rem`, and the hero only goes two column at **1120px**, not
  900px, because between those widths the text column is too narrow for the headline

Change the copy and you have to re-check the line count at 390, 768, 1120 and 1440.

### Icons

Line icons, inline SVG, one 24x24 grid, `stroke-width` 1.7, `currentColor`, no fills.
17px in an eyebrow, 28px on a card. They inherit the colour of whatever they sit in.

**The bird submark is not an all-purpose icon.** It earns its place in the nav bookmark
and the footer mark. Everywhere else, use an icon that means the thing: a target for
mission, an eye for vision, a calendar for the hangouts, a tag for merch. A mark that
appears on every single section stops reading as a mark and starts reading as decoration.

Adding a new section? Draw the icon on the same grid at the same weight, or reuse one
already in the file. Do not import an icon library.

### Nav order follows the page

The nav, the mobile menu and the footer Explore column list the sections in the order a
visitor actually scrolls past them:

**Social, About, How it works, Reading, Community, Partners**

(The Social link reads as the date, "5 Dec Social", from the `event` object. "Community"
lands on the champions block, which starts the community stretch.)

The list lives once, in `lib/navigation.ts`, and the nav, menu and footer all read it.
If you add, remove or move a section, change it there to match the page.
A nav in a different order to the page makes scrolling feel broken even when every
link works.

### Green sections must be `.band`

Every colour on this site defaults to the **light** ground: `h2` is green, body text is
brown, eyebrows are terracotta. The `.band` class is what flips all of that for a dark
ground, in one place:

```css
.band{background:var(--nest);color:var(--ivory)}
.band h2,.band h3,.band h4{color:var(--ivory)}
.band p{color:#CFC2AE}
.band .eyebrow{color:var(--gold)}
```

Give a section a green background **without** `.band` and it silently keeps the light
ground colours: a green heading on a green background, terracotta on green at 2.49:1,
invisible sub-headings. Nothing errors. It just disappears. That is exactly what happened
to the join section, and it went unnoticed for weeks because the body copy was the one
thing that still happened to be readable.

So: green background, `class="band"`. Always. If a section needs green and cannot take
the class, copy all four rules across, not just the background.

### Alternate light and dark

Sections go green, ivory, green, ivory down the page. Two of the same in a row read as one
long section and the boundary between them vanishes. The current order:

```
hero            green      how         ivory      community   ivory
the Social      ivory      reading     green      partners    green
about+pillars   green      shelf       ivory      join        ivory
                                                  footer      green
```

Shelf, champions (`#community`) and the gallery run together on purpose. They use `padding-top:0` so they
read as one long ivory stretch, not three sections.

Before adding a section, check what is above and below it, and give it `.band` if it lands
on a green beat. Removing a section usually breaks the pattern for everything below it.
When merch came off the homepage, About and the pillars merged into one green band to
keep the alternation.

Cards inside a `.band` switch to the dark card greens automatically (`.band .card`).

### Buttons

One gold button per section, at most. Across the site the gold button means **join**:
"Join the flock" in the nav and hero, "Join before the next book" on the current read,
"Ask to join" in the join section. Attending a Social is always the secondary, outline
button ("Attend Social 4.0"). "Partner with us" is the one other gold button, alone in the
partners band.

Every button and link must go somewhere real: an anchor that exists on the page, a page,
WhatsApp with a message started, or a real external URL. If there is nowhere to send
people yet, leave the button out rather than linking to `#`.

### Yes and no lists

`.ticks.yes` and `.ticks.no` are the scannable qualifier lists, used for "Join us if" and
"Not for you if". The tick and cross are drawn with `::before` content, so there is no icon
file to ship. One line per item. If an item needs two lines it is too long, cut it.

### Contrast is not optional

Every text and background pair on this site has been measured. Keep it that way.
Small text needs **4.5:1**, large text (18pt+ or 14pt bold) needs **3:1**.

Verified pairings on `#0C4831`:

| Foreground | Ratio | Verdict |
|---|---|---|
| Warm Ivory `#F3EDE3` | 9.08:1 | Safe for anything |
| Muted body `#CFC2AE` | 6.03:1 | Safe |
| Footer grey-green `#A8BBAE` | 5.23:1 | Safe |
| Mustard Gold `#EFAE1E` | 5.41:1 | Safe |
| Sage `#98B095` | 4.52:1 | Safe, but only just. Do not darken it |
| Terracotta `#C55B3D` | 2.49:1 | **Never put terracotta on green** |

Those are the flat values. With the texture on, each one measures higher, not lower.

If you change a colour, compute the ratio before committing. Do not estimate it by eye.

---

## Typography

Two typefaces. **Never add a third.**

- **Archivo** — display. Headings, numbers, buttons, labels. Weights 700 and 800
- **Karla** — body. Paragraphs, list items, captions
- `--mono` is used for small tracked labels and eyebrows

Rules that hold across the site:

- Sentence case everywhere. Only eyebrows are uppercase
- Only eyebrows get letter-spacing
- Body text never exceeds about 66 characters per line
- Headings get `text-wrap: balance`

---

## Layout

- Content sits in `.wrap`, max-width with side padding. Never remove the side gutter
- Rows use flex or grid with `gap`. Not per-element margins
- Everything must work at **320px wide**. That is a real constraint, not a nicety
- Every tappable thing is at least **44px tall**. Buttons, links, form fields, footer links
- Images get `max-width: 100%`
- The page body must never scroll sideways

Before shipping any layout change, check it at 320px, 390px, 768px and 1280px.

---

## Voice

How the site talks:

- Plain and direct. Short sentences
- Honest over impressive. "Two months a book. That is the whole answer" beats a
  paragraph of aspiration
- Never claim something the club does not actually do. Programme names, member numbers
  and event formats must be real
- **No em dashes.** Use commas, colons or full stops
- No corporate speak. No "leverage", "unlock", "empower", "journey"
- Warm, a little wry. Not jokey

---

## Do not touch

**`public/__forms.html`.** It holds two hidden forms, `rsvp` and `merch-preorder`. Netlify
reads them at deploy time to know what fields to capture. Nobody visits the file. Delete
it and RSVPs and merch orders stop being recorded. It looks like dead code. It is not.
If you add a field to the RSVP or the order form, add it here too.

**`lib/netlifyForms.ts`** and the calls to `recordSubmission()` in `EventBanner.tsx` and
`MerchShop.tsx`. These POST each submission to `/__forms.html`, which is what puts it in
the Netlify Forms tab. With Next.js on Netlify they must POST to that static file, not
to `/`. The WhatsApp handoff runs alongside them, not instead of them.

**`netlify.toml`.** Sets the build command, the Next.js plugin, security headers and
caching. Redirects for the old `.html` addresses live in `next.config.ts`; links already
shared on WhatsApp point at `/merch.html`, so keep them.

**`--tex` and `--tex-soft`** and the two files in `public/images/texture/`. Deleting them
flattens both pages.

**The metadata.** `app/layout.tsx` sets the shared `<head>`: language, theme colour,
favicons, fonts, and default description and share tags. Each page then sets its own
`metadata`: title, canonical URL and Open Graph tags. Next.js **replaces** the layout's
`openGraph` block rather than merging it, so a page that sets `openGraph` must set all of
it (title, description, url, image), not just the URL. `app/page.tsx` also carries the
JSON-LD Organization block. None of it is visible on the page, which is exactly why it
goes missing. Without the Open Graph tags a shared link has no title or description.

Images are files in `public/images/`, not base64. Book covers, partner logos and merch
photos will move to Supabase Storage when the admin is built. The texture, nav mark,
gallery and other fixed photos stay in `public/`.

---

## Where things live

| To change | Go to |
|---|---|
| Merch products, prices, colours, sizes | `app/merch/page.tsx`, the `products` array |
| Preorder deadline, deposit %, WhatsApp number for orders | `app/merch/page.tsx`, the `config` object |
| RSVP, join and partner WhatsApp number | `lib/whatsapp.ts`, `WHATSAPP_NUMBER` |
| Join button destination | `app/page.tsx`, `JOIN_URL`. Empty means it opens WhatsApp |
| Merch product photos | `app/merch/page.tsx`, the `photoSrc` field on each product |
| Current book and shelf, covers and Kibanga links | `app/page.tsx`, `currentBook` and `shelfBooks` |
| Partners (name, role, card image, link) | `app/page.tsx`, `partners` |
| Member posts and testimonials | `app/page.tsx`, `posts` and `testimonials`. Empty hides them |
| Event date, time, venue, price, poster | `app/page.tsx`, the `event` object. Every date on the page reads from it |
| Last Social recap | `app/page.tsx`, the `.recap` block in the gallery |
| Event section layout and RSVP form | `components/content/EventBanner.tsx` |
| Nav, menu and footer links | `lib/navigation.ts` |
| Colours, spacing, every style | `app/globals.css` |

## Content that is not there yet

**Empty lists hide their section. Nothing shows a TO DO box on the homepage.** Posts and
testimonials are empty arrays (`posts`, `testimonials` in `app/page.tsx`), so the "From the
flock" block does not render. Add a real entry and it appears. The same rule holds for
partners, and for buy links: a book with no `purchaseUrl` shows no buy link.

**Testimonials are deliberately empty.** Do not write quotes and attribute them to
members. Real quotes only, collected with permission. The same goes for member posts.

**Social payment.** The RSVP note says we reply with how to pay the KES 2,000 by M-Pesa.
If the club gets a till number, put it in that note in `EventBanner.tsx`.

**Large images get a `-web` copy.** Originals stay as they were uploaded; the page uses a
copy resized to about 800px tall (`innovation-stack-web.jpg`, `surrounded_by_idiots-web.jpg`,
`Blue-Ocean-Strategy-web.jpg`, and the partner cards as `.jpg`). Make one with
`sips --resampleHeight 800 in.jpg --out in-web.jpg`.

`app/merch/page.tsx` has a yellow **DRAFT** banner at the top listing five things it needs before
the page can be shared. It is not linked from the homepage while there is no drop on.

**The join and partner buttons open WhatsApp.** There is no join form yet. Paste a Google
Form or Tally URL into `JOIN_URL` in `app/page.tsx` and the button switches to it, changes
its own label, and the WhatsApp fallback stops being used. Until then nobody hits a dead
button.

**The order summary shows a thumbnail per line.** It uses each product's `photo`, and falls
back to a tile with the product kind while photos are still missing. Clicking a thumbnail or
a product name scrolls back to that card and flashes it, and "Add something else" returns to
the shop. Fill in `photoSrc` and all of that starts showing real product shots.

**`share-card.jpg` does not exist yet.** Both pages point their Open Graph tags at it.
Until a real 1200x630 image sits in `public/`, links shared on WhatsApp or LinkedIn
show a title and description but no picture.

---

## Deploying

Netlify builds from this repository: it runs `npm run build` and publishes the result.
Push a change, or edit a file on github.com and commit, and the site updates in a couple
of minutes. If the build fails, the live site stays on the last good version and the
error is in the Netlify Deploys tab. Every deploy is kept, so a bad change can
be rolled back from the Netlify Deploys tab.

Do not drag folders onto Netlify any more. The repository is the source of truth now, and
mixing the two makes it impossible to tell what is live.

---

## Changing the event

Everything about the next Social is the `event` object at the top of `app/page.tsx`:
heading, edition, date, time, venue, price, poster. The hero pill, the stat tile, the nav
and footer link, the Social section and the RSVP WhatsApp message all read from it.

To move on to the next Social: upload its poster to `public/images/social/`, update the
`event` object, and move the last Social into the gallery as a recap row (see the Social
3.0 row for the pattern). Change the current book in `currentBook` at the same time.

---

## If you are unsure

Choose the quieter option, then ask. Adding a colour, a typeface or a new component is
how a brand ends up with two of everything. The full brand system, including the logo
rules, the archetypes and the messaging, lives in the Flocking Birds brand guidelines.

The decks use the same plaster wash on their green pages, so a slide and a section of
the site now read as the same surface. If you change the texture here, change it there.
