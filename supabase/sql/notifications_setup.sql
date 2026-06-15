-- Device token storage
create table if not exists public.user_device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_token text not null unique,
  platform text not null default 'ios',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_user_device_tokens_user_id
  on public.user_device_tokens(user_id);

-- Notification send logs
create table if not exists public.notification_send_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  device_token text not null,
  campaign_key text not null,
  title text not null,
  body text not null,
  status text not null default 'queued', -- queued | sent | failed
  apns_id text,
  error_reason text,
  created_at timestamptz not null default now()
);

create index if not exists idx_notification_send_logs_campaign
  on public.notification_send_logs(campaign_key, created_at desc);

-- RLS
alter table public.user_device_tokens enable row level security;
alter table public.notification_send_logs enable row level security;

-- Device token policies (client can only access own rows)
drop policy if exists "select own device tokens" on public.user_device_tokens;
create policy "select own device tokens"
on public.user_device_tokens
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "insert own device tokens" on public.user_device_tokens;
create policy "insert own device tokens"
on public.user_device_tokens
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "update own device tokens" on public.user_device_tokens;
create policy "update own device tokens"
on public.user_device_tokens
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Logs should be server-only (Edge Function uses service role and bypasses RLS)
-- Optional read policy for debugging from authenticated users:
drop policy if exists "read own notification logs" on public.notification_send_logs;
create policy "read own notification logs"
on public.notification_send_logs
for select
to authenticated
using (auth.uid() = user_id);

-- Keep updated_at fresh
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_user_device_tokens_updated_at on public.user_device_tokens;
create trigger trg_user_device_tokens_updated_at
before update on public.user_device_tokens
for each row execute function public.set_updated_at();

-- Audience selection helper view (active token + marketing push preference)
create or replace view public.v_notification_audience_marketing as
select
  udt.user_id,
  udt.device_token
from public.user_device_tokens udt
join public.user_notification_preferences unp on unp.user_id = udt.user_id
where
  udt.is_active = true
  and unp.push_marketing = true;
