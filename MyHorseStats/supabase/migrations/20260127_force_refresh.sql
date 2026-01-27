-- Trivial migration to force schema cache refresh
alter table bundles add column if not exists cache_refresh text;
