create table if not exists public.financial_reports (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  period_start date not null,
  period_end date not null,
  currency text not null default 'RM',
  revenue numeric(14,2) not null default 0,
  cogs numeric(14,2) not null default 0,
  rent numeric(14,2) not null default 0,
  salaries numeric(14,2) not null default 0,
  marketing numeric(14,2) not null default 0,
  utilities numeric(14,2) not null default 0,
  other_opex numeric(14,2) not null default 0,
  other_income numeric(14,2) not null default 0,
  other_expenses numeric(14,2) not null default 0,
  cash_balance numeric(14,2) not null default 0,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
grant select, insert, update, delete on public.financial_reports to authenticated;
grant all on public.financial_reports to service_role;
alter table public.financial_reports enable row level security;
create policy "dealer read reports" on public.financial_reports
  for select to authenticated using (public.has_role(auth.uid(), 'dealer_admin'));
create policy "dealer insert reports" on public.financial_reports
  for insert to authenticated with check (public.has_role(auth.uid(), 'dealer_admin'));
create policy "dealer update reports" on public.financial_reports
  for update to authenticated
  using (public.has_role(auth.uid(), 'dealer_admin'))
  with check (public.has_role(auth.uid(), 'dealer_admin'));
create policy "dealer delete reports" on public.financial_reports
  for delete to authenticated using (public.has_role(auth.uid(), 'dealer_admin'));
create index if not exists financial_reports_period_idx on public.financial_reports (period_end desc);
