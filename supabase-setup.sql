-- Run this script once in the Supabase project's SQL Editor.
-- The administrator is authenticated by Supabase; never put a service-role key in the website.
-- Enable the Email provider (password sign-in) under Authentication > Providers.
-- The website's allowed_emails list grants dashboard access but does not create Auth users.
-- Create each user's Auth account and password under Authentication > Users.
-- Add the deployed website URL under Authentication > URL Configuration.
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
