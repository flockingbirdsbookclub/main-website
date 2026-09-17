# Flocking Birds Book Club — working with this site

Claude reads this file automatically at the start of every session in this repo.
It exists so that anyone on the team can make changes without the site drifting.

**Read this before changing anything.**

---

## What this is

A two-page static site for a Nairobi book club. Live at **flockingbirdsbookclub.com**,
hosted on Netlify, deployed automatically from this repository.

```
index.html   the landing page. Currently in "event mode" for the 3 October Social
merch.html   print-to-order merch preorder page
404.html     not-found page
netlify.toml Netlify config: caching, security headers, the /merch short link
```

No build step. No framework. No npm. Everything each page needs lives inside its own
HTML file, including the images as base64. Open `index.html` in a browser and you see
exactly what is live.

**Do not introduce a build system, a framework, a CSS library, or a package manager.**
Three non-technical people maintain this. The moment it needs compiling, it stops being
maintainable by them. This constraint is deliberate, not an oversight.

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
| `--terracotta-text` | `#AD5035` | Terracotta darkened so small text passes contrast |
| `--sage` | `#98B095` | Muted green. Small text on the dark green, dots, fills |
| `--teal` | `#214F54` | Deep teal. From the logo. Links, secondary surfaces |
| `--taupe` | `#8F7864` | From the logo. Paper, kraft, packaging |
| `--ink` | `#2E2118` | Body text on light grounds |
| `--ink-soft` | `#6B5B4C` | Secondary text |
| `--ink-faint` | `#75695E` | Captions. The lightest ink that still passes AA |
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

**The hidden forms.** Both pages contain a `<form data-netlify="true" hidden>` near the
bottom. Netlify reads these at deploy time to know what fields to capture. Delete them
and RSVPs and merch orders stop being recorded. They look like dead code. They are not.

**`netlify.toml`.** Sets caching, security headers, and the `/merch` short link.

**The `record()` function in `merch.html`** and the `fetch('/')` block in `index.html`.
These POST each submission to Netlify Forms. The WhatsApp handoff runs alongside them,
not instead of them.

---

## Where things live

| To change | Go to |
|---|---|
| Merch products, prices, colours, sizes | `merch.html`, the `PRODUCTS` array |
| Preorder deadline, deposit %, WhatsApp number | `merch.html`, the `CONFIG` object above it |
| RSVP WhatsApp number | `index.html`, search `var WA` |
| Current book and dates | `index.html`, search `Currently reading` |
| Event details | `index.html`, the `<section id="social">` block |

---

## Placeholders still in place

Unfilled image slots carry a gold **TO DO** tag so they are visible: merch shots, book
covers, post images, testimonial avatars, partner logos.

`merch.html` has a yellow **DRAFT** banner at the top listing five things it needs before
the page can be shared. Delete that whole block once they are filled.

**Testimonials are deliberately empty.** Do not write quotes and attribute them to
members. Real quotes only, collected with permission.

---

## Deploying

Netlify builds from this repository. Push a change, or edit a file on github.com and
commit, and the site updates in about a minute. Every deploy is kept, so a bad change can
be rolled back from the Netlify Deploys tab.

Do not drag folders onto Netlify any more. The repository is the source of truth now, and
mixing the two makes it impossible to tell what is live.

---

## After 3 October

The site is in event mode and will need unwinding:

- Delete or rewrite `<section class="band" id="social">` as a recap
- Delete `<section id="merch">` once preorders close
- Change the nav button from `RSVP · 3 Oct` back to `Join the flock`
- Replace the `3 Oct / Next Social` stat tile

---

## If you are unsure

Choose the quieter option, then ask. Adding a colour, a typeface or a new component is
how a brand ends up with two of everything. The full brand system, including the logo
rules, the archetypes and the messaging, lives in the Flocking Birds brand guidelines.
