const assert = require('assert/strict');
const fs = require('fs');
const path = require('path');
const profiles = require('../tools/map-profiles.cjs');
const root = path.resolve(__dirname, '..');
assert.deepEqual(profiles.map(p => p.id), ['cp_zmb','cp_rave','cp_disco','cp_town','cp_final']);
for (const p of profiles) {
  assert(p.splits.length <= 15);
  assert.equal(new Set(p.splits.map(s => s.id)).size, p.splits.length);
  assert.equal(new Set(p.splits.map(s => s.name)).size, p.splits.length);
  const finish = p.splits.find(s => s.kind === 'finish');
  assert.equal(finish.id, p.finish.id);
  assert.equal(finish.name, 'boss_defeated');
  for (const s of p.splits) assert(['flag','event','ufo_stage','jmem_stage','finish'].includes(s.kind));
}
assert.equal(profiles.find(p => p.id === 'cp_disco').finish.guard, 'ratking_final');
assert.equal(profiles.find(p => p.id === 'cp_final').finish.guard, 'mammoths');
const referenceRoot = path.join(root, '.development/iw7-gsc-dump/decompiled/scripts');
if (fs.existsSync(referenceRoot)) {
  const readTree = dir => fs.readdirSync(dir, {withFileTypes:true}).flatMap(e => e.isDirectory() ? readTree(path.join(dir,e.name)) : e.name.endsWith('.gsc') ? [fs.readFileSync(path.join(dir,e.name),'utf8')] : []);
  const source = readTree(referenceRoot).join('\n');
  let checked = 0;
  for (const p of profiles) {
    for (const s of p.splits) {
      if (s.kind === 'finish') continue;
      assert(source.includes('"' + s.event + '"'), 'Missing reference event: ' + p.id + ':' + s.event);
      checked++;
    }
    assert(source.includes('"' + p.finish.event + '"'), 'Missing victory reference: ' + p.id);
  }
  console.log('PASS: ' + checked + ' split event names and all 5 victory events exist in the local reference scripts');
}
console.log('PASS: profile identities, unique IDs, finish slots, and final-boss guards');
