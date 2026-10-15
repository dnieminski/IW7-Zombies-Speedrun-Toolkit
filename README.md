# IW7 Zombies Speedrun Toolkit

An in-game timer, Easter egg autosplitter, and statistics menu for all five Infinite Warfare Zombies maps on [iw7-mod](https://github.com/auroramod/iw7-mod).

**Version 0.3.2 — practice build.** Supports all five maps with 64 split points, automatic map selection, separate map history/PBs, and editable split names and visibility. Includes the menu overlap fixes and matches the Barracks shortcut to the neighboring buttons' native width and text/focus styling.

The recorder compiles and the Lua history/UI checks pass. Early Beast splits and the gameplay overlay have been tested by the user. The four new routes, full boss finishes, and pause behavior still need in-game validation. This is not yet a verified leaderboard timing tool.

## Install and launch

1. Close Infinite Warfare / iw7-mod.
2. From this project directory, run:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Update
   ```

   Default game folder: `D:\SteamLibrary\steamapps\common\Call of Duty - Infinite Warfare`. Use `-GamePath 'your path'` for another location. Changed toolkit scripts are backed up under `.development/install-backups` before replacement.
3. Launch `iw7-mod.exe` normally and start any supported Zombies map. The timer starts at the first player spawn.
4. Open **SPEEDRUN STATS** from the pause menu, Zombies main menu, or customization menu. Console fallback: `luiOpenMenu BeastRunnerStats`.

These are loose scripts loaded by iw7-mod; no executable rebuild or Mods-menu selection is needed. Four files are installed: the GSC recorder and `__init__.lua`, `core.lua`, and **`maps.lua`** under `ui_scripts/BeastRunner`. For manual installation, copy the entire packaged `iw7-mod` directory into the game's existing `iw7-mod` directory.

Use locally hosted Zombies, solo first. The overlay reads local dvars; remote clients and splitscreen are not supported. These scripts observe quest events without replacing quest logic or changing weapons, damage, RNG, or movement. Other mods can affect runs and are not detected.

## Timing and endpoints

Every map starts at the first `spawned_player` notification. Respawning does not restart the clock; restarting/reloading the map creates a new attempt.

| Map | Finish event | Meaning |
| --- | --- | --- |
| Zombies in Spaceland | `ufo_destroyed` | UFO destruction after the Alien fight; includes the native scripted destruction delay |
| Rave in the Redwoods | `super_slasher_death` | Super Slasher death |
| Shaolin Shuffle | `rat_king_killed`, final stage only | Final Rat King death; ignores earlier Rat Kings |
| Attack of the Radioactive Thing | `boss_fight_finished` | Successful final bomb sequence, before the death/reward sequence |
| The Beast from Beyond | `rhino_fight_over`, two Mammoths dead | Beast boss defeat; excludes Mephistopheles |

These endpoints follow native script events. Compare them with your speedrun category's rules during testing, especially Spaceland's destruction delay.

The clock uses integer `gettime()` timestamps from the game simulation: **IGT**, excluding time while simulation stops. The HUD samples every 50 ms; splits record on their events independently of HUD refresh. Observed timestamps land on 50 ms increments, so this build does not provide 1 ms timing resolution. Times display as `MM:SS.t`, truncated to tenths; logs and calculations retain raw integer milliseconds.

Each split records its first completion. Optional splits may be missing and routes can complete steps in different orders. Full-run PB eligibility requires selected main quest events to have been observed; direct boss mode is excluded. This is a consistency check, not cheat detection. See [event definitions](docs/map-events.md) for profiles and qualifications.

## Overlay and menu controls

The overlay stays in the upper-left corner with equal horizontal/vertical margins. `RUNNING / GAME TIME` means the attempt is recording on the simulation clock. `DC` means Director's Cut.

The statistics menu has clickable controls for previous/next map, splits/history, HUD visibility, refreshing history, and **EDIT SPLITS**. In the main menu, browse saved data for each map; gameplay selects the current map automatically. Controller shoulder buttons also change maps in the main menu. Internal `ALT1` / `ALT2` actions remain supported; they are not literal Alt+1 / Alt+2 keyboard combinations.

### Custom split names and visibility

Open **SPEEDRUN STATS > EDIT SPLITS** for the selected map:

- Click `[X]` / `[ ]` beside a split to show/hide it in the gameplay overlay and split comparisons.
- Select **RENAME** and enter a name up to 28 characters. Cancelling keeps the old name; an empty name restores the default. Control characters and caret formatting are removed.
- Select **DEFAULT** to restore that split's name while keeping its on/off state.
- Select **RESTORE MAP DEFAULTS** to restore all names and enable all splits for that map.
- Browse other maps from the main menu using the map buttons; during gameplay, settings stay on the current map.

Names and visibility are presentation preferences. The timer, original event recording, full-run PB requirements, and saved run IDs continue unchanged, including when a split is hidden. Renamed labels also appear on old runs; no history is rewritten.

Preferences use saved `br_pref_<map>_<slot>` game settings via the console's `seta` command, separate from the run log. Back up your game profile/configuration as well as the log to preserve customization. The Lua UI's file API is read-only, so this does not create a separate settings file. Updates and uninstall leave saved preferences intact. Keyboard interaction and persistence across a full game exit still need in-game confirmation; automated checks cover the preference format and a fresh UI load.

Optional gameplay HUD keybind, entered in the game console:

```text
bind F6 "set br_hud_toggle 1"
```

Check your existing F6 binding first. This shows/hides only the toolkit overlay; recording continues. It runs on the next simulation tick, so a solo pause delays it until simulation resumes. You can also use `set br_hud 0` or `set br_hud 1`.

## Statistics and saved data

PBs, cumulative comparisons, attempts, valid finishes, average completed time, completion rate, and history are separated by **map**, Standard/Director's Cut, and maximum concurrent player count. PB cumulative means time from the start to that split in your fastest valid completed run. Best cumulative splits also use valid completed runs; partial attempts remain visible in history without replacing full-run PBs.

Team round, kills, headshots, downs, and revives come from existing game data, sampled once per second and at splits/finish. Check these against the scoreboard during validation.

Records append as `BR2|map|...` lines to iw7-mod's existing `g_log`, normally `iw7-mod\logs\games_mp.log`. Keep logging enabled and back up this file to preserve history. Existing `BR1` records still read as Beast attempts. No migration or log deletion is necessary. Leaving a running game may record an abort/shutdown; crashes can leave an interrupted attempt. Refreshing or reopening the menu reloads disk history.

Game logs, player data, reference dumps, and executables are excluded from the repository.

## In-game validation

For each new map, first test solo Standard, then Director's Cut:

1. Confirm the correct map title, one timer start at spawn, and sensible pause/resume behavior.
2. Compare every split to its visible quest action. Test failed/retried defenses and rituals for duplicate or premature splits.
3. Down, revive, and respawn; check the timer and scoreboard statistics.
4. Complete the main quest and confirm the documented finish, including retries of Attack's final bomb sequence and Shaolin's earlier Rat Kings.
5. Return to the main menu, browse maps, and confirm saved data stays with the correct map/category after relaunching.

If a split is wrong, note map, Standard/DC, player count, visible action, split label, and whether it fired early, late, or never. Relevant `BR2` lines from the game log and script/LUI errors from `iw7-mod\logs\console.log` help diagnose it.

## Uninstall

Close the game and run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1`. Only the four matching toolkit files are removed. History stays in the game log.

## Development

Source is under `iw7-mod/custom_scripts/cp/` and `iw7-mod/ui_scripts/BeastRunner/`. Legacy `BeastRunner` file/menu names remain for update compatibility.

`tools/map-profiles.cjs` is the authoritative profile definition. Regenerate the GSC configuration and Lua table after changing it:

```powershell
npm ci
npm run generate
npm test
```

Tests cover profile integrity, Lua syntax, timing/history logic, legacy history, per-map/category PB isolation, and a mocked UI on all five maps. If local reference dumps are present, the audit also checks event names exist. These checks cannot establish in-game event timing or HKS VM compatibility.

With a local [GSC Tool](https://github.com/xensik/gsc-tool), compile-check the recorder:

```powershell
& .\.development\gsc-tool\gsc-tool.exe -m comp -g iw7 -s pc -y .\iw7-mod\custom_scripts\cp\beast_runner.gsc
```

Research tools and dumps stay in ignored `.development/`. See [event research notes](docs/map-events.md) for provenance and finish guards.

Project: [IW7-Zombies-Speedrun-Toolkit](https://github.com/dnieminski/IW7-Zombies-Speedrun-Toolkit).
