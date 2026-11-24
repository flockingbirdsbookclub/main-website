import type { Metadata } from "next";
import { Nav } from "@/components/layout/Nav";
import { Footer } from "@/components/layout/Footer";
import { Band } from "@/components/ui/Band";
import { Card, CardGrid } from "@/components/ui/Card";
import { PhotoSlot } from "@/components/ui/PhotoSlot";
import { TicksList } from "@/components/ui/TicksList";
import { EventBanner } from "@/components/content/EventBanner";
import { BookCard, type Book } from "@/components/content/BookCard";
import { PartnerCard, type Partner } from "@/components/content/PartnerCard";
import { rsvpCtaLabel, type EventInfo } from "@/lib/event";
import { buildWhatsAppLink } from "@/lib/whatsapp";

// Join button. Paste a Google Form or Tally URL into JOIN_URL and the button
// points there instead. Left empty, it opens WhatsApp with the message started,
// the same way the RSVP and merch buttons work, so it is never a dead button.
const JOIN_URL = "";
const joinHref =
  JOIN_URL ||
  buildWhatsAppLink(
    "FLOCKING BIRDS \u00B7 I would like to join a flock\n\n" +
      "Name:\nArea of Nairobi:\nWhat I do:\nWhat I am working on right now:",
  );
// Partner enquiries are a different conversation to a membership request.
const partnerHref = buildWhatsAppLink(
  "FLOCKING BIRDS \u00B7 partnership enquiry\n\n" +
    "Business:\nWhat we offer:\nWhat we would like to do with the flock:",
);

// Real content as of this rebuild, ported verbatim from the legacy
// index.html — including its own still-unfilled placeholders (current
// book, partner names, testimonials). Per CLAUDE.md: never invent content
// that looks real. This becomes a Supabase read in a later phase; for now
// it's the single object every date-dependent spot on the page consumes.
const event: EventInfo = {
  eyebrowText: "The BookClub Social · Sat 3 October · open to everyone",
  shortLabel: "3 Oct",
  pillText: "Saturday 3 October",
  heading: "The BookClub Social",
  time: "1:00–6:00 PM",
  venueName: "Nairobi",
  venueAddress: "venue shared with everyone who RSVPs",
  who: "Open to everyone. You do not need to be a member",
  bring: "Yourself. Bring a friend who reads, or one who says they will",
};

const currentBook: Book = {
  title: "Add the current title here",
  author: "Author Name",
  purchaseUrl: null,
};

const shelfBooks: Book[] = [
  { title: "Blue Ocean Strategy", author: "Kim & Mauborgne", tag: "Heavy", purchaseUrl: null },
  { title: "The Innovation Stack", author: "Jim McKelvey", tag: "Heavy", purchaseUrl: null },
  { title: "How Will You Measure Your Life?", author: "Clayton Christensen", tag: "Heavy", purchaseUrl: null },
  { title: "Steal Like an Artist", author: "Austin Kleon", tag: "Lighter", purchaseUrl: null },
  { title: "Show Your Work!", author: "Austin Kleon", tag: "Lighter", purchaseUrl: null },
];

const partners: Partner[] = [
  { name: "Partner name", description: "Bookshop · 10% member discount", url: null },
  { name: "Partner name", description: "Venue", url: null },
  { name: "Partner name", description: "Photography", url: null },
  { name: "Partner name", description: "Catering", url: null },
];

// Homepage-only metadata. Next.js replaces (does not merge) the layout's
// openGraph block, so the full set is repeated here with the homepage URL.
export const metadata: Metadata = {
  alternates: { canonical: "/" },
  openGraph: {
    type: "website",
    siteName: "Flocking Birds Book Club",
    title: "Flocking Birds Book Club",
    description:
      "Flocking Birds is a Nairobi book club and growth community. Over 200 members across 12 flocks read one book every two months, apply it, and grow together.",
    url: "https://flockingbirdsbookclub.com/",
    images: ["https://flockingbirdsbookclub.com/share-card.jpg"],
  },
};

const organisationJsonLd = {
  "@context": "https://schema.org",
  "@type": "Organization",
  name: "Flocking Birds Book Club",
  description:
    "Flocking Birds is a Nairobi book club and growth community. Over 200 members across 12 flocks read one book every two months, apply it, and grow together.",
  url: "https://flockingbirdsbookclub.com/",
  foundingDate: "2024",
  areaServed: "Nairobi, Kenya",
};

export default function Home() {
  return (
    <>
      <Nav page="home" rsvpLabel={rsvpCtaLabel(event.shortLabel)} eventShortLabel={event.shortLabel} />

      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(organisationJsonLd) }}
      />
      <main id="top">
        {/* ========== HERO ========== */}
        <section className="hero" style={{ paddingBottom: 0 }}>
          <div className="wrap grid">
            <div style={{ paddingBottom: "clamp(30px,5vw,56px)" }}>
              <a className="evt" href="#social">
                <span className="evt-tag">THIS MONTH</span>
                <span className="evt-txt">{event.eyebrowText}</span>
                <span className="evt-go" aria-hidden="true">
                  →
                </span>
              </a>
              <h1>
                <span className="l">Growth is lonely.</span>
                <span className="l">It doesn&apos;t have to be.</span>
              </h1>
              <p className="sub">
                A Nairobi book club for people who are done reading alone. We pick hard books,
                actually apply them, and hold each other to it.
              </p>
              <div className="acts">
                <a className="btn btn-gold" href="#social">
                  RSVP for 3 October
                </a>
                <a className="btn btn-out" href="#join">
                  Join the flock
                </a>
              </div>
              <p className="note">200+ members · 12 flocks across Nairobi · new members welcome any cycle</p>
            </div>
            <div className="collage">
              <PhotoSlot
                className="a"
                src="/images/hero/collage-1.jpg"
                ratio="r34"
                slotLabel=""
                alt="Two members working through the book together at a Flocking Birds session"
              />
              <PhotoSlot src="/images/hero/collage-2.jpg" ratio="r1" slotLabel="" alt="The flock gathered for the community champions award" />
              <PhotoSlot src="/images/hero/collage-3.jpg" ratio="r1" slotLabel="" alt="A member at the table during a book review session" />
            </div>
          </div>
          <div className="strip">
            <div className="wrap" style={{ paddingLeft: 0, paddingRight: 0 }}>
              <div className="stats">
                <div>
                  <div className="n">200+</div>
                  <div className="l">Members</div>
                </div>
                <div>
                  <div className="n">12</div>
                  <div className="l">Flocks across Nairobi</div>
                </div>
                <div>
                  <div className="n">6</div>
                  <div className="l">Books a year</div>
                </div>
                <div>
                  <div className="n">{event.shortLabel}</div>
                  <div className="l">Next Social</div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <EventBanner
          event={event}
          description="Every cycle ends the same way. The whole flock in one room for the community book review, the flock awards, games, food, and the announcement of what we read next. Our third one, and the biggest so far."
          photoSrc="/images/social/photo.jpg"
        />

        {/* ========== MERCH (time-boxed) ========== */}
        <Band id="merch">
          <div className="wrap">
            <div className="merch-wrap">
              <div>
                <p className="eyebrow">
                  <TagIcon />
                  First drop
                </p>
                <h2>Merch, before it exists</h2>
                <p className="lede" style={{ marginTop: 16 }}>
                  Punny tees, an embroidered cap, a canvas tote and a set of archetype bookmarks. We
                  print to order, so nothing gets made unless enough of the flock wants it.
                </p>
                <p style={{ marginTop: 14, maxWidth: "56ch" }}>
                  Reserve your size with a deposit and collect it at the Social on 3 October. If an
                  item does not hit its run, you get the deposit back in full.
                </p>
                <div className="deadline">PREORDERS CLOSE 22 SEPTEMBER</div>
                <div className="acts" style={{ display: "flex", gap: 12, flexWrap: "wrap", marginTop: 22 }}>
                  <a className="btn btn-gold" href="/merch">
                    Reserve your merch
                  </a>
                </div>
              </div>
              <div>
                <div className="mrow">
                  <div className="ph" data-slot="TEE" />
                  <div className="ph" data-slot="CAP" />
                  <div className="ph" data-slot="TOTE" />
                </div>
                <div className="mrow" style={{ marginTop: 12 }}>
                  <div className="ph" data-slot="BOOKMARKS" />
                  <div className="ph" data-slot="TEE 2" />
                  <div className="ph" data-slot="TEE 3" />
                </div>
              </div>
            </div>
          </div>
        </Band>

        {/* ========== ABOUT ========== */}
        <section id="about">
          <div className="wrap">
            <div className="two wide">
              <div>
                <p className="eyebrow">
                  <PeopleIcon />
                  Who we are
                </p>
                <h2>
                  We&apos;re not just a brand.
                  <br />
                  We&apos;re a flock.
                </h2>
                <p className="lede" style={{ marginTop: 18 }}>
                  Flocking Birds is a growth community for intellectually curious builders
                  navigating career, purpose, faith and life together.
                </p>
                <p style={{ maxWidth: "58ch", marginTop: 16 }}>
                  High-growth seasons, career shifts, levelling up, job hunting, are exactly the
                  seasons people go through alone. Most networks stay at the surface. Most book
                  clubs are vibes with a book on the table. We wanted the room where you could be
                  honest about work, and then do something about it.
                </p>
                <p style={{ maxWidth: "58ch" }}>
                  It started in 2024 with three friends trying to stay in touch. We opened to the
                  public in March 2026. Since then we&apos;ve grown to over two hundred members
                  across twelve flocks.
                </p>
              </div>
              <PhotoSlot
                src="/images/about/photo.jpg"
                ratio="r43"
                slotLabel=""
                alt="The three Flocking Birds founders in conversation on a sofa"
              />
            </div>

            <CardGrid columns={3} className="about-cards">
              <Card icon={<TargetIcon />}>
                <h4>Our mission</h4>
                <p style={{ color: "var(--ink-soft)", marginTop: 8 }}>
                  To create intentional spaces where ambitious people grow through books,
                  conversation, accountability and community.
                </p>
              </Card>
              <Card icon={<EyeIcon />}>
                <h4>Our vision</h4>
                <p style={{ color: "var(--ink-soft)", marginTop: 8 }}>
                  A world where no one has to navigate their growth journey alone.
                </p>
              </Card>
              <Card icon={<CheckCircleIcon />}>
                <h4>Our promise</h4>
                <p style={{ color: "var(--ink-soft)", marginTop: 8 }}>
                  Real books. Real conversations. Real growth. Real community.
                </p>
              </Card>
            </CardGrid>
          </div>
        </section>

        {/* ========== PILLARS ========== */}
        <Band>
          <div className="wrap">
            <p className="eyebrow">
              <PillarsIcon />
              What holds us up
            </p>
            <h2>Three pillars</h2>
            <p className="lede" style={{ color: "#CFC2AE", marginTop: 16 }}>
              These come together or not at all.
            </p>
            <CardGrid columns={3} className="pillars-cards">
              <Card style={{ background: "#1C5340", borderColor: "#31624D" }}>
                <span className="num" style={{ color: "var(--gold)" }}>
                  01 · Challenge
                </span>
                <h4 style={{ color: "var(--ivory)" }}>We do hard things</h4>
                <p style={{ color: "#CFC2AE", marginTop: 8 }}>
                  Hard books, not comfortable ones. Honest conversations. A practical challenge
                  every book. Around three hours a week, to depth rather than surface.
                </p>
              </Card>
              <Card style={{ background: "#1C5340", borderColor: "#31624D" }}>
                <span className="num" style={{ color: "var(--gold)" }}>
                  02 · Accountability
                </span>
                <h4 style={{ color: "var(--ivory)" }}>We are doers</h4>
                <p style={{ color: "#CFC2AE", marginTop: 8 }}>
                  Peer check-ins and visible progress. The Implementation Showdown is where you
                  say out loud how you actually used the book.
                </p>
              </Card>
              <Card style={{ background: "#1C5340", borderColor: "#31624D" }}>
                <span className="num" style={{ color: "var(--gold)" }}>
                  03 · Christ &amp; Community
                </span>
                <h4 style={{ color: "var(--ivory)" }}>We do life together, and with God</h4>
                <p style={{ color: "#CFC2AE", marginTop: 8 }}>
                  Career transparency and faith in the same room. Sessions close in prayer. We say
                  this up front so everyone who joins has chosen it.
                </p>
              </Card>
            </CardGrid>
          </div>
        </Band>

        {/* ========== HOW IT WORKS ========== */}
        <section id="how">
          <div className="wrap">
            <p className="eyebrow">
              <CycleIcon />
              How it works
            </p>
            <h2>One book. Two months. Then we all meet.</h2>
            <p className="lede" style={{ marginTop: 16 }}>
              Your flock is a small group that meets near you. Every flock runs the same rhythm,
              so the whole community moves together.
            </p>

            <CardGrid columns={4} className="how-cards">
              <Card num="Weeks 1 to 8">
                <h4>Read together</h4>
                <p style={{ color: "var(--ink-soft)", marginTop: 8 }}>
                  Your flock takes one book over two months, discussing the chapters as you go.
                  Every member gets a turn leading a session.
                </p>
              </Card>
              <Card num="Throughout">
                <h4>Apply it</h4>
                <p style={{ color: "var(--ink-soft)", marginTop: 8 }}>
                  One practical challenge tied to the book. Small, real, and built for people with
                  full-time jobs.
                </p>
              </Card>
              <Card num="End of cycle">
                <h4>Come together</h4>
                <p style={{ color: "var(--ink-soft)", marginTop: 8 }}>
                  Every flock meets as one community for the book review, the Implementation
                  Showdown, the Hot Take Debate and the awards.
                </p>
              </Card>
              <Card num="Then">
                <h4>Next book drops</h4>
                <p style={{ color: "var(--ink-soft)", marginTop: 8 }}>
                  We announce the next title and the cycle restarts. A natural moment to bring
                  someone new in.
                </p>
              </Card>
            </CardGrid>

            <div style={{ marginTop: "clamp(40px,6vw,68px)" }}>
              <h3>Will you keep up? Here&apos;s the honest answer.</h3>
              <p style={{ maxWidth: "62ch", marginTop: 12, color: "var(--ink-soft)" }}>
                Two months a book. That is the whole answer. On most titles it works out at twenty
                or thirty pages a week, which fits around a full-time job and a life. And if you
                fall behind, come to the discussion anyway. Nobody is marking your homework.
              </p>
              <img
                className="bandimg"
                src="/images/how/room.jpg"
                alt="The room during the July community hangout"
              />
              <p className="note">Two months a book · six books a year · the flock picks what comes next.</p>
            </div>
          </div>
        </section>

        {/* ========== CURRENT READ ========== */}
        <Band id="reading">
          <div className="wrap">
            <div className="now">
              <div className="ph r34 cover" data-slot="COVER · book jacket 3:4" style={{ background: "#235843" }}>
                <img
                  loading="lazy"
                  src="/images/books/current-cover.png"
                  alt="Cover of the book the community is currently reading"
                />
              </div>
              <div>
                <span className="pill">Currently reading</span>
                <h2 style={{ marginTop: 16 }}>{currentBook.title}</h2>
                <p style={{ color: "#A8BBAE", fontFamily: "var(--mono)", fontSize: ".85rem", marginTop: 6 }}>
                  by {currentBook.author} · started 00 Month · review night 00 Month
                </p>
                <p style={{ color: "#CFC2AE", maxWidth: "52ch", marginTop: 16 }}>
                  One or two lines on why the flock picked this book and what everyone is trying to
                  get out of it. Keep it plain and specific.
                </p>
                <div className="acts" style={{ display: "flex", gap: 12, flexWrap: "wrap", marginTop: 24 }}>
                  <a className="btn btn-gold" href="#join">
                    Join before the next book
                  </a>
                  <a className="btn btn-out" href="#shelf">
                    See what we&apos;ve read
                  </a>
                  {currentBook.purchaseUrl ? (
                    <a className="btn btn-line" href={currentBook.purchaseUrl} target="_blank" rel="noopener noreferrer">
                      Buy from {currentBook.partnerStoreName ?? "our partner"}
                    </a>
                  ) : (
                    <span className="btn btn-line" data-pending>
                      Buy link coming soon
                    </span>
                  )}
                </div>
                <p style={{ color: "#A8BBAE", fontSize: ".86rem", marginTop: 22, maxWidth: "52ch", lineHeight: 1.65 }}>
                  <b style={{ color: "var(--ivory)" }}>How we do books.</b> We publish the reading
                  list ahead of time so you can plan. Get your copy from our partner bookshop at a
                  members&apos; discount, from a library, or however you normally buy books. We
                  support the authors we read.
                </p>
              </div>
            </div>
          </div>
        </Band>

        {/* ========== SHELF ========== */}
        <section id="shelf">
          <div className="wrap">
            <p className="eyebrow">
              <BooksIcon />
              The shelf
            </p>
            <h2>What we&apos;ve read together</h2>
            <p className="lede" style={{ marginTop: 16 }}>
              Confirm these titles and dates before this goes live. Add a cover image to each.
            </p>
            <div className="shelf" style={{ marginTop: 32 }}>
              {shelfBooks.map((book) => (
                <BookCard key={book.title} book={book} />
              ))}
            </div>
          </div>
        </section>

        {/* ========== CHAMPIONS ========== */}
        <section style={{ paddingTop: 0 }}>
          <div className="wrap">
            <div className="champ">
              <div>
                <p className="eyebrow" style={{ color: "#FFE4C0" }}>
                  <TrophyIcon />
                  Community champions
                </p>
                <h3 style={{ fontSize: "1.05rem", fontWeight: 700, color: "#FCE8DC" }}>
                  This cycle&apos;s top flock
                </h3>
                <div className="name">Kiambu Road</div>
                <ul>
                  <li>Showed up, every session</li>
                  <li>Held each other to it</li>
                  <li>Did the challenge, not just the reading</li>
                </ul>
              </div>
              <div>
                <img
                  className="champimg"
                  src="/images/champions/trophy.jpg"
                  alt="The Flocking Birds community champions trophy"
                />
                <div className="prev">
                  <div className="k">Previous champions</div>
                  <div className="v">Thika Road Bears</div>
                </div>
                <p style={{ color: "#FCE8DC", fontSize: ".92rem", margin: "18px 0 0" }}>
                  Awarded at every hangout to the flock that best embodies how we do this. Yes, it
                  is competitive. That is the point.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* ========== COMMUNITY / POSTS ========== */}
        <section id="community" style={{ paddingTop: 0 }}>
          <div className="wrap">
            <p className="eyebrow">
              <PostsIcon />
              From the flock
            </p>
            <h2>What our members are making</h2>
            <p className="lede" style={{ marginTop: 16 }}>
              Reviews, reflections, posts and threads from people in the community. Replace each
              card with a real post and link it out.
            </p>
            <CardGrid columns={3} className="posts">
              <div className="post">
                <PhotoSlot src="/images/community/post-placeholder.png" ratio="r169" slotLabel="Post image 16:9" alt="" />
                <div className="body">
                  <span className="kind">Book review</span>
                  <h4>Headline of the member&apos;s review</h4>
                  <p style={{ color: "var(--ink-soft)", fontSize: ".93rem", margin: 0 }}>
                    Two lines of the opening paragraph, enough to make someone want to click
                    through to the full piece.
                  </p>
                  <div className="who">Member name · Kiambu Road flock</div>
                </div>
              </div>
              <div className="post">
                <PhotoSlot src="/images/community/post-placeholder.png" ratio="r169" slotLabel="Post image 16:9" alt="" />
                <div className="body">
                  <span className="kind">LinkedIn post</span>
                  <h4>What this chapter changed at work</h4>
                  <p style={{ color: "var(--ink-soft)", fontSize: ".93rem", margin: 0 }}>
                    A short reflection a member shared publicly after applying the monthly
                    challenge.
                  </p>
                  <div className="who">Member name · Online flock</div>
                </div>
              </div>
              <div className="post">
                <PhotoSlot src="/images/community/post-placeholder.png" ratio="r169" slotLabel="Post image 16:9" alt="" />
                <div className="body">
                  <span className="kind">Reflection</span>
                  <h4>Six months in the flock</h4>
                  <p style={{ color: "var(--ink-soft)", fontSize: ".93rem", margin: 0 }}>
                    A longer piece on what changed, written by someone who joined at the March
                    onboarding.
                  </p>
                  <div className="who">Member name · Thika Road flock</div>
                </div>
              </div>
            </CardGrid>

            <CardGrid columns={3} className="testimonials" style={{ marginTop: "clamp(38px,6vw,60px)" }}>
              <div className="quote">
                <p>
                  Replace with a real quote from a member. Two sentences is plenty, and specific
                  beats glowing every time.
                </p>
                <div className="by">
                  <div className="av">
                    <img src="/images/community/avatar-placeholder.png" alt="" />
                  </div>
                  <div>
                    <div className="nm">Member name</div>
                    <div className="fl">Flock name</div>
                  </div>
                </div>
              </div>
              <div className="quote">
                <p>
                  The best testimonials name a concrete thing that changed. A promotion, a side
                  project shipped, a habit that stuck.
                </p>
                <div className="by">
                  <div className="av">
                    <img src="/images/community/avatar-placeholder.png" alt="" />
                  </div>
                  <div>
                    <div className="nm">Member name</div>
                    <div className="fl">Flock name</div>
                  </div>
                </div>
              </div>
              <div className="quote">
                <p>
                  Ask three members at the next hangout. Record it on a phone, transcribe the good
                  bit, get their nod before publishing.
                </p>
                <div className="by">
                  <div className="av">
                    <img src="/images/community/avatar-placeholder.png" alt="" />
                  </div>
                  <div>
                    <div className="nm">Member name</div>
                    <div className="fl">Flock name</div>
                  </div>
                </div>
              </div>
            </CardGrid>
          </div>
        </section>

        {/* ========== GALLERY ========== */}
        <section style={{ paddingTop: 0 }}>
          <div className="wrap">
            <p className="eyebrow">
              <GalleryIcon />
              The hangouts
            </p>
            <h2>Two hangouts in, and counting</h2>
            <p className="lede" style={{ marginTop: 16 }}>
              Every flock comes together after each book. Food, debate, awards, and the occasional
              argument about a chapter.
            </p>
            <div className="gal" style={{ marginTop: 32 }}>
              <img className="big" src="/images/gallery/photo-big.jpg" alt="Flocking Birds community hangout, July 2026" style={{ gridColumn: "span 2", gridRow: "span 2", borderRadius: 10, width: "100%", height: "100%", objectFit: "cover" }} />
              <img src="/images/gallery/photo-2.jpg" alt="Flocking Birds community hangout, July 2026" style={{ borderRadius: 10, width: "100%", height: "100%", objectFit: "cover" }} />
              <img src="/images/gallery/photo-3.jpg" alt="Flocking Birds community hangout, July 2026" style={{ borderRadius: 10, width: "100%", height: "100%", objectFit: "cover" }} />
              <img src="/images/gallery/photo-4.jpg" alt="Flocking Birds community hangout, July 2026" style={{ borderRadius: 10, width: "100%", height: "100%", objectFit: "cover" }} />
              <img src="/images/gallery/photo-5.jpg" alt="Flocking Birds community hangout, July 2026" style={{ borderRadius: 10, width: "100%", height: "100%", objectFit: "cover" }} />
            </div>
          </div>
        </section>

        {/* ========== PARTNERS ========== */}
        <Band id="partners">
          <div className="wrap">
            <div className="two">
              <div>
                <p className="eyebrow">
                  <PartnersIcon />
                  Partners
                </p>
                <h2>People who show up for us</h2>
                <p style={{ color: "#CFC2AE", maxWidth: "52ch", marginTop: 16 }}>
                  Service providers who have volunteered their time, given us deals for events, or
                  looked after our members. One of them gives every Flocking Birds member 10% off
                  books.
                </p>
                <p style={{ color: "#CFC2AE", maxWidth: "52ch" }}>
                  If you run something our community would genuinely benefit from, we would like to
                  hear from you. We are small, specific and growing fast.
                </p>
                <a
                  className="btn btn-gold"
                  id="partnerlink"
                  href={partnerHref}
                  target="_blank"
                  rel="noopener"
                  style={{ marginTop: 12 }}
                >
                  Partner with us
                </a>
              </div>
              <div>
                <div className="plogos" style={{ gridTemplateColumns: "repeat(2,1fr)" }}>
                  {partners.map((partner, i) => (
                    <PartnerCard key={i} partner={partner} />
                  ))}
                </div>
                <p className="note" style={{ color: "#93A89B" }}>
                  Swap each box for the partner&apos;s logo on Warm Ivory.
                </p>
              </div>
            </div>
          </div>
        </Band>

        {/* ========== JOIN ========== */}
        <section id="join" className="join">
          <div className="wrap">
            <div style={{ maxWidth: "62ch" }}>
              <p className="eyebrow">
                <JoinIcon />
                Join us
              </p>
              <h2>Find your flock.</h2>
              <p className="lede" style={{ marginTop: 16 }}>
                Tell us a little about yourself and where you are in Nairobi. We place you in a
                flock near you, personally, and you start with the next book.
              </p>
            </div>

            <div className="steps" style={{ maxWidth: 900 }}>
              <div className="step">
                <span className="n">1</span>
                <span className="tx">
                  <b>Fill the form</b>Takes about three minutes.
                </span>
              </div>
              <div className="step">
                <span className="n">2</span>
                <span className="tx">
                  <b>We place you</b>A real person matches you to the closest flock.
                </span>
              </div>
              <div className="step">
                <span className="n">3</span>
                <span className="tx">
                  <b>Start with the next book</b>You join at the start of a cycle, never halfway.
                </span>
              </div>
            </div>

            <div className="formbox">
              <div className="fb-grid">
                <div>
                  <h3>Ready when you are</h3>
                  <p style={{ marginTop: 10, maxWidth: "52ch" }}>
                    A few quick questions: your name, how to reach you, your area of residence,
                    where you are in your career, and what matters to you right now.
                  </p>
                  <p style={{ maxWidth: "52ch" }}>
                    We ask for your area so we can place you in the flock closest to you.
                  </p>
                  <a
                    className="btn btn-dark"
                    href={joinHref}
                    id="joinlink"
                    target="_blank"
                    rel="noopener"
                    style={{ marginTop: 8 }}
                  >
                    {JOIN_URL ? "Open the join form" : "Ask to join"}
                  </a>
                  <p className="note" id="joinnote">
                    {JOIN_URL
                      ? "Takes about three minutes."
                      : "Opens WhatsApp with your message started. We reply with the flock closest to you."}
                  </p>
                </div>
                <div className="fb-photo">
                  <img src="/images/join/photo.jpg" alt="The flock together at a Flocking Birds community hangout" />
                </div>
              </div>
            </div>

            <CardGrid columns={2} className="join-ticks" style={{ marginTop: 26 }}>
              <Card>
                <h4>Join us if</h4>
                <TicksList
                  variant="yes"
                  items={[
                    "You can give it about three hours a week",
                    "You would rather apply a book than quote it",
                    "You are fine with faith named out loud",
                  ]}
                />
              </Card>
              <Card>
                <h4>Not for you if</h4>
                <TicksList
                  variant="no"
                  items={[
                    "You want the vibes without the reading",
                    "You are here with a sales agenda",
                    "You are a chronic excuse maker",
                  ]}
                />
              </Card>
            </CardGrid>
          </div>
        </section>
      </main>

      <Footer page="home" eventShortLabel={event.shortLabel} />
    </>
  );
}

// ---------- icons (line icons, 24x24 grid, stroke 1.7, inherit colour) ----------

function iconProps() {
  return {
    className: "ico",
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: 1.7,
    strokeLinecap: "round" as const,
    strokeLinejoin: "round" as const,
    "aria-hidden": true,
    focusable: false,
  };
}

function TagIcon() {
  return (
    <svg {...iconProps()}>
      <path d="M3.5 11.4V4.6a1.1 1.1 0 0 1 1.1-1.1h6.8a1.1 1.1 0 0 1 .8.3l8 8a1.1 1.1 0 0 1 0 1.6l-6.8 6.8a1.1 1.1 0 0 1-1.6 0l-8-8a1.1 1.1 0 0 1-.3-.8z" />
      <circle cx={7.6} cy={7.6} r={1.4} />
    </svg>
  );
}

function PeopleIcon() {
  return (
    <svg {...iconProps()}>
      <circle cx={9} cy={8} r={3.2} />
      <path d="M3.4 19.4a5.8 5.8 0 0 1 11.2 0" />
      <path d="M16.4 5.3a3.2 3.2 0 0 1 0 5.9" />
      <path d="M17.6 14.4a5.8 5.8 0 0 1 3 5" />
    </svg>
  );
}

function TargetIcon() {
  return (
    <svg {...iconProps()} className="ico-lg">
      <circle cx={12} cy={12} r={8.5} />
      <circle cx={12} cy={12} r={4.4} />
      <circle cx={12} cy={12} r={0.9} />
    </svg>
  );
}

function EyeIcon() {
  return (
    <svg {...iconProps()} className="ico-lg">
      <path d="M1.9 12S5.5 5.5 12 5.5 22.1 12 22.1 12 18.5 18.5 12 18.5 1.9 12 1.9 12z" />
      <circle cx={12} cy={12} r={3.1} />
    </svg>
  );
}

function CheckCircleIcon() {
  return (
    <svg {...iconProps()} className="ico-lg">
      <circle cx={12} cy={12} r={8.6} />
      <path d="M8.2 12.3l2.6 2.6 5-5.4" />
    </svg>
  );
}

function PillarsIcon() {
  return (
    <svg {...iconProps()}>
      <path d="M3 5.5h18" />
      <path d="M6 8.5v11" />
      <path d="M12 8.5v11" />
      <path d="M18 8.5v11" />
      <path d="M3.5 19.5h17" />
    </svg>
  );
}

function CycleIcon() {
  return (
    <svg {...iconProps()}>
      <path d="M20 12a8 8 0 0 1-13.7 5.6" />
      <path d="M4 12a8 8 0 0 1 13.7-5.6" />
      <path d="M17.4 3.1v3.4h-3.4" />
      <path d="M6.6 20.9v-3.4h3.4" />
    </svg>
  );
}

function BooksIcon() {
  return (
    <svg {...iconProps()}>
      <path d="M4 4.5h3.6v13.5H4z" />
      <path d="M9.6 4.5h3.6v13.5H9.6z" />
      <path d="M16.4 6.6l3.5 1-3 10.9-3.5-1z" />
      <path d="M2.8 21h18.4" />
    </svg>
  );
}

function TrophyIcon() {
  return (
    <svg {...iconProps()}>
      <circle cx={12} cy={8.6} r={5.1} />
      <path d="M8.6 12.9L7 21l5-2.6L17 21l-1.6-8.1" />
    </svg>
  );
}

function PostsIcon() {
  return (
    <svg {...iconProps()}>
      <path d="M3.2 6.5h11.6a1.7 1.7 0 0 1 1.7 1.7v5.4a1.7 1.7 0 0 1-1.7 1.7H8.2L4.4 19v-3.7h-1.2a1.7 1.7 0 0 1-1.7-1.7V8.2a1.7 1.7 0 0 1 1.7-1.7z" />
      <path d="M19 9.4h1.8a1.7 1.7 0 0 1 1.7 1.7v5.4a1.7 1.7 0 0 1-1.7 1.7h-.9v3l-3-3" />
    </svg>
  );
}

function GalleryIcon() {
  return (
    <svg {...iconProps()}>
      <rect x={3.5} y={5.5} width={17} height={15} rx={2.2} />
      <path d="M3.5 10h17" />
      <path d="M8 3.4v4" />
      <path d="M16 3.4v4" />
    </svg>
  );
}

function PartnersIcon() {
  return (
    <svg {...iconProps()}>
      <circle cx={8.6} cy={12} r={5.1} />
      <circle cx={15.4} cy={12} r={5.1} />
    </svg>
  );
}

function JoinIcon() {
  return (
    <svg {...iconProps()}>
      <path d="M13.5 3.5H19a1.5 1.5 0 0 1 1.5 1.5v14a1.5 1.5 0 0 1-1.5 1.5h-5.5" />
      <path d="M9.5 8.2L13.3 12l-3.8 3.8" />
      <path d="M13 12H3.5" />
    </svg>
  );
}
