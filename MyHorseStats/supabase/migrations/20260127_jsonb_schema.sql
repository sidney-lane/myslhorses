-- Drop and recreate bundles table with flexible JSONB data column
DROP TABLE IF EXISTS bundles;
CREATE TABLE bundles (
  id serial PRIMARY KEY,
  uuid text,
  name text,
  data jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
