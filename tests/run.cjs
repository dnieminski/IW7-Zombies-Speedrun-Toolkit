const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const luaRoot = path.join(root, 'iw7-mod/ui_scripts/BeastRunner');
const dependencies = path.join(root, '.development/validation/node_modules');
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = require(path.join(dependencies, 'fengari'));
const luaparse = require(path.join(dependencies, 'luaparse'));
for (const name of ['core.lua', '__init__.lua']) {
  luaparse.parse(fs.readFileSync(path.join(luaRoot, name), 'utf8'), {luaVersion: '5.1'});
  console.log('PASS: Lua 5.1 syntax ' + name);
}
for (const name of ['core_spec.lua', 'ui_spec.lua']) {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  const bootstrap = `package.path = ${JSON.stringify(luaRoot.replaceAll('\\', '/') + '/?.lua;')} .. package.path\n`;
  const source = bootstrap + fs.readFileSync(path.join(__dirname, name), 'utf8');
  const status = lauxlib.luaL_dostring(L, to_luastring(source));
  if (status !== lua.LUA_OK) throw Error(to_jsstring(lua.lua_tostring(L, -1)));
}
