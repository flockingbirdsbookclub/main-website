-- Seed data: what the live homepage and merch page show today, so the site
-- looks the same on the day it switches to Supabase.
--
-- No personal data goes in this file: the repository is public. Staff
-- invites and member profiles are added in the Supabase dashboard or /admin.
--
-- Safe to run more than once: every insert skips rows that already exist.

-- ---------------------------------------------------------------------------
-- Settings
-- ---------------------------------------------------------------------------

insert into public.site_settings (join_url, whatsapp_rsvp, whatsapp_partners, whatsapp_merch, currency, merch_deposit_pct)
values ('https://forms.gle/QkmrkPRywfeGpRkq7', '254716681166', '254716681166', '254723906069', 'KES', 50)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Lookups
-- ---------------------------------------------------------------------------

insert into public.link_kinds (key, label, default_visibility, sort_order) values
  ('linkedin',  'LinkedIn',  'public',  1),
  ('instagram', 'Instagram', 'public',  2),
  ('x',         'X',         'public',  3),
  ('website',   'Website',   'public',  4),
  ('email',     'Email',     'members', 5),
  ('phone',     'Phone',     'members', 6),
  ('whatsapp',  'WhatsApp',  'members', 7)
on conflict (key) do nothing;

insert into public.partner_kinds (key, label, sort_order) values
  ('bookshop', 'Bookshop', 1),
  ('merch',    'Merch',    2),
  ('gifting',  'Gifting',  3),
  ('venue',    'Venue',    4),
  ('other',    'Other',    5)
on conflict (key) do nothing;

insert into public.event_kinds (key, label, sort_order) values
  ('social', 'BookClub Social', 1)
on conflict (key) do nothing;

insert into public.merch_categories (key, label, sort_order) values
  ('t_shirt',   'T-shirt',   1),
  ('cap',       'Cap',       2),
  ('tote',      'Tote',      3),
  ('bookmarks', 'Bookmarks', 4)
on conflict (key) do nothing;

insert into public.merch_colours (key, label, hex) values
  ('forest', 'Forest', '#0C4831'),
  ('navy',   'Navy',   '#1F2E45'),
  ('cream',  'Cream',  '#EFE6D6'),
  ('black',  'Black',  '#211E1B'),
  ('clay',   'Clay',   '#B4634A')
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- Images that already live in the site's public/ folder
-- ---------------------------------------------------------------------------

insert into public.media (bucket, path, alt) values
  ('site', '/images/social/bookclub_social_4-web.jpg',
   'Poster for BookClub Social 4.0, Surrounded by Idiots edition: four personality types, one room. Saturday 5 December, 12 to 6 PM, Golden Tulip Westlands, KES 2,000 covers buffet lunch.'),
  ('site', '/images/social/kalekye_mumo_2.JPG',
   'Social 3.0 guest speaker card: Kalekye Mumo, The Art of Communication, a practical workshop on public speaking'),
  ('site', '/images/books/surrounded_by_idiots-web.jpg',   'Cover of Surrounded by Idiots by Thomas Erikson'),
  ('site', '/images/books/Blue-Ocean-Strategy-web.jpg',    'Cover of Blue Ocean Strategy by Kim & Mauborgne'),
  ('site', '/images/books/great_mental_models.jpg',        'Cover of The Great Mental Models by Shane Parrish'),
  ('site', '/images/books/innovation-stack-web.jpg',       'Cover of The Innovation Stack by Jim McKelvey'),
  ('site', '/images/books/how_will_measure_your_life.jpg', 'Cover of How Will You Measure Your Life? by Clayton Christensen'),
  ('site', '/images/books/steal-like-an-artist.jpg',       'Cover of Steal Like an Artist by Austin Kleon'),
  ('site', '/images/books/show-your-work.jpg',             'Cover of Show Your Work! by Austin Kleon'),
  ('site', '/images/partners/kibanga_books.jpg',  'Kibanga Books'),
  ('site', '/images/partners/book_embossers.jpg', 'Book Embossers'),
  ('site', '/images/partners/punny_crafts.jpg',   'Punny Crafts'),
  ('site', '/images/champions/trophy.jpg',        'The Flocking Birds community champions trophy')
on conflict (bucket, path) do nothing;

-- ---------------------------------------------------------------------------
-- Bird test results. Bird names are for the club to choose.
-- ---------------------------------------------------------------------------

insert into public.personality_types (key, colour) values
  ('red',    '--terracotta'),
  ('yellow', '--gold'),
  ('green',  '--nest'),
  ('blue',   '--teal')
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- Flocks and partners
-- ---------------------------------------------------------------------------

insert into public.flocks (slug, name, sort_order) values
  ('kiambu-road',      'Kiambu Road',      1),
  ('thika-road-bears', 'Thika Road Bears', 2),
  ('online',           'Online flock',     3)
on conflict (slug) do nothing;

insert into public.partners (slug, name, kind, description, member_offer, image_media_id, url, sort_order)
select v.slug, v.name, v.kind, v.description, v.offer, m.id, v.url, v.sort_order
  from (values
    ('kibanga-books',  'Kibanga Books',  'bookshop', null, '10% off for members',
     '/images/partners/kibanga_books.jpg', 'https://kibangabooks.com/', 1),
    ('book-embossers', 'Book Embossers', 'gifting', 'Embossed “From the library of” stamps', null,
     '/images/partners/book_embossers.jpg', 'https://www.instagram.com/bookembossers_ke/', 2),
    ('punny-crafts',   'Punny Crafts',   'gifting', 'Gifting partner', null,
     '/images/partners/punny_crafts.jpg', 'https://www.instagram.com/punnycraftskenya/', 3)
  ) as v(slug, name, kind, description, offer, image, url, sort_order)
  join public.media m on m.bucket = 'site' and m.path = v.image
on conflict (slug) do nothing;

-- ---------------------------------------------------------------------------
-- Authors and books
-- ---------------------------------------------------------------------------

insert into public.authors (slug, name) values
  ('thomas-erikson',       'Thomas Erikson'),
  ('w-chan-kim',           'W. Chan Kim'),
  ('renee-mauborgne',      'Renée Mauborgne'),
  ('shane-parrish',        'Shane Parrish'),
  ('jim-mckelvey',         'Jim McKelvey'),
  ('clayton-christensen',  'Clayton Christensen'),
  ('austin-kleon',         'Austin Kleon')
on conflict (slug) do nothing;

insert into public.books (slug, title, reading_weight, cover_media_id)
select v.slug, v.title, v.weight, m.id
  from (values
    ('surrounded-by-idiots',           'Surrounded by Idiots',           null,      '/images/books/surrounded_by_idiots-web.jpg'),
    ('blue-ocean-strategy',            'Blue Ocean Strategy',            'heavy',   '/images/books/Blue-Ocean-Strategy-web.jpg'),
    ('the-great-mental-models',        'The Great Mental Models',        null,      '/images/books/great_mental_models.jpg'),
    ('the-innovation-stack',           'The Innovation Stack',           'heavy',   '/images/books/innovation-stack-web.jpg'),
    ('how-will-you-measure-your-life', 'How Will You Measure Your Life?', 'heavy',  '/images/books/how_will_measure_your_life.jpg'),
    ('steal-like-an-artist',           'Steal Like an Artist',           'lighter', '/images/books/steal-like-an-artist.jpg'),
    ('show-your-work',                 'Show Your Work!',                'lighter', '/images/books/show-your-work.jpg')
  ) as v(slug, title, weight, cover)
  join public.media m on m.bucket = 'site' and m.path = v.cover
on conflict (slug) do nothing;

insert into public.book_authors (book_id, author_id, position)
select b.id, a.id, v.position
  from (values
    ('surrounded-by-idiots',           'thomas-erikson',      1),
    ('blue-ocean-strategy',            'w-chan-kim',          1),
    ('blue-ocean-strategy',            'renee-mauborgne',     2),
    ('the-great-mental-models',        'shane-parrish',       1),
    ('the-innovation-stack',           'jim-mckelvey',        1),
    ('how-will-you-measure-your-life', 'clayton-christensen', 1),
    ('steal-like-an-artist',           'austin-kleon',        1),
    ('show-your-work',                 'austin-kleon',        1)
  ) as v(book, author, position)
  join public.books b on b.slug = v.book
  join public.authors a on a.slug = v.author
on conflict (book_id, author_id) do nothing;

insert into public.book_purchase_links (book_id, partner_id, url)
select b.id, (select id from public.partners where slug = 'kibanga-books'), v.url
  from (values
    ('surrounded-by-idiots',           'https://kibangabooks.com/books/surrounded-by-idiotsthomas-erikson/'),
    ('blue-ocean-strategy',            'https://kibangabooks.com/books/blue-ocean-strategy-w-chan-kim-reneemouborgne-paperback/'),
    ('the-great-mental-models',        'https://kibangabooks.com/books/the-great-mental-models-by-parrish-shane/'),
    ('how-will-you-measure-your-life', 'https://kibangabooks.com/books/how-will-you-measure-your-life-by-clayton-m-christensen-james-allworth-karen-dillon/'),
    ('steal-like-an-artist',           'https://kibangabooks.com/books/steal-like-an-artist-10-things-nobody-told-you-about-being-creative-by-austin-kleon/'),
    ('show-your-work',                 'https://kibangabooks.com/books/show-your-work-10-ways-to-share-your-creativity-and-get-discovered-austin-kleon-book-by-austin-kleon/')
  ) as v(book, url)
  join public.books b on b.slug = v.book
on conflict (book_id, url) do nothing;

-- Current read: two months, ending at Social 4.0. Shelf books have no
-- recorded dates, so sort_order keeps them in the order the page shows.
insert into public.reading_cycles (book_id, starts_on, ends_on, sort_order)
select b.id, v.starts_on, v.ends_on, v.sort_order
  from (values
    ('surrounded-by-idiots',           date '2026-10-04', date '2026-12-05', 0),
    ('blue-ocean-strategy',            null, null, 1),
    ('the-great-mental-models',        null, null, 2),
    ('the-innovation-stack',           null, null, 3),
    ('how-will-you-measure-your-life', null, null, 4),
    ('steal-like-an-artist',           null, null, 5),
    ('show-your-work',                 null, null, 6)
  ) as v(slug, starts_on, ends_on, sort_order)
  join public.books b on b.slug = v.slug
 where not exists (select 1 from public.reading_cycles c where c.book_id = b.id and c.flock_id is null);

-- ---------------------------------------------------------------------------
-- Socials
-- ---------------------------------------------------------------------------

insert into public.venues (slug, name) values ('golden-tulip-westlands', 'Golden Tulip Westlands')
on conflict (slug) do nothing;

insert into public.events (slug, kind, number, heading, edition, tagline, description, starts_at, ends_at,
                           venue_id, price_kes, price_note, who, bring, poster_media_id, book_id, status)
values (
  'social-4', 'social', '4.0', 'BookClub Social 4.0', 'Surrounded by Idiots edition',
  'Four personality types. One room. Which one are you?',
  'Every cycle ends the same way: the whole flock in one room. This time the book is Surrounded by Idiots, so the day is built around its four personality types. Book review, flock awards, games, a buffet lunch, and the announcement of what we read next.',
  timestamptz '2026-12-05 12:00:00+03', timestamptz '2026-12-05 18:00:00+03',
  (select id from public.venues where slug = 'golden-tulip-westlands'),
  2000, 'covers a buffet lunch',
  'Open to everyone. You do not need to be a member',
  'Yourself. Bring a friend who reads, or one who says they will',
  (select id from public.media where bucket = 'site' and path = '/images/social/bookclub_social_4-web.jpg'),
  (select id from public.books where slug = 'surrounded-by-idiots'),
  'published'
)
on conflict (slug) do nothing;

-- Social 3.0. The start and end times were never published; the club
-- should confirm them before /socials/social-3 goes live.
insert into public.events (slug, kind, number, heading, starts_at, ends_at, recap_title, recap_body, status)
values (
  'social-3', 'social', '3.0', 'BookClub Social 3.0',
  timestamptz '2026-10-03 12:00:00+03', timestamptz '2026-10-03 18:00:00+03',
  'The art of communication',
  'Our guest speaker, Kalekye Mumo, communications coach with Own Your Mic Programs at KM Network, ran a practical workshop on public speaking.',
  'published'
)
on conflict (slug) do nothing;

insert into public.speakers (slug, name, title, organisation, photo_media_id)
values ('kalekye-mumo', 'Kalekye Mumo', 'Communications coach', 'Own Your Mic Programs, KM Network',
        (select id from public.media where bucket = 'site' and path = '/images/social/kalekye_mumo_2.JPG'))
on conflict (slug) do nothing;

insert into public.event_speakers (event_id, speaker_id, talk_title)
select e.id, s.id, 'The art of communication'
  from public.events e, public.speakers s
 where e.slug = 'social-3' and s.slug = 'kalekye-mumo'
on conflict (event_id, speaker_id) do nothing;

-- ---------------------------------------------------------------------------
-- Champions
-- ---------------------------------------------------------------------------

insert into public.awards (title, flock_id, awarded_on, media_id)
select v.title, f.id, v.awarded_on,
       (select id from public.media where bucket = 'site' and path = '/images/champions/trophy.jpg')
  from (values
    ('Community champions', 'thika-road-bears', date '2026-07-01'),
    ('Community champions', 'kiambu-road',      date '2026-10-03')
  ) as v(title, flock_slug, awarded_on)
  join public.flocks f on f.slug = v.flock_slug
 where not exists (select 1 from public.awards a where a.flock_id = f.id and a.awarded_on = v.awarded_on);

-- ---------------------------------------------------------------------------
-- Leaderboard categories. Points are placeholders and every category is
-- switched off until the club agrees them (open item, Phase 12).
-- ---------------------------------------------------------------------------

insert into public.score_categories (slug, name, description, applies_to, default_points, is_automatic, is_active) values
  ('session-attendance', 'Came to the session',  'Attended a flock session',                              'both',   0, false, false),
  ('challenge-done',     'Did the challenge',    'Completed the book''s challenge, not just the reading', 'both',   0, false, false),
  ('hosted-session',     'Hosted a session',     'Led or hosted a flock session',                         'member', 0, false, false),
  ('brought-someone',    'Brought someone new',  'Brought a new reader who joined a flock',               'member', 0, false, false),
  ('social-attended',    'Came to the Social',   'Attended a BookClub Social',                            'member', 0, true,  false),
  ('article-published',  'Published an article', 'Had an article published on the blog',                  'member', 0, true,  false)
on conflict (slug) do nothing;

-- ---------------------------------------------------------------------------
-- Merch: the first drop, kept as a draft. Prices were suggestions, not
-- decisions, and the drop has closed (see the DRAFT banner on /merch).
-- ---------------------------------------------------------------------------

insert into public.merch_drops (slug, name, description, closes_at, collect_event_id, status)
values ('first-drop', 'The first drop', 'Printed in Nairobi. Limited run.',
        timestamptz '2026-09-22 23:59:59+03',
        (select id from public.events where slug = 'social-3'), 'draft')
on conflict (slug) do nothing;

insert into public.merch_products (slug, drop_id, category, name, description, price_kes, fulfilment, sort_order, status)
select v.slug, (select id from public.merch_drops where slug = 'first-drop'), v.category, v.name, v.blurb,
       v.price, 'preorder', v.sort_order, 'draft'
  from (values
    ('shelf-care',       't_shirt',   'Shelf Care',       1800, 'For the ones who treat a good book as a wellness routine. Front print, soft cotton.', 1),
    ('booked-and-busy',  't_shirt',   'Booked & Busy',    1800, 'The one you wear to the discussion you almost skipped. Front print, soft cotton.', 2),
    ('one-more-chapter', 't_shirt',   'One More Chapter', 1800, 'A lie we tell ourselves at 1am, printed on a shirt so at least it is honest now.', 3),
    ('know-your-bird',   't_shirt',   'Know Your Bird',   2000, 'The archetype series. Pick the bird you actually are, not the one you wish you were.', 4),
    ('embroidered-cap',  'cap',       'Embroidered Cap',  1500, 'The submark stitched on the front. One bird, one weight, a bookmark for a tail.', 5),
    ('book-tote',        'tote',      'Book Tote',        1000, 'Heavy canvas, flat bottom, actually fits a hardback and a laptop at the same time.', 6),
    ('bookmark-set',     'bookmarks', 'Bookmark Set',      400, 'Six punny bookmarks, one per archetype. The cheapest thing here and the most used.', 7)
  ) as v(slug, category, name, price, blurb, sort_order)
on conflict (slug) do nothing;

-- Options per product, in display order.
insert into public.merch_options (product_id, label, is_swatch, sort_order)
select p.id, v.label, v.swatch, v.sort_order
  from (values
    ('shelf-care', 'Colour', true, 1),       ('shelf-care', 'Size', false, 2),
    ('booked-and-busy', 'Colour', true, 1),  ('booked-and-busy', 'Size', false, 2),
    ('one-more-chapter', 'Colour', true, 1), ('one-more-chapter', 'Size', false, 2),
    ('know-your-bird', 'Bird', false, 1),    ('know-your-bird', 'Colour', true, 2), ('know-your-bird', 'Size', false, 3),
    ('embroidered-cap', 'Colour', true, 1),
    ('book-tote', 'Colour', true, 1),
    ('bookmark-set', 'Set', false, 1)
  ) as v(product, label, swatch, sort_order)
  join public.merch_products p on p.slug = v.product
on conflict (product_id, label) do nothing;

-- Values for each option. Swatch values point at a brand colour.
insert into public.merch_option_values (option_id, value, colour_key, sort_order)
select o.id, v.value, case when o.is_swatch then v.value end, v.ord
  from (values
    ('shelf-care', 'Colour', array['forest', 'navy', 'cream', 'black']),
    ('booked-and-busy', 'Colour', array['forest', 'navy', 'cream', 'black']),
    ('one-more-chapter', 'Colour', array['forest', 'navy', 'cream', 'clay']),
    ('know-your-bird', 'Colour', array['forest', 'navy', 'cream']),
    ('embroidered-cap', 'Colour', array['forest', 'navy', 'black']),
    ('book-tote', 'Colour', array['cream', 'forest']),
    ('know-your-bird', 'Bird', array['Owl', 'Woodpecker', 'Raven', 'Sparrow', 'Eagle', 'Dove']),
    ('bookmark-set', 'Set', array['Set of 6']),
    ('shelf-care', 'Size', array['S', 'M', 'L', 'XL', '2XL']),
    ('booked-and-busy', 'Size', array['S', 'M', 'L', 'XL', '2XL']),
    ('one-more-chapter', 'Size', array['S', 'M', 'L', 'XL', '2XL']),
    ('know-your-bird', 'Size', array['S', 'M', 'L', 'XL', '2XL'])
  ) as d(product, label, vals)
  cross join lateral unnest(d.vals) with ordinality as v(value, ord)
  join public.merch_products p on p.slug = d.product
  join public.merch_options o on o.product_id = p.id and o.label = d.label
on conflict (option_id, value) do nothing;

-- Every buyable combination. The function skips ones that already exist.
select public.merch_generate_variants(id) from public.merch_products;

-- ---------------------------------------------------------------------------
-- The bird test, as a draft with no questions yet (open item, Phase 14).
-- ---------------------------------------------------------------------------

insert into public.games (slug, title, kind, description, emails_result, status)
values ('what-bird-are-you', 'What bird are you?', 'personality',
        'A short test based on the four colour personality types. Your result is emailed to you.',
        true, 'draft')
on conflict (slug) do nothing;
