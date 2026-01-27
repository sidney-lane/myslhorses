// Parses bundle list and detail HTML for Amaretto bundles
// Usage: node parseBundles.js <bundleListHtml> <bundleDetailHtml>

const fs = require('fs');
const cheerio = require('cheerio');
const { insertBundles } = require('./supabaseInsert');

function parseBundleDetail(html) {
  const $ = cheerio.load(html);
  const bundle = {};
  // Main bundle info
  const bundleSection = $('#theHorse .data .dataOutput').html();
  if (bundleSection) {
    bundleSection.split('<br>').forEach((line) => {
      const clean = line.replace(/\n|\r/g, '').trim();
      if (!clean) return;
      const [key, ...rest] = clean.split(':');
      if (rest.length > 0) {
        bundle[key.trim().toLowerCase().replace(/ /g, '_')] = rest
          .join(':')
          .trim();
      } else {
        // Handle traits like 'Coat Gleam Null'
        const trait = clean.split(' ');
        if (trait.length > 1) {
          bundle[trait.slice(0, -1).join('_').toLowerCase()] =
            trait[trait.length - 1];
        }
      }
    });
  }

  // Parents
  bundle.parents = {};
  ['father', 'mother'].forEach((parent) => {
    const parentSection = $(`#parents #${parent} .dataOutput`).html();
    if (parentSection) {
      const parentObj = {};
      parentSection.split('<br>').forEach((line) => {
        const clean = line.replace(/\n|\r/g, '').trim();
        if (!clean) return;
        const [key, ...rest] = clean.split(':');
        if (rest.length > 0) {
          parentObj[key.trim().toLowerCase().replace(/ /g, '_')] = rest
            .join(':')
            .trim();
        } else {
          const trait = clean.split(' ');
          if (trait.length > 1) {
            parentObj[trait.slice(0, -1).join('_').toLowerCase()] =
              trait[trait.length - 1];
          }
        }
      });
      bundle.parents[parent] = parentObj;
    }
  });

  // Grandparents
  bundle.grandparents = {};
  [
    ['fathersFather', 'fathers_father'],
    ['fathersMother', 'fathers_mother'],
    ['mothersFather', 'mothers_father'],
    ['mothersMother', 'mothers_mother'],
  ].forEach(([id, key]) => {
    const gpSection = $(`#grandParents #${id} .dataOutput`).html();
    if (gpSection) {
      const gpObj = {};
      gpSection.split('<br>').forEach((line) => {
        const clean = line.replace(/\n|\r/g, '').trim();
        if (!clean) return;
        const [k, ...rest] = clean.split(':');
        if (rest.length > 0) {
          gpObj[k.trim().toLowerCase().replace(/ /g, '_')] = rest
            .join(':')
            .trim();
        } else {
          const trait = clean.split(' ');
          if (trait.length > 1) {
            gpObj[trait.slice(0, -1).join('_').toLowerCase()] =
              trait[trait.length - 1];
          }
        }
      });
      bundle.grandparents[key] = gpObj;
    }
  });

  return bundle;
}

// For this project, parseBundleList can be a stub or handle future list pages
function parseBundleList(html) {
  // Not implemented: use parseBundleDetail for now
  return [];
}

if (require.main === module) {
  // Accept the detail HTML file as a command-line argument, or use default
  const detailPath = process.argv[2] || '../Bundle Lineage.html';
  const detailHtml = fs.readFileSync(detailPath, 'utf8');
  const bundle = parseBundleDetail(detailHtml);

  // Extract core fields
  const uuid = bundle.uuid || '';
  const name = bundle.name || '';
  const gender = bundle.gender || '';
  const coat = bundle.coat || '';
  const tail = bundle.tail || '';
  const mane = bundle.mane || '';
  const eye = bundle.eye || '';

  // Remove core fields from bundle for data json
  const extra = { ...bundle };
  delete extra.uuid;
  delete extra.name;
  delete extra.gender;
  delete extra.coat;
  delete extra.tail;
  delete extra.mane;
  delete extra.eye;

  // Prepare CSV output with core fields and data (all extra traits as JSON)
  const csvPath = 'bundle_core_json.csv';
  const csvHeader = 'uuid,name,gender,coat,tail,mane,eye,data\n';
  const data = JSON.stringify(extra).replace(/"/g, '""'); // escape quotes for CSV
  const csvRow = `${uuid},${name},${gender},${coat},${tail},${mane},${eye},"${data}"\n`;
  fs.writeFileSync(csvPath, csvHeader + csvRow);
  console.log(`CSV written to ${csvPath}`);
}
