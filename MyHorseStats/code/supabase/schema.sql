-- Supabase table for bundles (add/adjust fields as needed)
create table bundles (
  id serial primary key,
  name text,
  -- Add all relevant fields here
  raw_list_html text,
  raw_detail_html text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
