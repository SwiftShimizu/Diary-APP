## Supabase setup (minimal 2-person shared diary)

Run this in Supabase **SQL Editor**.

```sql
-- diaries (a shared space)
create table if not exists diaries (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now()
);

-- diary_members (who can access the diary)
create table if not exists diary_members (
  diary_id uuid not null references diaries(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (diary_id, user_id)
);

-- entries
create table if not exists entries (
  id uuid primary key,
  diary_id uuid not null references diaries(id) on delete cascade,
  author_id uuid not null references auth.users(id),
  author_name text not null,
  author_color_hex text not null,
  diary_date date not null,
  title text not null,
  body text not null default '',
  is_deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_entries_updated_at on entries;
create trigger trg_entries_updated_at
before update on entries
for each row execute function set_updated_at();

-- RLS
alter table diaries enable row level security;
alter table diary_members enable row level security;
alter table entries enable row level security;

create or replace function is_diary_member(d uuid)
returns boolean as $$
  select exists (
    select 1 from diary_members m
    where m.diary_id = d and m.user_id = auth.uid()
  );
$$ language sql stable;

create policy "diaries select if member"
on diaries for select
using (is_diary_member(id));

create policy "members select self"
on diary_members for select
using (user_id = auth.uid());

create policy "entries select if member"
on entries for select
using (is_diary_member(diary_id));

create policy "entries upsert if member"
on entries for insert
with check (is_diary_member(diary_id) and author_id = auth.uid());

create policy "entries update if member"
on entries for update
using (is_diary_member(diary_id))
with check (is_diary_member(diary_id));

create policy "entries delete disabled"
on entries for delete
using (false);
```

### One-time bootstrap

1. Sign up / sign in as both users once (so they exist in `auth.users`)
2. Create a diary:
```sql
insert into diaries default values returning id;
```
3. Add both users to `diary_members` (replace placeholders):
```sql
insert into diary_members (diary_id, user_id) values
  ('<DIARY_ID>', '<YOUR_USER_ID>'),
  ('<DIARY_ID>', '<PARTNER_USER_ID>');
```

The iOS app fetches `diary_id` automatically via `diary_members`.

