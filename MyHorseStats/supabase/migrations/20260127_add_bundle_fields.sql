-- Add all relevant fields to bundles table for parsed bundle data
alter table bundles
  add column if not exists gender text,
  add column if not exists age text,
  add column if not exists current_owner text,
  add column if not exists breed text,
  add column if not exists eye text,
  add column if not exists mane text,
  add column if not exists tail text,
  add column if not exists coat_gleam text,
  add column if not exists hair_luster text,
  add column if not exists coat_gloom text,
  add column if not exists branding text,
  add column if not exists pegasus_wing text,
  add column if not exists unicorn_horn text,
  add column if not exists uuid text,
  add column if not exists version text;
