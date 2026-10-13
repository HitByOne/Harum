-- =====================================================================
-- Harim shared backend: one-time setup for a Supabase project
-- Paste this whole file into Supabase > SQL Editor > New query > Run.
-- Safe to run again (it updates what's there).
--
-- BEFORE YOU RUN IT: put your own email address on the line marked
-- >>> OWNER EMAIL <<< near the bottom. That account becomes the first
-- admin of your team space.
-- =====================================================================

-- ---------- tables ----------
-- Shared records: requests, users, roles, settings, sales requests...
-- One row per record so two people working at once don't overwrite each other.
create table if not exists public.harim_docs (
  space      text        not null,              -- 'team' (invite-only) or 'demo' (public sandbox)
  kind       text        not null,              -- requests, users, roles, ws (settings and other singles), shared, rec
  id         text        not null,
  data       jsonb       not null,
  n          bigint      generated always as identity,   -- keeps lists in the order they were made
  updated_at timestamptz not null default now(),
  updated_by text        default lower(coalesce(auth.jwt() ->> 'email', 'demo visitor')),
  primary key (space, kind, id)
);

-- Audit log: append-only
create table if not exists public.harim_audit (
  n        bigint generated always as identity primary key,
  space    text not null,
  t        timestamptz not null default now(),
  u        text,
  action   text,
  target   text,
  detail   text,
  by_email text default lower(coalesce(auth.jwt() ->> 'email', ''))
);
create index if not exists harim_audit_space_n on public.harim_audit (space, n desc);

-- Who may use the team space. Kept in step with the users you add in Harim
-- (Admin > Users & roles, with an email address); the owner row is added below.
create table if not exists public.harim_members (
  space    text    not null,
  email    text    not null,
  is_admin boolean not null default false,
  active   boolean not null default true,
  name     text,
  from_doc boolean not null default false,       -- true = maintained from Harim's user list
  primary key (space, email)
);

-- ---------- who is calling ----------
create or replace function public.harim_email() returns text
language sql stable as $$ select lower(coalesce(auth.jwt() ->> 'email', '')) $$;

-- signed in with an email address that has been confirmed (stops someone signing up with your boss's email)
create or replace function public.harim_confirmed() returns boolean
language sql stable security definer set search_path = public, auth as $$
  select exists (select 1 from auth.users u where u.id = auth.uid() and u.email_confirmed_at is not null and coalesce(u.email, '') <> '')
$$;

-- may this person read and write this space?
create or replace function public.harim_can(sp text) returns boolean
language sql stable security definer set search_path = public, auth as $$
  select case
    when sp = 'demo' then auth.uid() is not null                       -- any signed-in visitor, including "Try the demo"
    else public.harim_confirmed() and exists (
      select 1 from public.harim_members m
      where m.space = sp and m.active and m.email = public.harim_email())
  end
$$;

-- admins manage users and roles
create or replace function public.harim_is_admin(sp text) returns boolean
language sql stable security definer set search_path = public, auth as $$
  select case
    when sp = 'demo' then auth.uid() is not null
    else public.harim_confirmed() and exists (
      select 1 from public.harim_members m
      where m.space = sp and m.active and m.is_admin and m.email = public.harim_email())
  end
$$;

-- what the app asks right after sign-in
create or replace function public.harim_whoami() returns jsonb
language sql stable security definer set search_path = public, auth as $$
  select jsonb_build_object(
    'email', public.harim_email(),
    'confirmed', public.harim_confirmed(),
    'spaces', coalesce((select jsonb_agg(jsonb_build_object('space', m.space, 'admin', m.is_admin, 'name', m.name))
                        from public.harim_members m
                        where m.active and m.email = public.harim_email() and public.harim_confirmed()), '[]'::jsonb))
$$;

-- ---------- keep members in step with Harim's user list ----------
create or replace function public.harim_sync_member() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op in ('UPDATE', 'DELETE') and old.kind = 'users' and coalesce(old.data ->> 'email', '') <> '' then
    update public.harim_members set active = false
    where space = old.space and email = lower(old.data ->> 'email') and from_doc;
  end if;
  if tg_op in ('INSERT', 'UPDATE') and new.kind = 'users' and coalesce(new.data ->> 'email', '') <> '' then
    insert into public.harim_members (space, email, is_admin, active, name, from_doc)
    values (new.space, lower(new.data ->> 'email'), coalesce(new.data ->> 'role', '') = 'admin',
            coalesce((new.data ->> 'active')::boolean, true), new.data ->> 'name', true)
    on conflict (space, email) do update
      set is_admin = excluded.is_admin, active = excluded.active, name = excluded.name, from_doc = true;
  end if;
  return null;
end $$;
drop trigger if exists harim_sync_member on public.harim_docs;
create trigger harim_sync_member after insert or update or delete on public.harim_docs
  for each row execute function public.harim_sync_member();

create or replace function public.harim_touch() returns trigger
language plpgsql as $$ begin new.updated_at := now(); return new; end $$;
drop trigger if exists harim_touch on public.harim_docs;
create trigger harim_touch before update on public.harim_docs for each row execute function public.harim_touch();

-- ---------- security rules ----------
alter table public.harim_docs    enable row level security;
alter table public.harim_audit   enable row level security;
alter table public.harim_members enable row level security;

drop policy if exists harim_docs_read  on public.harim_docs;
drop policy if exists harim_docs_ins   on public.harim_docs;
drop policy if exists harim_docs_upd   on public.harim_docs;
drop policy if exists harim_docs_del   on public.harim_docs;
create policy harim_docs_read on public.harim_docs for select to authenticated using (public.harim_can(space));
create policy harim_docs_ins  on public.harim_docs for insert to authenticated
  with check (public.harim_can(space) and (kind not in ('users', 'roles') or public.harim_is_admin(space)));
create policy harim_docs_upd  on public.harim_docs for update to authenticated
  using      (public.harim_can(space) and (kind not in ('users', 'roles') or public.harim_is_admin(space)))
  with check (public.harim_can(space) and (kind not in ('users', 'roles') or public.harim_is_admin(space)));
create policy harim_docs_del  on public.harim_docs for delete to authenticated
  using (public.harim_can(space) and (kind not in ('users', 'roles') or public.harim_is_admin(space)));

drop policy if exists harim_audit_read on public.harim_audit;
drop policy if exists harim_audit_ins  on public.harim_audit;
create policy harim_audit_read on public.harim_audit for select to authenticated using (public.harim_can(space));
create policy harim_audit_ins  on public.harim_audit for insert to authenticated with check (public.harim_can(space));

drop policy if exists harim_members_self on public.harim_members;
create policy harim_members_self on public.harim_members for select to authenticated using (email = public.harim_email());
-- (no write rules on harim_members: only the trigger above and this script change it)

grant select, insert, update, delete on public.harim_docs to authenticated;
grant select, insert on public.harim_audit to authenticated;
grant select on public.harim_members to authenticated;
revoke all on public.harim_docs, public.harim_audit, public.harim_members from anon;

-- ---------- shared files (product data, submitted supplier files) ----------
-- Bucket "harim", private. Paths: <space>/data/<file> (loaded for everyone, admins upload)
--                                  <space>/files/<id>  (files people submit in Harim)
insert into storage.buckets (id, name, public) values ('harim', 'harim', false) on conflict (id) do nothing;
drop policy if exists harim_files_read  on storage.objects;
drop policy if exists harim_files_ins   on storage.objects;
drop policy if exists harim_files_upd   on storage.objects;
drop policy if exists harim_files_del   on storage.objects;
create policy harim_files_read on storage.objects for select to authenticated
  using (bucket_id = 'harim' and public.harim_can(split_part(name, '/', 1)));
create policy harim_files_ins on storage.objects for insert to authenticated
  with check (bucket_id = 'harim' and public.harim_can(split_part(name, '/', 1))
              and (split_part(name, '/', 2) <> 'data' or public.harim_is_admin(split_part(name, '/', 1))));
create policy harim_files_upd on storage.objects for update to authenticated
  using (bucket_id = 'harim' and public.harim_can(split_part(name, '/', 1))
         and (split_part(name, '/', 2) <> 'data' or public.harim_is_admin(split_part(name, '/', 1))));
create policy harim_files_del on storage.objects for delete to authenticated
  using (bucket_id = 'harim' and public.harim_can(split_part(name, '/', 1))
         and (split_part(name, '/', 2) <> 'data' or public.harim_is_admin(split_part(name, '/', 1))));

-- ---------- live updates (others' changes appear without refreshing) ----------
do $$ begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin alter publication supabase_realtime add table public.harim_docs;  exception when duplicate_object then null; end;
    begin alter publication supabase_realtime add table public.harim_audit; exception when duplicate_object then null; end;
  end if;
end $$;

-- ---------- nightly demo reset ----------
create or replace function public.harim_reset_demo() returns void
language plpgsql security definer set search_path = public, auth as $$
begin
  delete from public.harim_docs  where space = 'demo';
  delete from public.harim_audit where space = 'demo';
  begin   -- tidy up "Try the demo" visitor accounts older than two days
    delete from auth.users where is_anonymous and created_at < now() - interval '2 days';
  exception when others then null;
  end;
end $$;
revoke execute on function public.harim_reset_demo() from public, anon, authenticated;

do $$ begin
  begin create extension if not exists pg_cron; exception when others then null; end;
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule(jobid) from cron.job where jobname = 'harim-demo-reset';
    perform cron.schedule('harim-demo-reset', '0 8 * * *', 'select public.harim_reset_demo()');   -- 08:00 UTC = 3am Central
  else
    raise notice 'pg_cron is not enabled: turn it on under Database > Extensions, then run this file again for the nightly demo reset.';
  end if;
end $$;

-- ---------- the first admin of your team space ----------
-- >>> OWNER EMAIL <<<  put your email between the quotes:
insert into public.harim_members (space, email, is_admin, active, name)
values ('team', lower('YOUR-EMAIL@EXAMPLE.COM'), true, true, 'Owner')
on conflict (space, email) do update set is_admin = true, active = true;

select 'Harim backend is set up.' as result;
