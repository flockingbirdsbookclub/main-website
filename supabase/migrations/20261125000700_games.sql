-- Games: the bird test and book quizzes. Results are worked out on the
-- server, so answer weights never reach the browser. Design: docs/DATA_MODEL.md.

create table public.games (
  id          uuid primary key default gen_random_uuid(),
  slug        text not null unique check (public.is_valid_slug(slug)),
  title       text not null,
  kind        text not null check (kind in ('personality', 'quiz', 'trivia')),
  description text,
  book_id     uuid references public.books (id) on delete set null,
  config      jsonb not null default '{}'::jsonb check (jsonb_typeof(config) = 'object'),
  status      text not null default 'draft' check (status in ('draft', 'published')),
  sort_order  int not null default 0,
  archived_at timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

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
  -- Bird test: {"red":2,"yellow":0,"green":1,"blue":0}. Quiz: {"correct":true}.
  weights     jsonb not null default '{}'::jsonb check (jsonb_typeof(weights) = 'object'),
  sort_order  int not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index game_options_question_idx on public.game_options (question_id, sort_order);

create table public.game_attempts (
  id                uuid primary key default gen_random_uuid(),
  game_id           uuid not null references public.games (id) on delete cascade,
  profile_id        uuid references public.profiles (id) on delete set null,
  name              text,
  email             text not null check (email = lower(email)),
  answers           jsonb not null check (jsonb_typeof(answers) = 'array'),
  result_key        text references public.personality_types (key) on delete set null,
  scores            jsonb not null default '{}'::jsonb,
  marketing_consent boolean not null default false,
  emailed_at        timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index game_attempts_game_idx on public.game_attempts (game_id, created_at desc);
create index game_attempts_email_idx on public.game_attempts (email);

select public.track_table('public.games');
select public.track_table('public.game_questions');
select public.track_table('public.game_options');
-- Attempts hold visitors' emails; they are not copied into the audit log.
select public.track_table('public.game_attempts', false);

alter table public.games          enable row level security;
alter table public.game_questions enable row level security;
alter table public.game_options   enable row level security;
alter table public.game_attempts  enable row level security;

revoke all on public.games, public.game_questions, public.game_options, public.game_attempts
  from anon, authenticated;

grant select on public.games, public.game_questions to anon, authenticated;
-- Weights are left out of the public grant.
grant select (id, question_id, label, sort_order) on public.game_options to anon, authenticated;
grant insert, update, delete on public.games, public.game_questions, public.game_options to authenticated;
grant select on public.game_attempts to authenticated;

create policy "published games are public" on public.games
  for select to anon, authenticated using ((status = 'published' and archived_at is null) or public.is_staff());
create policy "questions of published games are public" on public.game_questions
  for select to anon, authenticated
  using (exists (select 1 from public.games g where g.id = game_id and g.status = 'published' and g.archived_at is null)
         or public.is_staff());
-- Options are visible, but the weights column is not granted to anyone
-- through the API. Staff read weights with staff_game_options() below.
create policy "options of published games are public" on public.game_options
  for select to anon, authenticated
  using (exists (select 1 from public.game_questions q join public.games g on g.id = q.game_id
                  where q.id = question_id and g.status = 'published' and g.archived_at is null)
         or public.is_staff());

create policy "staff manage games" on public.games
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff manage questions" on public.game_questions
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff manage options" on public.game_options
  for all to authenticated using (public.is_staff()) with check (public.is_staff());

create or replace function public.staff_game_options(p_game_id uuid)
returns table (id uuid, question_id uuid, label text, weights jsonb, sort_order int)
language sql
stable
security definer
set search_path = ''
as $$
  select o.id, o.question_id, o.label, o.weights, o.sort_order
    from public.game_options o
    join public.game_questions q on q.id = o.question_id
   where q.game_id = p_game_id and public.is_staff()
   order by q.sort_order, o.sort_order;
$$;
revoke execute on function public.staff_game_options(uuid) from public, anon;
grant execute on function public.staff_game_options(uuid) to authenticated;

-- Attempts are written by server code (service role). A member reads their
-- own; staff read all.
create policy "staff and the player read attempts" on public.game_attempts
  for select to authenticated using (public.is_staff() or profile_id = public.current_profile_id());
