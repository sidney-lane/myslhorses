# Supabase Data Object Specification

This document defines the **database schema**, **storage layout**, and **data object shapes** for a Supabase-backed Bundle Viewer/Vendor backend. It is designed to support automatic stats enrichment, search, pricing, and sync with in-world Second Life LSL scripts.

---

## 1. Scope
- **Primary entities**: Owners, Containers (boxes), Bundles (inventory objects), Stats, and Prices.
- **Storage use**: Optional raw payload storage (HTML/JSON) and image assets.
- **Sync model**: LSL pushes metadata to API → Supabase stores → enrichment jobs populate stats → API returns concise stats to LSL.

---

## 2. Core Tables (SQL)

### 2.1 `owners`
Stores the owner of the in-world box (avatar).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | uuid | PK | Internal owner record UUID. |
| `sl_avatar_id` | text | unique, not null | Second Life avatar UUID. |
| `sl_avatar_name` | text | not null | Owner name at time of ingestion. |
| `created_at` | timestamptz | default now() | Record creation time. |
| `updated_at` | timestamptz | default now() | Record update time. |

---

### 2.2 `containers`
Represents a single in-world box (linkset root). One owner can have many containers.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | uuid | PK | Internal container UUID. |
| `owner_id` | uuid | FK → owners.id | Container owner. |
| `sl_object_id` | text | not null | LSL key for the box if available. |
| `name` | text | | Box name (if set). |
| `slurl` | text | | Region/location at last update. |
| `last_seen_at` | timestamptz | | Last update from SL. |
| `created_at` | timestamptz | default now() | Record creation time. |
| `updated_at` | timestamptz | default now() | Record update time. |

---

### 2.3 `bundles`
Represents a bundle or boxed bundle stored in a container.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | uuid | PK | Internal bundle UUID. |
| `container_id` | uuid | FK → containers.id | Container that holds this bundle. |
| `bundle_uuid` | text | unique, not null | Bundle UUID (inventory key). |
| `name` | text | not null | Bundle name from inventory. |
| `description` | text | | Description from inventory. |
| `owner_name` | text | | Owner name from SL (box owner). |
| `bundle_type` | text | not null | `bundle` or `boxed_bundle`. |
| `price_l$` | integer | default 0 | Price in L$. |
| `status` | text | default 'active' | `active`, `sold`, `archived`. |
| `created_at` | timestamptz | default now() | Record creation time. |
| `updated_at` | timestamptz | default now() | Record update time. |

Indexes:
- `bundle_uuid` unique index for fast lookups.
- `container_id` index for listing bundles per box.

---

### 2.4 `bundle_stats`
Stores parsed stats and traits per bundle. This is the “clean” data used for search.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | uuid | PK | Internal stats UUID. |
| `bundle_id` | uuid | FK → bundles.id | Bundle record. |
| `raw_source` | text | | Source URL or API. |
| `raw_payload_key` | text | | Storage key for raw payload (HTML/JSON). |
| `trait_json` | jsonb | | Normalized trait data. |
| `lineage_json` | jsonb | | Parent lineage and ancestry. |
| `stats_text` | text | | Concise summary string for LSL. |
| `last_enriched_at` | timestamptz | | When stats last updated. |
| `created_at` | timestamptz | default now() | Record creation time. |
| `updated_at` | timestamptz | default now() | Record update time. |

Indexes:
- GIN index on `trait_json` for search.

---

### 2.5 `sync_events`
Tracks LSL sync events and failures for monitoring.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | uuid | PK | Internal event UUID. |
| `bundle_uuid` | text | | Bundle UUID from LSL. |
| `container_id` | uuid | | Container reference. |
| `event_type` | text | not null | `ingest`, `update`, `delete`, `error`. |
| `payload` | jsonb | | Raw inbound payload. |
| `status` | text | default 'ok' | `ok` or `failed`. |
| `error_message` | text | | Failure reason. |
| `created_at` | timestamptz | default now() | Event time. |

---

## 3. Storage Buckets (Supabase Storage)

### 3.1 Bucket: `bundle-raw`
Stores raw payloads from lineage pages or API responses.

**Key format**
```
raw/{bundle_uuid}/{timestamp}.json
raw/{bundle_uuid}/{timestamp}.html
```

### 3.2 Bucket: `bundle-images` (Optional)
Stores trait/coat images.

**Key format**
```
traits/{trait_id}/{filename}.png
bundles/{bundle_uuid}/preview.png
```

---

## 4. Data Object Shapes (JSON)

### 4.1 Ingest Payload (LSL → API)
```json
{
  "bundle_uuid": "0c9b8a1c-ad7b-c16a-0f51-41d809e5b6e5",
  "container": {
    "sl_object_id": "<box-uuid>",
    "name": "My Bundle Box",
    "slurl": "secondlife://Anarchy/143/164/4005"
  },
  "owner": {
    "sl_avatar_id": "<avatar-uuid>",
    "sl_avatar_name": "Owner Resident"
  },
  "bundle": {
    "name": "Amaretto Breedable Bundle",
    "description": "SUCCESSFUL_BUNDLE ...",
    "bundle_type": "bundle",
    "price_l$": 0
  }
}
```

### 4.2 Stats Payload (API → LSL)
```json
{
  "bundle_uuid": "0c9b8a1c-ad7b-c16a-0f51-41d809e5b6e5",
  "stats_text": "Breed: Friesian | Coat: Ebony | Eyes: Gold | Gen: 5",
  "traits": {
    "breed": "Friesian",
    "coat": "Ebony",
    "eyes": "Gold",
    "generation": 5
  }
}
```

---

## 5. Data Lifecycle
1. **Ingest**: LSL sends bundle metadata (ingest payload).
2. **Store**: API upserts owner, container, bundle.
3. **Enrich**: background job fetches lineage stats by UUID and stores `bundle_stats`.
4. **Return**: LSL requests concise `stats_text` when needed.
5. **Update**: new ingest overwrites metadata, stats preserved unless stale.

---

## 6. Recommended Constraints & Rules
- **Unique bundle UUID** across all containers.
- **Upsert** on bundle UUID to prevent duplicates.
- **Soft delete**: mark `status = archived` rather than deleting.
- **Stats freshness**: refresh if older than 7 days.
- **Payload size**: keep `stats_text` under LSL string limits (e.g., 1024 chars).

---

## 7. Supabase SQL (Starter DDL)
```sql
create table owners (
  id uuid primary key default gen_random_uuid(),
  sl_avatar_id text unique not null,
  sl_avatar_name text not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table containers (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references owners(id),
  sl_object_id text not null,
  name text,
  slurl text,
  last_seen_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table bundles (
  id uuid primary key default gen_random_uuid(),
  container_id uuid references containers(id),
  bundle_uuid text unique not null,
  name text not null,
  description text,
  owner_name text,
  bundle_type text not null,
  price_l$ integer default 0,
  status text default 'active',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table bundle_stats (
  id uuid primary key default gen_random_uuid(),
  bundle_id uuid references bundles(id),
  raw_source text,
  raw_payload_key text,
  trait_json jsonb,
  lineage_json jsonb,
  stats_text text,
  last_enriched_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table sync_events (
  id uuid primary key default gen_random_uuid(),
  bundle_uuid text,
  container_id uuid,
  event_type text not null,
  payload jsonb,
  status text default 'ok',
  error_message text,
  created_at timestamptz default now()
);

create index bundles_container_id_idx on bundles(container_id);
create index bundles_bundle_uuid_idx on bundles(bundle_uuid);
create index bundle_stats_traits_gin on bundle_stats using gin (trait_json);
```
