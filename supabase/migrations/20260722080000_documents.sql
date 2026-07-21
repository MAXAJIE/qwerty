-- Unified documents store + transaction linkage
create type public.document_type as enum (
  'spa','invoice','receipt','booking_receipt','loan',
  'customer','vehicle','jpj_transfer','insurance_road_tax','payment_log'
);

create table public.documents (
  id uuid primary key default gen_random_uuid(),
  doc_type public.document_type not null,
  doc_number text,
  doc_date date,
  title text not null,
  customer_name text,
  vehicle_ref text,
  data jsonb not null default '{}'::jsonb,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index documents_type_idx on public.documents(doc_type);
create index documents_date_idx on public.documents(doc_date desc);

grant select, insert, update, delete on public.documents to authenticated;
grant all on public.documents to service_role;

alter table public.documents enable row level security;

create policy "dealer full access documents"
  on public.documents for all to authenticated
  using (public.has_role(auth.uid(), 'dealer_admin'))
  with check (public.has_role(auth.uid(), 'dealer_admin'));

create policy "agent read documents"
  on public.documents for select to authenticated
  using (public.has_role(auth.uid(), 'agent'));

create policy "agent insert own documents"
  on public.documents for insert to authenticated
  with check (public.has_role(auth.uid(), 'agent') and created_by = auth.uid());

create table public.transaction_documents (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references public.transactions(id) on delete cascade,
  document_id uuid not null references public.documents(id) on delete cascade,
  role text not null default 'attached',
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (transaction_id, document_id, role)
);
create index tx_docs_tx_idx on public.transaction_documents(transaction_id);
create index tx_docs_doc_idx on public.transaction_documents(document_id);

grant select, insert, update, delete on public.transaction_documents to authenticated;
grant all on public.transaction_documents to service_role;

alter table public.transaction_documents enable row level security;

create policy "authenticated read transaction_documents"
  on public.transaction_documents for select to authenticated
  using (true);

create policy "dealer manage transaction_documents"
  on public.transaction_documents for all to authenticated
  using (public.has_role(auth.uid(), 'dealer_admin'))
  with check (public.has_role(auth.uid(), 'dealer_admin'));

create policy "agent link transaction_documents"
  on public.transaction_documents for insert to authenticated
  with check (public.has_role(auth.uid(), 'agent') and created_by = auth.uid());

create policy "agent unlink own transaction_documents"
  on public.transaction_documents for delete to authenticated
  using (public.has_role(auth.uid(), 'agent') and created_by = auth.uid());
