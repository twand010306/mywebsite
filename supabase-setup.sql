-- Run this script in the Supabase project's SQL Editor to set up or update access and personal-data sync.
-- The administrator is authenticated by Supabase; never put a service-role key in the website.
-- Enable Google under Authentication > Providers and add its OAuth client ID and secret.
-- In Google Cloud, set this as an authorized redirect URI:
-- https://ugpdnfyscmvnfbljebus.supabase.co/auth/v1/callback
-- Add the deployed website URL to Supabase's Authentication > URL Configuration redirect allow-list.
-- The website's allowed_emails list controls dashboard access after Google sign-in.
-- Add local development URLs there too if you test with a local web server.

create table if not exists public.allowed_emails (
    email text primary key check (email = lower(btrim(email))),
    added_at timestamptz not null default now(),
    added_by uuid references auth.users(id) on delete set null
);

alter table public.allowed_emails enable row level security;

revoke all on public.allowed_emails from anon, public;
grant select, insert, delete on public.allowed_emails to authenticated;

drop policy if exists "Users and admin can read allowed emails" on public.allowed_emails;
create policy "Users and admin can read allowed emails"
    on public.allowed_emails
    for select
    to authenticated
    using (
        email = lower((select auth.jwt() ->> 'email'))
        or (select auth.jwt() ->> 'email') = 'twan.dieker@gmail.com'
    );

drop policy if exists "Admin can add allowed emails" on public.allowed_emails;
create policy "Admin can add allowed emails"
    on public.allowed_emails
    for insert
    to authenticated
    with check (
        (select auth.jwt() ->> 'email') = 'twan.dieker@gmail.com'
        and added_by = (select auth.uid())
    );

drop policy if exists "Admin can remove allowed emails" on public.allowed_emails;
create policy "Admin can remove allowed emails"
    on public.allowed_emails
    for delete
    to authenticated
    using ((select auth.jwt() ->> 'email') = 'twan.dieker@gmail.com');

insert into public.allowed_emails (email)
values
    ('twan.dieker@gmail.com'),
    ('twan@email.nl'),
    ('admin@enterprise.nl'),
    ('gebruiker@email.nl')
on conflict (email) do nothing;

create table if not exists public.dashboard_data (
    user_id uuid primary key references auth.users(id) on delete cascade,
    data jsonb not null default '{}'::jsonb check (jsonb_typeof(data) = 'object'),
    updated_at timestamptz not null default now()
);

alter table public.dashboard_data enable row level security;

revoke all on public.dashboard_data from anon, public;
grant select, insert, update on public.dashboard_data to authenticated;

drop policy if exists "Users can read their own dashboard data" on public.dashboard_data;
create policy "Users can read their own dashboard data"
    on public.dashboard_data
    for select
    to authenticated
    using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert their own dashboard data" on public.dashboard_data;
create policy "Users can insert their own dashboard data"
    on public.dashboard_data
    for insert
    to authenticated
    with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own dashboard data" on public.dashboard_data;
create policy "Users can update their own dashboard data"
    on public.dashboard_data
    for update
    to authenticated
    using ((select auth.uid()) = user_id)
    with check ((select auth.uid()) = user_id);

create table if not exists public.family_events (
    id uuid primary key default gen_random_uuid(),
    title text not null check (length(btrim(title)) between 1 and 100),
    event_date date not null,
    details text check (details is null or length(details) <= 240),
    created_by uuid not null references auth.users(id) on delete cascade,
    created_at timestamptz not null default now()
);

create index if not exists family_events_event_date_idx
    on public.family_events (event_date);

alter table public.family_events enable row level security;

revoke all on public.family_events from anon, public;
grant select, insert, update, delete on public.family_events to authenticated;

drop policy if exists "Allowed users can read family events" on public.family_events;
create policy "Allowed users can read family events"
    on public.family_events
    for select
    to authenticated
    using (
        exists (
            select 1
            from public.allowed_emails
            where email = lower((select auth.jwt() ->> 'email'))
        )
    );

drop policy if exists "Allowed users can add family events" on public.family_events;
create policy "Allowed users can add family events"
    on public.family_events
    for insert
    to authenticated
    with check (
        created_by = (select auth.uid())
        and exists (
            select 1
            from public.allowed_emails
            where email = lower((select auth.jwt() ->> 'email'))
        )
    );

drop policy if exists "Allowed users can update family events" on public.family_events;
create policy "Allowed users can update family events"
    on public.family_events
    for update
    to authenticated
    using (
        exists (
            select 1
            from public.allowed_emails
            where email = lower((select auth.jwt() ->> 'email'))
        )
    )
    with check (
        exists (
            select 1
            from public.allowed_emails
            where email = lower((select auth.jwt() ->> 'email'))
        )
    );

drop policy if exists "Allowed users can delete family events" on public.family_events;
create policy "Allowed users can delete family events"
    on public.family_events
    for delete
    to authenticated
    using (
        exists (
            select 1
            from public.allowed_emails
            where email = lower((select auth.jwt() ->> 'email'))
        )
    );
