# IW7 Zombies Speedrun Toolkit

An in-game speedrun timer and Easter egg autosplitter for Infinite Warfare Zombies on iw7-mod, with a tenths-of-a-second display, split history, personal bests, and run statistics. Starting with The Beast from Beyond.

**Version 0.1.3 — practice prototype.** The first solo Director's Cut test confirmed the statistics menu, category detection, and early N31L splits. A subsequent screenshot confirmed that the corrected gameplay HUD appears. GSC compilation and Lua logic checks pass. The full quest, pause behavior, and boss finish still need in-game validation. This is not yet a verified leaderboard timing tool.

0.1.3 removes the duplicate power-restoration split, displays times to one decimal place, and uses `DC` in the gameplay overlay to avoid wrapping. Raw timestamps remain integer milliseconds. Displayed tenths are truncated, not rounded up. Existing run history remains readable.

### Optional F6 HUD toggle

After restarting iw7-mod to load 0.1.3, enter this in the in-game console:

```text
bind F6 "set br_hud_toggle 1"
```

F6 then shows/hides only the toolkit overlay during Beast gameplay. Recording continues while hidden. F6 was unused in the development user's saved bindings; check your own bindings before using it. The request is handled on the next game tick, so a solo pause delays it until simulation resumes. This works in the locally hosted mode supported by the toolkit.

0.1.2 fixes the missing gameplay overlay: Beast uses `ZMHUDDLC4`, so the toolkit now attaches through `HudManager.CreateHud` and also checks for an already-created active HUD. Mock checks cover both cases and HUD visibility toggling; the fix still needs confirmation in the game. Restart iw7-mod after updating. The GSC recorder is unchanged.

0.1.1 adds fixed time columns, orders N31L collection/installation before power restoration, and adds a Zombies main-menu shortcut. Main-menu statistics read the latest recorded run from disk, including after a relaunch. A native `ShutdownGame` log entry marks an unfinished attempt interrupted.

## How it works with iw7-mod

Launch your existing `iw7-mod.exe`. iw7-mod compiles the loose GSC source when a map loads and loads the Lua UI scripts. No new DLL, game executable, or client rebuild is needed. This package installs three uniquely named script files beneath the game's existing `iw7-mod` folder. It observes quest flags and notifications without replacing quest logic or changing weapons, damage, RNG, or player movement.

The first version is intended for locally hosted Zombies (solo first). Its HUD reads local dvars. Remote clients and splitscreen are not supported yet. Other gameplay mods can affect your run and are not detected by this toolkit.

## Install

1. Close Infinite Warfare / iw7-mod.
2. In PowerShell, run from this project directory:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
   ```

   Default game folder: `D:\SteamLibrary\steamapps\common\Call of Duty - Infinite Warfare`. To use another folder, pass `-GamePath 'your path'`.
3. Launch `iw7-mod.exe` as usual and start The Beast from Beyond.
4. The HUD should arm automatically and start on the first `spawned_player` event.
5. Open the pause menu and select **SPEEDRUN STATS**. The Zombies main menu and customization menu also receive a stats button. In the main menu, this opens your last recorded run and stored history, rather than a live timer. If a button does not appear, use the console: `luiOpenMenu BeastRunnerStats`.

These are globally loaded loose scripts rather than a selectable `fs_game` mod. You do not need to choose an entry in the Mods menu. Only `cp_final` activates the gameplay recorder; the statistics menu is available in Zombies.

Manual installation: copy the contents of the project's `iw7-mod` directory into the game's `iw7-mod` directory. The installer refuses to overwrite a different existing version of its scripts by default. To update, close the game and run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Update`; changed toolkit scripts are backed up under ignored `.development/install-backups` before replacement.

## Timing rules

- Start: first player `spawned_player` notification in a newly loaded Beast map.
- Finish: first `rhino_fight_over` notification with `level.dead_mammoths >= 2`. In the reference scripts this is emitted after the second final Mammoth's death, before the five-second victory delay and reward sequence. Mephistopheles is excluded.
- Clock: integer `gettime()` timestamps from the game simulation, displayed as `MM:SS.t` with one decimal place. The original millisecond values remain in the log and PB calculations. Pauses exclude time when simulation stops; this is **IGT**, not wall-clock RTA. The HUD samples the recorded clock every 50 ms. Split recording is event-driven and independent of the HUD refresh.
- In the first in-game test, both sampled timestamps and event splits landed on 50 ms increments. Trailing zeroes are expected; this build does not deliver 1 ms event resolution.
- Respawns do not restart the run. A map restart creates a new attempt. Ending or leaving a running game records an abort where the client exposes its shutdown notification. Crashes may leave an interrupted attempt; the next start marks it interrupted.
- PBs separate Standard / Director's Cut and maximum concurrent player count. Runs without the required main quest flags are recorded but excluded from complete-quest PBs. This is a consistency check, not proof that no cheats or shortcuts were used.

## Autosplits

| Split | Observed flag / event |
| --- | --- |
| N31L head collected | `neil_head_found` |
| N31L head installed | `neil_head_placed` |
| Pack-a-Punch bridge | `bridge_constructed` |
| Energy doors disabled | `security_doors_deactivated` |
| Fuse puzzle complete | `fuse_puzzle_completed` |
| Button in poster | `button_entered_poster` |
| Puzzle button pressed | `toggle_puzzle_button_pressed` |
| Toggle puzzle complete | `completed_toggle_puzzle_once` |
| N31L delivered to PaP | `neils_head_placed_in_pap` |
| Boss entry activated | `players_triggered_bossfight` |
| Opening Rhinos cleared | `rhino_stage_1` |
| Laser survival complete | `rhino_stage_4` |
| EMP defense complete | `rhino_stage_5` |
| Beast boss defeated | `rhino_fight_over` with two Mammoths dead |

Each split records its first completion. Optional splits may be missing, and different routes may complete splits in a different order. Flag-clear notifications and repeated victory notifications do not create extra splits. These event definitions come from reference dumps; verify their relationship to your speedrun category in game.

## Statistics and storage

The menu shows the current run, PB cumulative split comparisons, attempts, valid finishes, completion rate, average completed time, recent attempts, best cumulative splits, and team round / kills / headshots / downs / revives. Counts are snapshots from the game's existing data; validate them against the in-game scoreboard before relying on them. Team statistics are sampled once per second and at splits / finish.

Records append as `BR1|...` lines in iw7-mod's existing `g_log` file, normally `iw7-mod\logs\games_mp.log`. Keep `logfile` enabled. Preserve or back up that file to retain your history. The menu reads history on opening; its refresh control reloads it. Removing or rotating the game log removes the history available to the menu. GitHub excludes game logs and player data.

The menu currently labels internal actions `ALT1` (splits/history) and `ALT2` (HUD visibility); these are not Alt+1 / Alt+2 keyboard shortcuts. Keyboard prompts and clickable controls still need improvement. `ALT3` is an unsupported action in the stock menu handler and does not refresh; close and reopen the menu to reload history. HUD visibility can be set in the console: `set br_hud 0` or `set br_hud 1`. Hiding the overlay does not stop recording.

## First in-game validation

1. Start a solo Beast game; confirm a timer starts only once at spawn and the HUD appears.
2. Pause and resume; confirm game time behaves as described above.
3. Restore power and collect/install N31L; compare each split to the visible action and the `BR1` log record.
4. Down/revive and respawn; confirm the timer continues and counts match the scoreboard.
5. Complete the quest and kill both final Mammoths; confirm the timer freezes before the victory delay and does not continue into Mephistopheles.
6. Restart; confirm a new attempt, retained history, and correct PB category.
7. Repeat with Director's Cut; verify category detection and skipped/optional flags.

If it fails, inspect `iw7-mod\logs\console.log` for `beast_runner`, `BeastRunner`, script compile errors, or LUI errors. Sharing the relevant log lines is enough to begin debugging. No game launch or full run has been performed by the development checks.

## Uninstall

Close the game and run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1`. Only the three matching toolkit files are removed. History remains in the game log.

## Development and GitHub

Source files live in `iw7-mod/custom_scripts/cp/beast_runner.gsc` and `iw7-mod/ui_scripts/BeastRunner/`. `tests/` contains timing/history tests and an API-shaped UI smoke harness. Reference repositories, the GSC compiler, and validation dependencies are kept locally under ignored `.development/`; they are not part of the public project.

Validation commands, once the local tools are present:

```powershell
& .\.development\gsc-tool\gsc-tool.exe -m comp -g iw7 -s pc -y .\iw7-mod\custom_scripts\cp\beast_runner.gsc
node .\tests\run.cjs
```

The Lua syntax check targets Lua 5.1. The behavior harness uses Fengari rather than the game's HKS VM, so it does not prove in-game compatibility.

Project repository: [IW7-Zombies-Speedrun-Toolkit](https://github.com/dnieminski/IW7-Zombies-Speedrun-Toolkit). The repository includes toolkit source, this README, installers, and tests. Game files, executables, research dumps, and player data are excluded.

## References

- [iw7-mod](https://github.com/auroramod/iw7-mod): custom script loader, filesystem search paths, UI APIs and game logging.
- [Aurora GSC dump documentation](https://docs.auroramod.dev/gsc-dump).
- [IW7 GSC reference dump](https://github.com/mjkzy/iw7-gsc-dump): Beast quest flags and Mammoth victory notification.
- [IW7 UI reference dump](https://github.com/deshayu/iw7-dump): CPHUD, pause buttons and LUI timer interfaces.
- [GSC Tool](https://github.com/xensik/gsc-tool): standalone compilation validation.

Additional maps, wall-clock timing, route profiles, per-player analytics, and export / LiveSplit integration are future work.
