// Single source for gameplay event IDs and UI labels. Reference evidence is in docs/map-events.md.
const s = (name, label, id, kind = 'flag', event = name, stage = -1) => ({name, label, id, kind, event, stage});
module.exports = [
  {
    id: 'cp_zmb', name: 'Zombies in Spaceland', short: 'SPACELAND', finishLabel: 'UFO destroyed',
    finish: {event: 'ufo_destroyed', kind: 'flag', id: 10, guard: 'none'},
    required: ['dj_fetch_quest_completed', 'defense_1', 'defense_2', 'defense_3', 'tones_played_successfully', 'complete_alien_grey_fight'],
    splits: [
      s('pap_portal_used', 'Pack-a-Punch visited', 0),
      s('dj_fetch_quest_completed', 'SETI-COM parts delivered', 1),
      s('defense_1', 'SETI-COM defense 1', 2, 'ufo_stage', 'speaker_defense_completed', 2),
      s('defense_2', 'SETI-COM defense 2', 3, 'ufo_stage', 'speaker_defense_completed', 3),
      s('defense_3', 'SETI-COM defense 3', 4, 'ufo_stage', 'speaker_defense_completed', 4),
      s('tone_generators_given', 'Tone generators received', 5),
      s('all_structs_placed', 'Tone generators placed', 6),
      s('tones_played_successfully', 'Tone sequence complete', 7),
      s('complete_alien_grey_fight', 'Aliens defeated', 8, 'event'),
      s('fuses_inserted', 'Alien fuses inserted', 9),
      s('boss_defeated', 'UFO destroyed', 10, 'finish')
    ]
  },
  {
    id: 'cp_rave', name: 'Rave in the Redwoods', short: 'RAVE', finishLabel: 'Super Slasher defeated',
    finish: {event: 'super_slasher_death', kind: 'event', id: 11, guard: 'none'},
    required: ['photo_1_kev_given', 'photo_2_kev_given', 'third_quest_part_done', 'survivor_got_to_island'],
    splits: [
      s('pap_fixed', 'Pack-a-Punch repaired', 0),
      s('pap_portal_used', 'Pack-a-Punch visited', 1),
      s('ritual_1', 'First dismemberment ritual', 2, 'jmem_stage', 'speaker_defense_completed', 1),
      s('photo_1_kev_given', 'First photo recovered', 3),
      s('ritual_2', 'Second dismemberment ritual', 4, 'jmem_stage', 'speaker_defense_completed', 4),
      s('photo_2_kev_given', 'Second photo recovered', 5),
      s('ritual_3', 'Third dismemberment ritual', 6, 'jmem_stage', 'speaker_defense_completed', 7),
      s('third_quest_part_done', 'Jay memory quest complete', 7, 'event'),
      s('survivor_got_to_island', 'Boss island reached', 8),
      s('ss_intro_finished', 'Super Slasher fight started', 9, 'event'),
      s('super_slasher_is_trapped', 'First Slasher trap', 10, 'event'),
      s('boss_defeated', 'Super Slasher defeated', 11, 'finish')
    ]
  },
  {
    id: 'cp_disco', name: 'Shaolin Shuffle', short: 'SHAOLIN', finishLabel: 'Final Rat King defeated',
    finish: {event: 'rat_king_killed', kind: 'event', id: 13, guard: 'ratking_final'},
    required: ['brain_picked', 'eye_picked', 'heart_picked', 'skq_phase_3'],
    splits: [
      s('power_on', 'Power restored', 0),
      s('skq_phase_1', 'Pam quest started', 1),
      s('skq_p2t1_2', 'Locker key collected', 2),
      s('skq_p2t1_3', 'Locker opened', 3),
      s('skq_p2t2_3', 'Phone answered', 4),
      s('skq_p2t2_4', 'Poster rat shot', 5),
      s('correct_poster_got', 'Poster recovered', 6),
      s('brain_picked', 'Rat King brain collected', 7),
      s('eye_picked', 'Rat King eye collected', 8),
      s('heart_picked', 'Rat King heart collected', 9),
      s('skq_phase_3', 'Final boss entry activated', 10),
      s('rk_fight_started', 'Rat King fight started', 11),
      s('rk_fight_relic_stage', 'First relic phase', 12),
      s('boss_defeated', 'Final Rat King defeated', 13, 'finish')
    ]
  },
  {
    id: 'cp_town', name: 'Attack of the Radioactive Thing', short: 'ATTACK', finishLabel: 'Final bomb sequence won',
    finish: {event: 'boss_fight_finished', kind: 'flag', id: 12, guard: 'none'},
    required: ['deathray_step7', 'chemistry_step4', 'launchcode_step4'],
    splits: [
      // Retail garage interactions update fields, not the deathray quest flags.
      // Keep legacy names/slots for saved history and custom labels.
      s('deathray_step1', 'Zombie parts collected (6/6)', 0, 'town_state', 'mpq_zom_parts_picked_up'),
      s('mirrors_collected', 'Mirrors collected (3/3)', 13, 'town_state', 'mirrors_picked_up'),
      s('keycard_collected', 'Keycard collected', 14, 'town_state', 'punch_card_acquired'),
      s('deathray_step4', 'Zombie body assembled', 1, 'town_state', 'body_made'),
      s('deathray_step7', 'Garage key collected', 2, 'town_state', 'garage_key_found'),
      s('chemistry_step1', 'Chemistry table built', 3),
      s('chemistry_step3', 'Chemical compound ready', 4),
      s('chemistry_step4', 'Compound added to bomb', 5),
      s('launchcode_step1', 'Safe opened', 6),
      s('launchcode_step2', 'Launch codes collected', 7),
      s('launchcode_step3', 'Bomb constructed', 8),
      s('teleporter_charged', 'Bomb teleporter charged', 9),
      s('launchcode_step4', 'Boss entry activated', 10),
      s('boss_fight_active', 'Crog-Zilla fight started', 11),
      s('boss_defeated', 'Final bomb sequence won', 12, 'finish')
    ]
  },
  {
    id: 'cp_final', name: 'The Beast from Beyond', short: 'BEAST', finishLabel: 'Beast boss defeated',
    finish: {event: 'rhino_fight_over', kind: 'event', id: 14, guard: 'mammoths'},
    required: ['neil_head_found', 'neil_head_placed', 'security_doors_deactivated', 'fuse_puzzle_completed', 'button_entered_poster', 'completed_toggle_puzzle_once', 'neils_head_placed_in_pap', 'players_triggered_bossfight'],
    splits: [
      s('neil_head_found', 'N31L head collected', 2), s('neil_head_placed', 'N31L head installed', 3),
      s('bridge_constructed', 'Pack-a-Punch bridge', 1), s('security_doors_deactivated', 'Energy doors disabled', 4),
      s('fuse_puzzle_completed', 'Disc puzzle complete', 5), s('button_entered_poster', 'Button in poster', 6),
      s('toggle_puzzle_button_pressed', 'Puzzle button pressed', 7), s('completed_toggle_puzzle_once', 'Toggle puzzle complete', 8),
      s('neils_head_placed_in_pap', 'N31L delivered to PaP', 9), s('players_triggered_bossfight', 'Boss entry activated', 10),
      s('rhino_stage_1', 'Opening Rhinos cleared', 11), s('rhino_stage_4', 'Laser survival complete', 12),
      s('rhino_stage_5', 'EMP defense complete', 13), s('boss_defeated', 'Beast boss defeated', 14, 'finish')
    ]
  }
];
