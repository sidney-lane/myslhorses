## Plan: Bundle Data Scraper, Storage, and Search UI (Owner-Only)

Build a system to extract all bundle data for bundles owned by you from the Amaretto Breedables horse lineage site, store all details in Supabase, and provide a single-page searchable UI for trait-based queries. Authentication can use your personal credentials.

### Steps

1. **Requirements Definition**
   - Confirm features: scrape/parse only your bundles, store all fields, provide a searchable UI.
   - List all data fields from the provided HTML (list and detail views).

2. **Scraper & Parser Design**
   - Use attached HTML to identify selectors for your bundle rows and details.
   - Design a parser (Node.js/Python) to extract all fields from both list and detail HTML.
   - For live scraping, implement basic authentication (username/password form submission, session/cookie handling).

3. **Supabase Schema & Integration**
   - Define a Supabase table with columns for every extracted field (plus raw HTML/JSON for extensibility).
   - Implement code to insert/update bundle records in Supabase.

4. **Searchable UI Design**
   - Design a single-page web app (React or similar) with:
     - A table showing all bundles and all fields.
     - Search/filter input for any trait or field.
     - Sorting by any column.
   - Connect UI to Supabase (REST or client SDK).

5. **Execution & Automation**
   - Plan for periodic re-scraping/updating of your bundle data.
   - Document setup, credentials handling, and deployment steps.

### Further Considerations

1. **Authentication**: Store credentials securely (env file, secrets manager).
2. **Data Model**: Store traits as columns or flexible JSON for future-proofing.
3. **Extensibility**: Prepare for new/unknown fields in future HTML changes.
