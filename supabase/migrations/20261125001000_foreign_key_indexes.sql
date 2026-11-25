-- An index for every foreign key, so joins and deletes stay fast as tables grow.
-- Supabase's performance advisor flags any foreign key without one.
-- New foreign keys get their index in the migration that adds them.

create index if not exists albums_cover_media_id_fk_idx on public.albums (cover_media_id);
create index if not exists articles_book_id_fk_idx on public.articles (book_id);
create index if not exists articles_cover_media_id_fk_idx on public.articles (cover_media_id);
create index if not exists articles_reviewed_by_fk_idx on public.articles (reviewed_by);
create index if not exists awards_flock_id_fk_idx on public.awards (flock_id);
create index if not exists awards_media_id_fk_idx on public.awards (media_id);
create index if not exists awards_profile_id_fk_idx on public.awards (profile_id);
create index if not exists awards_season_id_fk_idx on public.awards (season_id);
create index if not exists books_cover_media_id_fk_idx on public.books (cover_media_id);
create index if not exists events_kind_fk_idx on public.events (kind);
create index if not exists events_poster_media_id_fk_idx on public.events (poster_media_id);
create index if not exists flocks_photo_media_id_fk_idx on public.flocks (photo_media_id);
create index if not exists game_attempt_answers_option_id_question_id_fk_idx on public.game_attempt_answers (option_id, question_id);
create index if not exists game_attempt_answers_question_id_fk_idx on public.game_attempt_answers (question_id);
create index if not exists game_attempts_result_key_fk_idx on public.game_attempts (result_key);
create index if not exists game_option_scores_personality_key_fk_idx on public.game_option_scores (personality_key);
create index if not exists media_uploaded_by_fk_idx on public.media (uploaded_by);
create index if not exists merch_drops_collect_event_id_fk_idx on public.merch_drops (collect_event_id);
create index if not exists merch_option_values_colour_key_fk_idx on public.merch_option_values (colour_key);
create index if not exists merch_orders_flock_id_fk_idx on public.merch_orders (flock_id);
create index if not exists merch_variant_values_option_id_product_id_fk_idx on public.merch_variant_values (option_id, product_id);
create index if not exists merch_variant_values_option_value_id_option_id_fk_idx on public.merch_variant_values (option_value_id, option_id);
create index if not exists merch_variant_values_variant_id_product_id_fk_idx on public.merch_variant_values (variant_id, product_id);
create index if not exists partners_image_media_id_fk_idx on public.partners (image_media_id);
create index if not exists personality_types_image_media_id_fk_idx on public.personality_types (image_media_id);
create index if not exists photo_tags_tagged_by_fk_idx on public.photo_tags (tagged_by);
create index if not exists profile_links_kind_fk_idx on public.profile_links (kind);
create index if not exists profiles_personality_key_fk_idx on public.profiles (personality_key);
create index if not exists profiles_photo_media_id_fk_idx on public.profiles (photo_media_id);
create index if not exists score_entries_awarded_by_fk_idx on public.score_entries (awarded_by);
create index if not exists seasons_reading_cycle_id_fk_idx on public.seasons (reading_cycle_id);
create index if not exists speakers_photo_media_id_fk_idx on public.speakers (photo_media_id);
create index if not exists testimonials_author_flock_id_fk_idx on public.testimonials (author_flock_id);
create index if not exists venues_partner_id_fk_idx on public.venues (partner_id);
