-- Drop and recreate bundles table with all required fields
DROP TABLE IF EXISTS bundles;
CREATE TABLE bundles (
  id serial primary key,
  name text,
  gender text,
  age text,
  current_owner text,
  breed text,
  eye text,
  mane text,
  tail text,
  coat_gleam text,
  hair_luster text,
  coat_gloom text,
  branding text,
  pegasus_wing text,
  unicorn_horn text,
  uuid text,
  version text,
  raw_list_html text,
  raw_detail_html text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
