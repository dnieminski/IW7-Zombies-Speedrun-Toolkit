# Map event research — 0.3.3

These definitions were traced through native quest scripts, not inferred from HUD text. They remain provisional until tested in the game. Source-name checks only establish that an event exists, not that it fires at the intended visible action.

## Reference provenance

Locally inspected [IW7 GSC dump](https://github.com/mjkzy/iw7-gsc-dump) at commit 1dd48a7, [IW7 UI dump](https://github.com/deshayu/iw7-dump) at 2305708, and [iw7-mod](https://github.com/auroramod/iw7-mod) at 37abcb2. Reference dumps are excluded from this repository. Paths below are relative to the GSC dump's decompiled/scripts directory.

## Event qualifications

- Spaceland: cp/maps/cp_zmb/cp_zmb_dj.gsc defines the ufo quest, SETI-COM defenses, tone generators, and Alien progression. speaker_defense_completed is emitted once per player. The observer counts unique completions, suppressing notifications within one second of the previous completion; the three actual defenses are much farther apart. This avoids relying on a quest index which may advance before the observer resumes. cp_zmb_ufo.gsc sets ufo_destroyed after approximately three seconds of scripted UFO movement/destruction following the final shot. The timer stops at that flag, not at final shot damage.
- Rave: cp/maps/cp_rave/cp_rave_j_mem_quest.gsc uses jmem quest indices 1, 4, and 7 for the three dismemberment rituals. The shared defense notification is accepted only at the corresponding index. photo_1_kev_given and photo_2_kev_given are set on repaired-photo pickup after the Slasher, despite their internal names. cp_rave_boat.gsc provides Pack-a-Punch and island flags. cp_rave_super_slasher_fight.gsc waits for super_slasher_death, emitted from mp/agents/superslasher/superslasher_agent.gsc; this precedes later victory/loot delays.
- Shaolin: cp/maps/cp_disco/disco_mpq.gsc sets the locker, phone, poster, relic, and boss-entry flags. skq_p2t1_2 follows locker-key pickup, skq_p2t1_3 follows opening the locker, and correct_poster_got follows correct poster pickup. cp/maps/cp_disco/ratking_damage.gsc emits rat_king_killed. rat_king_fight.gsc uses zero-based rat_king_stage 6 for the final stage, so the observer requires at least 6. Earlier Rat King deaths do not finish a run. The later rk_fight_completed notification follows a long outro and is intentionally not used.
- Attack: the first Director's Cut test recorded later chemistry/bomb flags but missed garage milestones. cp/maps/cp_town/cp_town_mpq.gsc's real pickup interactions set level.mpq_zom_parts_picked_up, level.mirrors_picked_up, level.punch_card_acquired, level.body_made, and level.garage_key_found, rather than the deathray_step1/4/7 flags previously observed. The recorder now samples these five persistent states every 50 ms, recording each once at first observation. Six distinct body keys (head, torso, left_arm, right_arm, left_leg, right_leg) and all three mirror keys (car_mirror, bathroom_mirror, elvira_mirror) are required for their collection splits; cp_town_elvira.gsc supplies the Elvira mirror pickup. Body assembly means successful life-ray activation, not merely placing six parts. The key split requires actual pickup, not key_spawned. Stable deathray split IDs/slots remain for compatibility; new mirrors/keycard splits use previously unused slots 13/14. Chemistry/bomb events remain native flags. cp_town_crab_boss_bomb.gsc sets boss_fight_finished only on successful final detonation, before death/rewards; cp_town_crab_boss_fight.gsc supplies boss_fight_active.
- Beast: the existing rhino_fight_over finish requires level.dead_mammoths >= 2. Mephistopheles is excluded. Stable split slots are retained for old BR1 history; slot 0 (duplicate power restoration) remains unused. Disc puzzle retains the native fuse_puzzle_completed event name.
- All maps: flag watchers reject notifications when the corresponding flag is false. Each split records once. Direct boss mode (level.direct_to_boss_fight) is excluded from full-quest PBs. Required observations below are consistency checks; Director's Cut may reveal legitimate skipped flags that need adjusting after testing.

## Profiles

The tables below reflect tools/map-profiles.cjs at release creation. That file is authoritative; regenerate the GSC/Lua profile data with npm run generate after changing it. Slot numbers are internal storage IDs, not presentation order. Ordinary event watchers use level notifications. Flag watchers additionally verify level.flag[event] is true.

### Zombies in Spaceland (cp_zmb)

| Split | Native event | Kind / condition | Slot |
| --- | --- | --- | --- |
| Pack-a-Punch visited | pap_portal_used | flag | 0 |
| SETI-COM parts delivered | dj_fetch_quest_completed | flag | 1 |
| SETI-COM defense 1 | speaker_defense_completed | ufo_stage; stage 2 | 2 |
| SETI-COM defense 2 | speaker_defense_completed | ufo_stage; stage 3 | 3 |
| SETI-COM defense 3 | speaker_defense_completed | ufo_stage; stage 4 | 4 |
| Tone generators received | tone_generators_given | flag | 5 |
| Tone generators placed | all_structs_placed | flag | 6 |
| Tone sequence complete | tones_played_successfully | flag | 7 |
| Aliens defeated | complete_alien_grey_fight | event | 8 |
| Alien fuses inserted | fuses_inserted | flag | 9 |
| UFO destroyed | ufo_destroyed | flag; guard none | 10 |

Required full-quest observations: `dj_fetch_quest_completed`, `defense_1`, `defense_2`, `defense_3`, `tones_played_successfully`, `complete_alien_grey_fight`.

### Rave in the Redwoods (cp_rave)

| Split | Native event | Kind / condition | Slot |
| --- | --- | --- | --- |
| Pack-a-Punch repaired | pap_fixed | flag | 0 |
| Pack-a-Punch visited | pap_portal_used | flag | 1 |
| First dismemberment ritual | speaker_defense_completed | jmem_stage; stage 1 | 2 |
| First photo recovered | photo_1_kev_given | flag | 3 |
| Second dismemberment ritual | speaker_defense_completed | jmem_stage; stage 4 | 4 |
| Second photo recovered | photo_2_kev_given | flag | 5 |
| Third dismemberment ritual | speaker_defense_completed | jmem_stage; stage 7 | 6 |
| Jay memory quest complete | third_quest_part_done | event | 7 |
| Boss island reached | survivor_got_to_island | flag | 8 |
| Super Slasher fight started | ss_intro_finished | event | 9 |
| First Slasher trap | super_slasher_is_trapped | event | 10 |
| Super Slasher defeated | super_slasher_death | event; guard none | 11 |

Required full-quest observations: `photo_1_kev_given`, `photo_2_kev_given`, `third_quest_part_done`, `survivor_got_to_island`.

### Shaolin Shuffle (cp_disco)

| Split | Native event | Kind / condition | Slot |
| --- | --- | --- | --- |
| Power restored | power_on | flag | 0 |
| Pam quest started | skq_phase_1 | flag | 1 |
| Locker key collected | skq_p2t1_2 | flag | 2 |
| Locker opened | skq_p2t1_3 | flag | 3 |
| Phone answered | skq_p2t2_3 | flag | 4 |
| Poster rat shot | skq_p2t2_4 | flag | 5 |
| Poster recovered | correct_poster_got | flag | 6 |
| Rat King brain collected | brain_picked | flag | 7 |
| Rat King eye collected | eye_picked | flag | 8 |
| Rat King heart collected | heart_picked | flag | 9 |
| Final boss entry activated | skq_phase_3 | flag | 10 |
| Rat King fight started | rk_fight_started | flag | 11 |
| First relic phase | rk_fight_relic_stage | flag | 12 |
| Final Rat King defeated | rat_king_killed | event; guard ratking_final | 13 |

Required full-quest observations: `brain_picked`, `eye_picked`, `heart_picked`, `skq_phase_3`.

### Attack of the Radioactive Thing (cp_town)

| Split | Native event | Kind / condition | Slot |
| --- | --- | --- | --- |
| Zombie parts collected (6/6) | level.mpq_zom_parts_picked_up | town_state; all six unique body keys true | 0 |
| Mirrors collected (3/3) | level.mirrors_picked_up | town_state; all three mirror keys true | 13 |
| Keycard collected | level.punch_card_acquired | town_state; true | 14 |
| Zombie body assembled | level.body_made | town_state; true | 1 |
| Garage key collected | level.garage_key_found | town_state; true | 2 |
| Chemistry table built | chemistry_step1 | flag | 3 |
| Chemical compound ready | chemistry_step3 | flag | 4 |
| Compound added to bomb | chemistry_step4 | flag | 5 |
| Safe opened | launchcode_step1 | flag | 6 |
| Launch codes collected | launchcode_step2 | flag | 7 |
| Bomb constructed | launchcode_step3 | flag | 8 |
| Bomb teleporter charged | teleporter_charged | flag | 9 |
| Boss entry activated | launchcode_step4 | flag | 10 |
| Crog-Zilla fight started | boss_fight_active | flag | 11 |
| Final bomb sequence won | boss_fight_finished | flag; guard none | 12 |

Required full-quest observations: `deathray_step7`, `chemistry_step4`, `launchcode_step4`.

### The Beast from Beyond (cp_final)

| Split | Native event | Kind / condition | Slot |
| --- | --- | --- | --- |
| N31L head collected | neil_head_found | flag | 2 |
| N31L head installed | neil_head_placed | flag | 3 |
| Pack-a-Punch bridge | bridge_constructed | flag | 1 |
| Energy doors disabled | security_doors_deactivated | flag | 4 |
| Disc puzzle complete | fuse_puzzle_completed | flag | 5 |
| Button in poster | button_entered_poster | flag | 6 |
| Puzzle button pressed | toggle_puzzle_button_pressed | flag | 7 |
| Toggle puzzle complete | completed_toggle_puzzle_once | flag | 8 |
| N31L delivered to PaP | neils_head_placed_in_pap | flag | 9 |
| Boss entry activated | players_triggered_bossfight | flag | 10 |
| Opening Rhinos cleared | rhino_stage_1 | flag | 11 |
| Laser survival complete | rhino_stage_4 | flag | 12 |
| EMP defense complete | rhino_stage_5 | flag | 13 |
| Beast boss defeated | rhino_fight_over | event; guard mammoths | 14 |

Required full-quest observations: `neil_head_found`, `neil_head_placed`, `security_doors_deactivated`, `fuse_puzzle_completed`, `button_entered_poster`, `completed_toggle_puzzle_once`, `neils_head_placed_in_pap`, `players_triggered_bossfight`.

## Runtime checks still required

Test all four new maps end to end in Standard and Director's Cut. Verify the three Spaceland defenses in solo and co-op, Rave ritual retries and photo timing, Shaolin's early versus final Rat Kings, and Attack's failed versus successful bomb sequence. Compare documented endpoints with category rules before treating a finish as authoritative. Check main-menu map browsing, persistent history after relaunch, team counts, and paused simulation. Earlier Beast testing confirms the overlay and early N31L events only; it does not establish a validated full run.
