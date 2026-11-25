-- Access-rule tests. Run by scripts/test-db.sh after the migrations and seed.
-- Each check signs in as a visitor, a member or staff and tries something.
-- Any failure stops the run with the check's name.
--
-- Uses made-up people at example.test. Never run against a real project.

\set ON_ERROR_STOP 1
set client_min_messages = warning;

create schema test;
grant usage on schema test to anon, authenticated, service_role;

create function test.ok(cond boolean, name text) returns void
language plpgsql as $$
begin
  if cond is not true then
    raise exception 'FAILED: %', name;
  end if;
end;
$$;

-- Runs a statement as the current role and passes only if it is refused.
create function test.refused(stmt text, name text) returns void
language plpgsql as $$
begin
  begin
    execute stmt;
  exception when others then
    return;
  end;
  raise exception 'FAILED (was allowed): %', name;
end;
$$;

create function test.count(q text) returns bigint
language plpgsql as $$
declare n bigint;
begin
  execute 'select count(*) from (' || q || ') t' into n;
  return n;
end;
$$;

grant execute on all functions in schema test to anon, authenticated, service_role;

-- Signing in: Supabase puts the user id in the JWT claims.
create function test.as_user(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid)::text, false);
  execute 'set role authenticated';
end;
$$;
create function test.as_anon() returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '', false);
  execute 'set role anon';
end;
$$;
grant execute on all functions in schema test to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- People (set up as the database owner)
-- ---------------------------------------------------------------------------

insert into public.staff_invites (email, role) values
  ('admin@example.test', 'admin'),
  ('editor@example.test', 'editor');

-- Staff create profiles before the members first sign in.
insert into public.profiles (email, slug, full_name, profession, fun_fact, status, consent_at) values
  ('amina@example.test', 'amina', 'Amina Test', 'Engineer', 'Reads in the bath', 'published', now()),
  ('brian@example.test', 'brian', 'Brian Test', 'Designer', 'Owns 40 bookmarks', 'submitted', null);

insert into public.flock_memberships (profile_id, flock_id, role)
select p.id, f.id, case p.slug when 'amina' then 'leader' else 'member' end
  from public.profiles p, public.flocks f where f.slug = 'kiambu-road';

-- First sign-ins.
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'admin@example.test'),
  ('00000000-0000-0000-0000-00000000000e', 'editor@example.test'),
  ('00000000-0000-0000-0000-0000000000a1', 'Amina@Example.test'),
  ('00000000-0000-0000-0000-0000000000b1', 'brian@example.test'),
  ('00000000-0000-0000-0000-0000000000c1', 'stranger@example.test');

select test.ok((select count(*) from public.staff_roles) = 2, 'invited staff get their role on first sign-in');
select test.ok((select role from public.staff_roles where user_id = '00000000-0000-0000-0000-00000000000e') = 'editor',
               'editor invite becomes editor');
select test.ok((select user_id from public.profiles where slug = 'amina') = '00000000-0000-0000-0000-0000000000a1',
               'profile is linked by email on first sign-in, ignoring case');
select test.ok((select count(*) from public.staff_roles where user_id = '00000000-0000-0000-0000-0000000000c1') = 0,
               'a stranger signing in does not become staff');

insert into public.profile_links (profile_id, kind, value)
select id, 'linkedin', 'https://linkedin.com/in/amina-test' from public.profiles where slug = 'amina';
insert into public.profile_links (profile_id, kind, value)
select id, 'phone', '0700000000' from public.profiles where slug = 'amina';
select test.ok((select visibility from public.profile_links where kind = 'phone') = 'members', 'phone defaults to members-only');
select test.ok((select visibility from public.profile_links where kind = 'linkedin') = 'public', 'linkedin defaults to public');

insert into public.events (slug, heading, starts_at, ends_at, status)
values ('secret-social', 'Not announced yet', now() + interval '60 days', now() + interval '60 days 6 hours', 'draft');

insert into public.games (slug, title, kind, status) values ('test-quiz', 'Test quiz', 'quiz', 'published');
insert into public.game_questions (game_id, prompt) select id, 'Pick one' from public.games where slug = 'test-quiz';
insert into public.game_options (question_id, label, is_correct)
select id, 'This one', true from public.game_questions;
insert into public.game_option_scores (option_id, personality_key, points)
select id, 'red', 2 from public.game_options;

insert into public.event_rsvps (event_id, name, phone) select id, 'Someone', '0711111111' from public.events where slug = 'social-4';
insert into public.game_attempts (game_id, email) select id, 'player@example.test' from public.games where slug = 'test-quiz';

-- A season covering today, with the automatic categories switched on.
insert into public.seasons (name, starts_on, ends_on) values ('Test season', current_date - 30, current_date + 30);
update public.score_categories set is_active = true, default_points = 5 where slug in ('article-published', 'social-attended');

-- ---------------------------------------------------------------------------
-- Visitors (signed out)
-- ---------------------------------------------------------------------------

select test.as_anon();

select test.ok(test.count('select * from public.events') = 2, 'visitors see the two published Socials, not the draft');
select test.ok((select slug from public.next_event) = 'social-4', 'next Social is Social 4.0');
select test.ok(test.count('select * from public.past_events') = 1, 'Social 3.0 is a past Social');
select test.ok((select slug from public.current_reads) = 'surrounded-by-idiots', 'current read is Surrounded by Idiots');
select test.ok(test.count('select * from public.shelf') = 6, 'the shelf has six books');
select test.ok(test.count('select * from public.partners') = 3, 'three partners are public');
select test.ok((select whatsapp_rsvp from public.site_settings) = '254716681166', 'public settings are readable');
select test.ok((select authors from public.book_cards where slug = 'blue-ocean-strategy') = 'W. Chan Kim & Renée Mauborgne',
               'co-authors are joined in order');
select test.ok(test.count($$select * from public.book_purchase_links$$) = 6, 'six books have a buy link');
select test.ok((select venue_name from public.next_event) = 'Golden Tulip Westlands', 'the next Social shows its venue');
select test.ok((select count(*) from public.merch_variants) = 0, 'visitors see no variants of draft merch');

select test.refused($$insert into public.events (slug, heading, starts_at, ends_at) values ('x', 'x', now(), now() + interval '1 hour')$$,
                    'visitors cannot create events');
select test.refused($$update public.site_settings set join_url = 'https://evil.test'$$, 'visitors cannot change settings');
select test.refused($$select email from public.profiles$$, 'visitors cannot read member emails');
select test.refused($$select pending_changes from public.profiles$$, 'visitors cannot read pending profile edits');
select test.refused($$select * from public.audit_log$$, 'visitors cannot read the audit log');
select test.refused($$select * from public.staff_invites$$, 'visitors cannot read staff invites');
select test.refused($$select * from public.event_rsvps$$, 'visitors cannot read RSVPs');
select test.refused($$select * from public.game_attempts$$, 'visitors cannot read game attempts');
select test.refused($$select * from public.merch_orders$$, 'visitors cannot read merch orders');
select test.refused($$select is_correct from public.game_options$$, 'visitors cannot read the correct answers');
select test.refused('select * from public.game_option_scores', 'visitors cannot read the bird test scoring');
select test.refused($$select note from public.score_entries$$, 'visitors cannot read notes on points');
select test.refused($$select public.profile_private(id) from public.profiles$$, 'visitors cannot call profile_private');
select test.refused($$insert into public.event_rsvps (event_id, name) select id, 'x' from public.events limit 1$$,
                    'visitors cannot write RSVPs directly');

select test.ok(test.count('select id, label from public.game_options') = 1, 'visitors can read answer labels');
select test.ok(test.count('select * from public.mural_entries') = 1, 'mural shows the published profile only');
select test.ok((select mural_group from public.mural_entries where slug = 'amina') = 0, 'flock leaders come first on the mural');
select test.ok(test.count('select * from public.profile_links') = 1, 'visitors see public links only');
select test.ok(test.count($$select * from public.profile_links where kind = 'phone'$$) = 0, 'visitors do not see phone numbers');
select test.ok(test.count('select * from public.merch_products') = 0, 'draft merch is hidden');
select test.ok(test.count($$select * from public.merch_product_progress((select id from public.merch_drops limit 1))$$) = 0,
               'merch progress works for visitors and hides drafts');
select test.ok(test.count('select * from public.awards') = 2, 'flock awards are public');

reset role;

-- ---------------------------------------------------------------------------
-- A signed-in stranger with no profile
-- ---------------------------------------------------------------------------

select test.as_user('00000000-0000-0000-0000-0000000000c1');
select test.ok(test.count($$select * from public.profile_links where kind = 'phone'$$) = 0,
               'signed in without a profile is not a member: no phone numbers');
select test.refused($$insert into public.articles (slug, author_profile_id, title) values ('x', (select id from public.profiles limit 1), 'x')$$,
                    'someone without a profile cannot write articles');
reset role;

-- ---------------------------------------------------------------------------
-- Brian: a member whose profile is under review
-- ---------------------------------------------------------------------------

select test.as_user('00000000-0000-0000-0000-0000000000b1');
select test.ok(test.count($$select * from public.profile_links where kind = 'phone'$$) = 1, 'members see members-only links');
select test.ok(test.count($$select id from public.profiles where slug = 'brian'$$) = 1, 'a member sees their own unpublished profile');
update public.profiles set status = 'published' where slug = 'brian';
reset role;
select test.ok((select status from public.profiles where slug = 'brian') = 'submitted', 'a member cannot publish their own profile');

select test.as_user('00000000-0000-0000-0000-0000000000b1');
update public.profiles set full_name = 'Hacked' where slug = 'amina';
reset role;
select test.ok((select full_name from public.profiles where slug = 'amina') = 'Amina Test', 'a member cannot edit someone else''s profile');

select test.as_user('00000000-0000-0000-0000-0000000000b1');
select test.ok(test.count($$select * from public.profile_private((select id from public.profiles where slug = 'amina'))$$) = 0,
               'a member cannot read another member''s email');
reset role;

-- ---------------------------------------------------------------------------
-- Amina: a published member
-- ---------------------------------------------------------------------------

select test.as_user('00000000-0000-0000-0000-0000000000a1');
update public.profiles set full_name = 'Amina New Name', is_featured = true, slug = 'hijack' where slug = 'amina';
reset role;
select test.ok((select full_name from public.profiles where id = (select id from public.profiles where email = 'amina@example.test')) = 'Amina Test',
               'edits to a published profile wait for review');
select test.ok((select pending_changes ->> 'full_name' from public.profiles where email = 'amina@example.test') = 'Amina New Name',
               'the edit is parked in pending_changes');
select test.ok((select is_featured from public.profiles where email = 'amina@example.test') = false, 'a member cannot feature themselves');
select test.ok((select slug from public.profiles where email = 'amina@example.test') = 'amina', 'a member cannot change their slug');

select test.as_user('00000000-0000-0000-0000-0000000000a1');
select test.refused($$select public.approve_profile_changes(id) from public.profiles where slug = 'amina'$$,
                    'a member cannot approve their own changes');
select test.refused($$insert into public.articles (slug, author_profile_id, title, body, status)
                      values ('sneaky', private.current_profile_id(), 'Sneaky', 'x', 'published')$$,
                    'a member cannot publish an article');
insert into public.articles (slug, author_profile_id, title, body, status)
values ('my-first-article', private.current_profile_id(), 'My first article', 'Hello.', 'submitted');
select test.refused($$insert into public.articles (slug, author_profile_id, title) values ('as-brian', (select id from public.profiles where slug = 'brian'), 'x')$$,
                    'a member cannot write as someone else');
select test.refused($$insert into storage.objects (bucket_id, name) values ('avatars', '00000000-0000-0000-0000-0000000000b1/photo.jpg')$$,
                    'a member cannot upload into another member''s folder');
select test.refused($$insert into storage.objects (bucket_id, name) values ('covers', '00000000-0000-0000-0000-0000000000a1/cover.jpg')$$,
                    'a member cannot upload book covers');
insert into storage.objects (bucket_id, name) values ('avatars', '00000000-0000-0000-0000-0000000000a1/photo.jpg');
update public.site_settings set join_url = 'https://member.test';
select test.ok(test.count('select * from public.game_option_scores') = 0, 'members cannot read the bird test scoring');
select test.refused($$insert into public.score_entries (season_id, category_id, profile_id, points)
                      select s.id, c.id, private.current_profile_id(), 1000 from public.seasons s, public.score_categories c limit 1$$,
                    'a member cannot award themselves points');
reset role;
select test.ok(test.count($$select * from storage.objects where bucket_id = 'avatars'$$) = 1, 'a member can upload to their own folder');
select test.ok((select join_url from public.site_settings) = 'https://forms.gle/QkmrkPRywfeGpRkq7', 'a member cannot change settings');

select test.as_user('00000000-0000-0000-0000-0000000000b1');
select test.ok(test.count($$select * from public.articles where slug = 'my-first-article'$$) = 0,
               'members cannot read each other''s unpublished articles');
reset role;

-- ---------------------------------------------------------------------------
-- Staff
-- ---------------------------------------------------------------------------

select test.as_user('00000000-0000-0000-0000-00000000000e');
select test.ok(test.count('select * from public.events') = 3, 'editors see draft Socials');
select public.approve_profile_changes(id) from public.profiles where slug = 'amina';
update public.articles set status = 'published' where slug = 'my-first-article';
update public.articles set status = 'published', title = 'My first article, again' where slug = 'my-first-article';
update public.event_rsvps set attended = true, profile_id = (select id from public.profiles where slug = 'amina');
update public.site_settings set join_url = 'https://editor.test';
select test.refused($$insert into public.staff_roles (user_id, role) values ('00000000-0000-0000-0000-0000000000c1', 'admin')$$,
                    'editors cannot make staff');
select test.ok(test.count('select * from public.audit_log') = 0, 'editors cannot read the audit log');
reset role;

select test.ok((select join_url from public.site_settings) = 'https://forms.gle/QkmrkPRywfeGpRkq7', 'editors cannot change settings');
select test.ok((select full_name from public.profiles where slug = 'amina') = 'Amina New Name', 'staff approval applies the parked edit');
select test.ok((select pending_changes from public.profiles where slug = 'amina') is null, 'approval clears pending_changes');
select test.ok((select reviewed_by from public.articles where slug = 'my-first-article') = '00000000-0000-0000-0000-00000000000e',
               'publishing records the reviewer');
select test.ok((select count(*) from public.score_entries where source_ref like 'article:%') = 1,
               'publishing an article awards points once, even if saved again');
select test.ok((select count(*) from public.score_entries where source_ref like 'event:%') = 1, 'attending a Social awards points');

select test.as_user('00000000-0000-0000-0000-00000000000a');
update public.site_settings set mpesa_till = '123456';
select test.ok(test.count('select * from public.audit_log') > 0, 'admins read the audit log');
insert into public.score_entries (season_id, category_id, flock_id, points, awarded_by)
select s.id, c.id, f.id, 10, auth.uid()
  from public.seasons s, public.score_categories c, public.flocks f
 where c.slug = 'challenge-done' and f.slug = 'kiambu-road';
reset role;
select test.ok((select mpesa_till from public.site_settings) = '123456', 'admins change settings');
select test.refused($$update public.site_settings set merch_deposit_pct = 150$$, 'settings are checked: deposit over 100% is refused');
select test.refused($$insert into public.site_settings (join_url, whatsapp_rsvp, whatsapp_partners, whatsapp_merch)
                      values ('https://x.test', '254700000000', '254700000000', '254700000000')$$,
                    'there is only ever one settings row');

-- Merch structure
select test.ok((select count(*) from public.merch_variants v join public.merch_products p on p.id = v.product_id
                 where p.slug = 'know-your-bird') = 90, 'Know Your Bird has 6 birds x 3 colours x 5 sizes = 90 variants');
select test.ok((select public.merch_generate_variants(id) from public.merch_products where slug = 'shelf-care') = 0,
               'generating variants again adds none');
select test.ok((select label from public.merch_variant_cards c join public.merch_products p on p.id = c.product_id
                 where p.slug = 'book-tote' order by label limit 1) = 'cream', 'variant labels read from the options');
select test.refused($$insert into public.merch_variant_values (variant_id, product_id, option_id, option_value_id)
                      select v.id, v.product_id, o.id, ov.id
                        from public.merch_variants v
                        join public.merch_products p on p.id = v.product_id and p.slug = 'book-tote'
                        join public.merch_options o on o.product_id <> v.product_id
                        join public.merch_option_values ov on ov.option_id = o.id
                       limit 1$$,
                    'a variant cannot take a value from another product''s option');
insert into public.merch_orders (name, phone, deposit_pct) values ('Buyer', '0722222222', 50);
insert into public.merch_order_items (order_id, variant_id, qty, unit_price_kes)
select (select id from public.merch_orders limit 1), c.id, 2, c.price_kes
  from public.merch_variant_cards c join public.merch_products p on p.id = c.product_id
 where p.slug = 'book-tote' and c.label = 'cream';
select test.ok((select total_kes from public.merch_order_totals) = 2000, 'order total is worked out from the lines');
select test.ok((select deposit_kes from public.merch_order_totals) = 1000, 'deposit is worked out from the order''s percentage');

-- Bird test structure
select test.refused($$insert into public.game_attempt_answers (attempt_id, question_id, option_id)
                      select a.id, q.id, gen_random_uuid() from public.game_attempts a, public.game_questions q limit 1$$,
                    'an answer must be an option of its question');
insert into public.game_attempt_answers (attempt_id, question_id, option_id)
select a.id, o.question_id, o.id from public.game_attempts a, public.game_options o;
select test.ok((select points from public.personality_attempt_scores where personality_key = 'red') = 2,
               'bird test totals are worked out from the answers');

-- The data field
select test.ok((select data from public.events where slug = 'social-4') = '{}'::jsonb, 'data defaults to an empty object');
update public.events set data = '{"dress_code": "Smart casual"}' where slug = 'social-4';
select test.ok((select data ->> 'dress_code' from public.next_event) = 'Smart casual', 'extra details show through the views');
select test.refused($$update public.events set data = '["not", "an", "object"]' where slug = 'social-4'$$,
                    'data must be a JSON object');
select test.refused($$update public.events set data = jsonb_build_object('big', repeat('x', 40000)) where slug = 'social-4'$$,
                    'data is capped at 32 KB');
select test.as_user('00000000-0000-0000-0000-0000000000a1');
update public.profiles set data = '{"badge": "self-awarded"}' where slug = 'amina';
reset role;
select test.ok((select data from public.profiles where slug = 'amina') = '{}'::jsonb, 'members cannot change their profile''s data');
select test.as_user('00000000-0000-0000-0000-00000000000e');
update public.profiles set data = '{"badge": "founding member"}' where slug = 'amina';
reset role;
select test.ok((select data ->> 'badge' from public.mural_entries where slug = 'amina') = 'founding member',
               'staff set profile data, and the mural shows it');
select test.ok((select count(*) from public.audit_log where table_name = 'profiles' and diff ? 'data') >= 1,
               'changes to data are in the audit log');

-- Testimonials are attributed once
select test.refused($$insert into public.testimonials (quote, profile_id, author_name)
                      select 'x', id, 'Also a name' from public.profiles limit 1$$,
                    'a testimonial cannot have both a profile and a name');

select test.refused($$update public.score_entries set points = 999$$, 'points cannot be edited, even by the owner');
select test.refused($$delete from public.score_entries$$, 'points cannot be deleted, even by the owner');

select test.as_anon();
select test.ok((select points from public.flock_standings where flock_slug = 'kiambu-road') = 10, 'flock standings sum the ledger');
select test.ok((select points from public.member_standings where profile_slug = 'amina') = 10, 'member standings sum the ledger');
select test.ok(test.count($$select * from public.articles where status = 'published'$$) = 1, 'published articles are public');
reset role;

select test.ok((select count(*) from public.audit_log where table_name = 'profiles' and action = 'update') >= 2,
               'profile changes are in the audit log');
select test.ok((select count(*) from public.audit_log where table_name = 'game_attempts') = 0,
               'game attempts (visitor emails) are not copied into the audit log');

-- Server code (the secret key) can read and write everything, emails included.
set role service_role;
select test.ok(test.count('select email from public.profiles') >= 1, 'server code can read member emails');
select test.ok(test.count('select * from public.staff_invites') >= 1, 'server code can read staff invites');
insert into public.event_rsvps (event_id, name) select id, 'Server RSVP' from public.events where slug = 'social-4';
select test.ok(test.count($$select * from public.event_rsvps where name = 'Server RSVP'$$) = 1, 'server code can save RSVPs');
reset role;

\echo 'Access tests: all checks passed.'
