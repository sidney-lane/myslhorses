// Inserts parsed bundles into Supabase
require('dotenv').config({ path: '../.env' });
const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY =
  process.env.SUPABASE_KEY || process.env.SUPABASE_SECRET_KEY;
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function insertBundles(bundles) {
  for (const bundle of bundles) {
    // Upsert by unique field if available (e.g., uuid)
    const { data, error } = await supabase
      .from('bundles')
      .upsert(bundle, { onConflict: ['uuid'] }); // Change 'uuid' to your unique field if needed
    if (error) {
      console.error('Error inserting bundle:', error);
    } else {
      console.log('Inserted bundle:', data);
    }
  }
}

module.exports = { insertBundles };
