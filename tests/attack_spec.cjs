const assert = require('assert/strict');
const fs = require('fs');
const path = require('path');
const profiles = require('../tools/map-profiles.cjs');
const source = fs.readFileSync(path.join(__dirname, '../iw7-mod/custom_scripts/cp/beast_runner.gsc'), 'utf8');
// Execute the actual predicate bodies. This small GSC subset has JS-compatible
// expressions; only foreach needs translation. Compilation separately checks GSC.
function predicate(name) {
  const body = source.match(new RegExp('^' + name + '\\([^\\n]*\\)\\r?\\n\\{[\\s\\S]*?^\\}', 'm'));
  assert(body, 'Missing recorder function ' + name);
  return body[0].replace(/foreach \((\w+) in (\w+)\)/g, 'for (const $1 of $2)');
}
const complete = new Function('level', 'isdefined',
  'function ' + predicate('array_has_all') + '\nreturn function ' + predicate('town_state_complete'));
const defined = value => value !== undefined && value !== null;
const level = {};
const done = name => Boolean(complete(level, defined)(name));
const parts = ['head','torso','left_arm','right_arm','left_leg','right_leg'];
assert(!done('mpq_zom_parts_picked_up'));
level.mpq_zom_parts_picked_up = {};
for (let i = 0; i < parts.length; i++) {
  assert(!done('mpq_zom_parts_picked_up'), 'Incomplete collection must not split');
  level.mpq_zom_parts_picked_up[parts[i]] = 1;
}
assert(done('mpq_zom_parts_picked_up'));
level.mpq_zom_parts_picked_up.head = 0;
level.mpq_zom_parts_picked_up.extra = 1;
assert(!done('mpq_zom_parts_picked_up'), 'Array size alone is insufficient');
level.mirrors_picked_up = {car_mirror:1,bathroom_mirror:1};
assert(!done('mirrors_picked_up'));
level.mirrors_picked_up.elvira_mirror = 1;
assert(done('mirrors_picked_up'));
for (const field of ['punch_card_acquired','body_made','garage_key_found']) {
  assert(!done(field)); level[field] = 0; assert(!done(field));
  level[field] = 1; assert(done(field));
}
delete level.garage_key_found; level.key_spawned = 1;
assert(!done('garage_key_found'), 'Spawning a key must not count as collecting it');
const attack = profiles.find(p => p.id === 'cp_town');
const watched = attack.splits.filter(s => s.kind === 'town_state');
assert.equal(watched.length, 5);
assert.deepEqual(watched.map(s => s.id), [0,13,14,1,2]);
assert.equal(attack.required[0], 'deathray_step7');
assert(source.includes('!isdefined(level.br_seen[i]) && town_state_complete(level.br_events[i])'));
level.mpq_zom_parts_picked_up.head = 1;
level.br_map = 'cp_town'; level.br_state = 'running'; level.br_seen = [];
level.br_names = Array(15).fill(''); level.br_events = Array(15).fill(''); level.br_kinds = Array(15).fill('');
for (const split of attack.splits) {
  level.br_names[split.id] = split.name; level.br_events[split.id] = split.event; level.br_kinds[split.id] = split.kind;
}
let now = 1000;
const records = [];
const sampleBody = predicate('sample_town_splits').replace('foreach (i, name in level.br_names)', 'for (const [i, name] of level.br_names.entries())');
const sample = new Function('level','isdefined','town_state_complete','gettime','record_split',
  'let stamp; return function ' + sampleBody)(level, defined, complete(level, defined), () => now,
  (id, name, stamp) => records.push({id,name,stamp}));
sample();
assert.equal(records.length, 4);
level.garage_key_found = 1; now = 1050; sample();
assert.equal(records.length, 5);
assert.deepEqual(records[4], {id:2,name:'deathray_step7',stamp:1050});
now = 1100; sample(); assert.equal(records.length, 5, 'Repeated samples must not duplicate splits');
level.br_seen = []; level.br_state = 'finished'; sample(); assert.equal(records.length, 5);
level.br_state = 'running'; level.br_map = 'cp_final'; sample(); assert.equal(records.length, 5);
console.log('PASS: actual Attack predicates require six distinct parts, all three mirrors, keycard, body completion and key pickup');
console.log('PASS: actual Attack sampler records each state once, uses first-observed time and ignores finished/other-map runs');
