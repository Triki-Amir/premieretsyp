const fs = require('fs');
const path = require('path');

const base = '/mnt/c/premieretsyp/fabric-samples/test-network';
let bad = [];
function walk(dir) {
  fs.readdirSync(dir, { withFileTypes: true }).forEach(d => {
    const p = path.join(dir, d.name);
    if (d.isDirectory()) return walk(p);
    if (p.endsWith('.json')) {
      try {
        const s = fs.readFileSync(p, 'utf8');
        if (!s || s.trim().length === 0) throw new Error('empty file');
        JSON.parse(s);
        console.log('OK:', p);
      } catch (e) {
        bad.push({ file: p, err: e.message });
      }
    }
  });
}

try {
  walk(base);
} catch (e) {
  console.error('Walker error:', e.message);
  process.exit(2);
}

if (bad.length) {
  console.error('\nInvalid JSON files:');
  bad.forEach(b => console.error(`${b.file} -> ${b.err}`));
  process.exit(1);
} else {
  console.log('\nAll JSON files valid.');
}
