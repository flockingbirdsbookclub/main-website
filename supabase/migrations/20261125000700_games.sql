-- Games: the bird test and book quizzes. Design: docs/DATA_MODEL.md.
--
-- Normalised: how much each answer counts towards each colour is a table,
-- not a JSON blob, and each answer someone gives is a row. Results are
-- worked out on the server, so scores and correct answers never reach the
-- browser.

create table public.games (
  id                 uuid primary key default gen_random_uuid(),
  slug               text not null unique check (public.is_valid_slug(slug)),
  title              text not null,
  kind               text not null check (kind in ('personality', 'quiz', 'trivia')),
  description        text,
  book_id            uuid references public.books (id) on delete set null,
  emails_result      boolean not null default false,
  time_limit_seconds int check (time_limit_seconds > 0),
  status             text not null default 'draft' check (status in ('draft', 'published')),
  sort_order         int not null default 0,
  archived_at        timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create index games_book_idx on public.games (book_id);

create table public.game_questions (
  id         uuid primary key default gen_random_uuid(),
  game_id    uuid not null references public.games (id) on delete cascade,
  prompt     text not null,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index game_questions_game_idx on public.game_questions (game_id, sort_order);

create table public.game_options (
  id          uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.game_questions (id) on delete cascade,
  label       text not null,
  is_correct  boolean, -- quizzes only; not readable by visitors or members
  sort_order  int not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (id, question_id)
);
create index game_options_question_idx on public.game_options (question_id, sort_order);

-- Bird test: how many points an answer gives each colour.
create table public.game_option_scores (
  option_id       uuid not null references public.game_options (id) on delete cascade,
  personality_key text not null references public.personality_types (key) on update cascade,
  points          int not null check (points >= 0),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  primary key (option_id, personality_key)
);

create table public.game_attempts (
  id                uuid primary key default gen_random_uuid(),
  game_id           uuid not null references public.games (id) on delete cascade,
  profile_id        uuid references public.profiles (id) on delete set null,
  name              text,
  email             text not null check (email = lower(email)),
  result_key        text references public.personality_types (key) on update cascade, -- bird test
  score             int check (score >= 0), -- quizzes
  marketing_consent boolean not null default false,
  emailed_at        timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index game_attempts_game_idx on public.game_attempts (game_id, created_at desc);
create index game_attempts_profile_idx on public.game_attempts (profile_id);
create index game_attempts_email_idx on public.game_attempts (email);

-- One row per question answered. The composite key makes sure the option
-- belongs to the question.
create table public.game_attempt_answers (
  attempt_id  uuid not null references public.game_attempts (id) on delete cascade,
  question_id uuid not null references public.game_questions (id) on delete cascade,
  option_id   uuid not null,
  primary key (attempt_id, question_id),
  foreign key (option_id, question_id) references public.game_options (id, question_id) on delete cascade
);

select public.track_table('public.games');
select public.track_table('public.game_questions');
select public.track_table('public.game_options');
select public.track_table('public.game_option_scores');
-- Attempts hold visitors' emails; they are not copied into the audit log.
select public.track_table('public.game_attempts', false);
select public.track_table('public.game_attempt_answers', false);

-- ---------------------------------------------------------------------------
-- Access
-- ---------------------------------------------------------------------------

alter table public.games                enable row level security;
alter table public.game_questions       enable row level security;
alter table public.game_options         enable row level security;
alter table public.game_option_scores   enable row level security;
alter table public.game_attempts        enable row level security;
alter table public.game_attempt_answers enable row level security;

revoke all on public.games, public.game_questions, public.game_options, public.game_option_scores,
  public.game_attempts, public.game_attempt_answers
  from anon, authenticated;

grant select on public.games, public.game_questions to anon, authenticated;
-- is_correct is left out of the read grant.
grant select (id, question_id, label, sort_order, created_at, updated_at) on public.game_options to anon, authenticated;
grant insert, update, delete on public.games, public.game_questions, public.game_options,
  public.game_option_scores
  to authenticated;
grant select on public.game_option_scores to authenticated; -- staff only, by the rule below
grant select on public.game_attempts, public.game_attempt_answers to authenticated;

create policy "published games are public" on public.games
  for select to anon, authenticated using ((status = 'published' and archived_at is null) or public.is_staff());
create policy "questions of published games are public" on public.game_questions
  for select to anon, authenticated
  using (exists (select 1 from public.games g where g.id = game_id and g.status = 'published' and g.archived_at is null)
         or public.is_staff());
create policy "options of published games are public" on public.game_options
  for select to anon, authenticated
  using (exists (select 1 from public.game_questions q join public.games g on g.id = q.game_id
                  where q.id = question_id and g.status = 'published' and g.archived_at is null)
         or public.is_staff());
create policy "staff read scores" on public.game_option_scores
  for select to authenticated using (public.is_staff());

create policy "staff manage games" on public.games
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff manage questions" on public.game_questions
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff manage options" on public.game_options
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff manage scores" on public.game_option_scores
  for all to authenticated using (public.is_staff()) with check (public.is_staff());

-- Staff read the correct answers with this, since is_correct isn't granted.
create or replace function public.staff_game_options(p_game_id uuid)
returns table (id uuid, question_id uuid, label text, is_correct boolean, sort_order int)
language sql
stable
security definer
set search_path = ''
as $$
  select o.id, o.question_id, o.label, o.is_correct, o.sort_order
    from public.game_options o
    join public.game_questions q on q.id = o.question_id
   where q.game_id = p_game_id and public.is_staff()
   order by q.sort_order, o.sort_order;
$$;
revoke execute on function public.staff_game_options(uuid) from public, anon;
grant execute on function public.staff_game_options(uuid) to authenticated;

-- Attempts are written by server code (secret key). A member reads their
-- own; staff read all.
create policy "staff and the player read attempts" on public.game_attempts
  for select to authenticated using (public.is_staff() or profile_id = public.current_profile_id());
create policy "staff and the player read answers" on public.game_attempt_answers
  for select to authenticated
  using (exists (select 1 from public.game_attempts a where a.id = attempt_id
                  and (a.profile_id = public.current_profile_id() or public.is_staff())));

-- Bird test totals per colour for an attempt, worked out from the answers.
create view public.personality_attempt_scores with (security_invoker = on) as
  select a.id as attempt_id, s.personality_key, sum(s.points)::int as points
    from public.game_attempts a
    join public.game_attempt_answers aa on aa.attempt_id = a.id
    join public.game_option_scores s on s.option_id = aa.option_id
   group by a.id, s.personality_key;
grant select on public.personality_attempt_scores to authenticated;
