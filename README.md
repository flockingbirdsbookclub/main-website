# Flocking Birds website

**flockingbirdsbookclub.com**

Two static pages. No build step, no framework, no dependencies. Everything each page
needs is inside its own HTML file, so you can open `index.html` by double-clicking it
and see exactly what the live site will look like.

```
index.html            the landing page (currently in "event mode" for 3 October)
merch.html            the merch preorder page
404.html              shown when someone hits a URL that does not exist
netlify.toml          Netlify settings: caching, security headers, /merch short link
favicon.png           browser tab icon
apple-touch-icon.png  icon when a member saves the site to their phone home screen
favicon-32.png        small tab icon
robots.txt            tells search engines they may index the site
sitemap.xml           lists both pages for search engines
CNAME                 only used if you ever move to GitHub Pages. Netlify ignores it.
```

The domain is already set correctly in every file. Nothing to find and replace.

---

## Publishing on Netlify

**1. Drop the folder.** Go to **app.netlify.com/drop** and drag this whole folder onto
the page. You get a live URL in about ten seconds, something like
`https://cheerful-pastry-a1b2c3.netlify.app`. The site is already working at that point
and you can send it to the team.

**2. Claim it.** Netlify will prompt you to sign up to keep the site. Use
**flockingbirdsbookclub@gmail.com**, not a personal account, so whoever runs the club
later still has access.

**3. Give the site a sensible name.** *Site configuration* → *Change site name*. Call it
`flockingbirds`. Your temporary URL becomes `flockingbirds.netlify.app`, which is much
easier to share while DNS is still settling.

**4. Add the domain.** *Domain management* → *Add a domain* → type
`flockingbirdsbookclub.com`.

**5. Point the domain at Netlify.** At your domain registrar, add these records:

| Type | Host | Value |
|---|---|---|
| ALIAS *or* ANAME | `@` | `apex-loadbalancer.netlify.com` |
| CNAME | `www` | `flockingbirds.netlify.app` |

If your registrar does not offer ALIAS or ANAME, use this instead for the apex:

| Type | Host | Value |
|---|---|---|
| A | `@` | `75.2.60.5` |

Use ALIAS or ANAME if you can. Netlify recommends it over the A record because the fixed
IP cannot route through their global network as efficiently.

**6. HTTPS happens on its own.** Netlify issues a free Let's Encrypt certificate once DNS
resolves. Usually minutes, sometimes longer while DNS propagates, which can take up to 24
hours. Check *Domain management* → *HTTPS* if it has not appeared. Do this step now, not
the night before the event.

### Easier alternative

If your registrar lets you change nameservers, Netlify can run DNS for you. *Domain
management* → *Add a domain* → choose **Netlify DNS**, then paste the four nameservers
it gives you into your registrar. No individual records to set up, and the certificate
is automatic. The one catch: if your club email is on this domain, move the existing MX
records across first or email will stop arriving.

---

## Changing something later

Drag the updated folder onto the same site in Netlify and it redeploys. Every deploy is
kept, so you can roll back to a previous version from *Deploys* if something breaks.

Common edits:

| What | Where |
|---|---|
| Merch products, prices, colours, sizes | `merch.html`, the `PRODUCTS` block near the bottom |
| Preorder deadline, deposit %, WhatsApp number | `merch.html`, the `CONFIG` block just above `PRODUCTS` |
| RSVP WhatsApp number | `index.html`, search for `var WA` |
| Current book, dates, reading list | `index.html`, search for `Currently reading` |

If more than one of you will be editing, connect the site to a GitHub repository instead
of dragging folders. You get version history and browser-based editing, and Netlify
redeploys on every change. Worth doing once the event is behind you, not before.

---

## Still to fill in

Placeholders carry a gold **TO DO** tag on the image so you can spot them: six merch
shots, six book covers, three post images, three testimonial avatars, and the partner
logos.

The merch page has a yellow **DRAFT** banner at the very top listing what it still needs:
real prices, product photos, the WhatsApp number that receives orders, the deposit
percentage, and the closing date. **Delete that banner block before you share the page.**

Also missing: `share-card.jpg`, a 1200x630 image used when someone shares a link on
WhatsApp or LinkedIn. Both pages already reference it. Until it exists, links will share
without a preview image.

---

## After 3 October

The site is in event mode. Once the Social has happened:

- In `index.html`, delete the `<section class="band" id="social">` block, or rewrite it
  as a recap with photos from the day
- Delete the `<section id="merch">` block once preorders have closed
- Change the nav button back from `RSVP · 3 Oct` to `Join the flock`
- Swap the `3 Oct / Next Social` stat tile for whatever comes next
