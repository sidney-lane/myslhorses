-- Drop and recreate bundles table with core columns and flexible JSONB for extra traits
DROP TABLE IF EXISTS bundles;
CREATE TABLE bundles (
  id serial PRIMARY KEY,
  uuid text,
  name text,
  gender text,
  coat text,
  tail text,
  mane text,
  eye text,
  data jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
