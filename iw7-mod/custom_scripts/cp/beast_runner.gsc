// IW7 Zombies Speedrun Toolkit 0.3.3. Observe only: no quest replacements.
init()
{
    setdvar("br_enabled", 0);
    level.br_map = getdvar("mapname");
    if (!configure_map())
        return;

    level.br_state = "armed";
    level.br_start = -1;
    level.br_elapsed = 0;
    level.br_seen = [];
    level.br_splits = [];
    level.br_players = [];
    level.br_max_players = 0;
    level.br_dc = 0;
    level.br_round = 0;
    level.br_kills = 0;
    level.br_downs = 0;
    level.br_revives = 0;
    level.br_headshots = 0;
    level.br_defense_count = 0;
    level.br_defense_last = -10000;
    setdvar("br_map", level.br_map);
    setdvar("br_log_path", getdvar("g_log"));
    setdvar("br_enabled", 1);
    setdvar("br_finish_valid", 0);
    setdvar("br_hud_toggle", 0);
    for (i = 0; i < 15; i++)
        setdvar("br_split_" + i, -1);
    publish();

    foreach (i, name in level.br_names)
    {
        if (name != "" && level.br_kinds[i] != "finish" && level.br_kinds[i] != "town_state")
            level thread watch_split(i);
    }
    level thread watch_boss_finish();
    level thread watch_game_end();
    level thread watch_shutdown();
    level thread watch_connections();
    level thread update_snapshot();
    // Covers clients already connected before this script's init handle runs.
    if (isdefined(level.players))
    {
        foreach (player in level.players)
            attach_player(player);
    }
    println("[BeastRunner] Armed for " + level.br_map + ": first spawn -> " + level.br_finish_event);
}

watch_connections()
{
    level endon("game_ended");
    for (;;)
    {
        level waittill("connected", player);
        attach_player(player);
    }
}

attach_player(player)
{
    if (!isdefined(player) || isdefined(player.br_attached))
        return;
    player.br_attached = 1;
    player thread watch_spawn();
}

watch_spawn()
{
    self endon("disconnect");
    level endon("game_ended");
    self waittill("spawned_player");
    if (level.br_state == "armed")
    {
        level.br_start = gettime();
        level.br_state = "running";
        collect_stats();
        emit("START", "first_spawn", 0);
        foreach (i, name in level.br_names)
        {
            if (isdefined(level.br_seen[i]))
                record_split(i, name, level.br_seen[i]);
        }
        publish();
    }
}

watch_split(index)
{
    level endon("game_ended");
    event = level.br_events[index];
    kind = level.br_kinds[index];
    for (;;)
    {
        level waittill(event);
        stamp = gettime();
        // flag_clear also notifies the same name: accept only a true flag.
        if (kind == "flag" && !flag_is_set(event))
            continue;
        // Spaceland emits this once per player. Count unique completions only.
        // The quest thread can advance its index before our observer resumes.
        if (kind == "ufo_stage")
        {
            if (stamp - level.br_defense_last < 1000 || level.br_stages[index] != level.br_defense_count + 2)
                continue;
            level.br_defense_last = stamp;
            level.br_defense_count++;
        }
        if (kind == "jmem_stage")
        {
            quest = "jmem";
            if (!isdefined(level.zombie_current_quest_step_index) || !isdefined(level.zombie_current_quest_step_index[quest]) || level.zombie_current_quest_step_index[quest] != level.br_stages[index])
                continue;
        }
        level.br_seen[index] = stamp;
        record_split(index, level.br_names[index], stamp);
        return;
    }
}

flag_is_set(name)
{
    return isdefined(level.flag) && isdefined(level.flag[name]) && level.flag[name];
}

array_has_all(parts, keys)
{
    if (!isdefined(parts))
        return 0;
    foreach (key in keys)
    {
        if (!isdefined(parts[key]) || !parts[key])
            return 0;
    }
    return 1;
}

town_state_complete(name)
{
    switch (name)
    {
        case "mpq_zom_parts_picked_up":
            return array_has_all(level.mpq_zom_parts_picked_up, ["head", "torso", "left_arm", "right_arm", "left_leg", "right_leg"]);
        case "mirrors_picked_up":
            return array_has_all(level.mirrors_picked_up, ["car_mirror", "bathroom_mirror", "elvira_mirror"]);
        case "punch_card_acquired":
            return isdefined(level.punch_card_acquired) && level.punch_card_acquired;
        case "body_made":
            return isdefined(level.body_made) && level.body_made;
        case "garage_key_found":
            return isdefined(level.garage_key_found) && level.garage_key_found;
    }
    return 0;
}

sample_town_splits()
{
    if (level.br_map != "cp_town" || (level.br_state != "armed" && level.br_state != "running"))
        return;
    stamp = gettime();
    foreach (i, name in level.br_names)
    {
        if (level.br_kinds[i] == "town_state" && !isdefined(level.br_seen[i]) && town_state_complete(level.br_events[i]))
        {
            level.br_seen[i] = stamp;
            record_split(i, name, stamp);
        }
    }
}

record_split(index, name, stamp)
{
    if (level.br_state != "running" || isdefined(level.br_splits[index]))
        return;
    elapsed = max(0, stamp - level.br_start);
    level.br_splits[index] = elapsed;
    setdvar("br_split_" + index, elapsed);
    collect_stats();
    emit("SPLIT", name, elapsed);
}

watch_boss_finish()
{
    level endon("game_ended");
    for (;;)
    {
        level waittill(level.br_finish_event);
        stamp = gettime();
        if (level.br_state != "running")
            continue;
        if (level.br_finish_kind == "flag" && !flag_is_set(level.br_finish_event))
            continue;
        if (level.br_finish_guard == "mammoths" && (!isdefined(level.dead_mammoths) || level.dead_mammoths < 2))
            continue;
        // Shaolin also has earlier Rat Kings. Only accept the final fight stage.
        if (level.br_finish_guard == "ratking_final" && (!isdefined(level.rat_king_stage) || level.rat_king_stage < 6))
            continue;
        level.br_elapsed = max(0, stamp - level.br_start);
        level.br_splits[level.br_finish_index] = level.br_elapsed;
        setdvar("br_split_" + level.br_finish_index, level.br_elapsed);
        // Exclude shortcuts / direct boss mode from complete-quest PBs.
        valid = 1;
        if (isdefined(level.direct_to_boss_fight) && level.direct_to_boss_fight)
            valid = 0;
        foreach (name in level.br_required)
        {
            found = 0;
            foreach (i, split_name in level.br_names)
            {
                if (split_name == name && isdefined(level.br_seen[i]))
                    found = 1;
            }
            if (!found)
                valid = 0;
        }
        collect_stats();
        level.br_state = "finished";
        setdvar("br_finish_valid", valid);
        emit("FINISH", "boss_defeated", level.br_elapsed);
        publish();
        return;
    }
}

watch_game_end()
{
    level waittill("game_ended");
    abort_run("game_ended");
}

watch_shutdown()
{
    level waittill("shutdownGame_called");
    abort_run("map_shutdown");
    setdvar("br_enabled", 0);
}

abort_run(reason)
{
    if (level.br_state != "running")
        return;
    level.br_elapsed = max(0, gettime() - level.br_start);
    collect_stats();
    level.br_state = "aborted";
    emit("ABORT", reason, level.br_elapsed);
    publish();
}

update_snapshot()
{
    level endon("game_ended");
    next_stats = 0;
    for (;;)
    {
        if (getdvarint("br_hud_toggle"))
        {
            if (getdvar("br_hud") == "0")
                setdvar("br_hud", 1);
            else
                setdvar("br_hud", 0);
            setdvar("br_hud_toggle", 0);
        }
        if (level.br_state == "running")
            level.br_elapsed = max(0, gettime() - level.br_start);
        // These garage fields have no native completion notify; sample once/tick.
        sample_town_splits();
        if (level.br_state == "running" && gettime() >= next_stats)
        {
            collect_stats();
            emit("STAT", "team", level.br_elapsed);
            next_stats = gettime() + 1000;
        }
        publish();
        wait 0.05;
    }
}

collect_stats()
{
    if (isdefined(level.wave_num))
        level.br_round = level.wave_num;
    if (isdefined(level.directors_cut_is_activated) && level.directors_cut_is_activated)
        level.br_dc = 1;
    if (isdefined(level.players))
    {
        level.br_max_players = max(level.br_max_players, level.players.size);
        foreach (player in level.players)
        {
            id = player getentitynumber();
            ddl_id = id;
            if (ddl_id == 4)
                ddl_id = 0;
            row = spawnstruct();
            row.kills = player getrankedplayerdata("cp", "EoGPlayer", ddl_id, "kills");
            row.downs = player getrankedplayerdata("cp", "EoGPlayer", ddl_id, "downs");
            row.revives = player getrankedplayerdata("cp", "EoGPlayer", ddl_id, "revives");
            row.headshots = 0;
            if (isdefined(player.headshots))
            {
                foreach (count in player.headshots)
                    row.headshots += count;
            }
            level.br_players[id] = row;
        }
    }
    level.br_kills = 0;
    level.br_downs = 0;
    level.br_revives = 0;
    level.br_headshots = 0;
    foreach (row in level.br_players)
    {
        if (isdefined(row.kills))
            level.br_kills += row.kills;
        if (isdefined(row.downs))
            level.br_downs += row.downs;
        if (isdefined(row.revives))
            level.br_revives += row.revives;
        level.br_headshots += row.headshots;
    }
}

publish()
{
    setdvar("br_snapshot", level.br_state + "|" + level.br_elapsed + "|" + level.br_round + "|" + level.br_kills + "|" + level.br_downs + "|" + level.br_revives + "|" + level.br_headshots + "|" + level.br_max_players + "|" + level.br_dc + "|" + level.br_map);
}

emit(kind, name, elapsed)
{
    // Stable, versioned, append-only records in iw7-mod's existing g_log.
    // gettime() is stored as an integer; no float seconds or update-count timing.
    logprint("BR2|" + level.br_map + "|" + kind + "|" + name + "|" + elapsed + "|" + level.br_round + "|" + level.br_kills + "|" + level.br_downs + "|" + level.br_revives + "|" + level.br_headshots + "|" + level.br_max_players + "|" + level.br_dc + "|" + getdvarint("br_finish_valid") + "\n");
}

// BEGIN GENERATED MAP PROFILES
configure_map()
{
    switch (level.br_map)
    {
        case "cp_zmb":
            level.br_names = ["pap_portal_used", "dj_fetch_quest_completed", "defense_1", "defense_2", "defense_3", "tone_generators_given", "all_structs_placed", "tones_played_successfully", "complete_alien_grey_fight", "fuses_inserted", "boss_defeated", "", "", "", ""];
            level.br_events = ["pap_portal_used", "dj_fetch_quest_completed", "speaker_defense_completed", "speaker_defense_completed", "speaker_defense_completed", "tone_generators_given", "all_structs_placed", "tones_played_successfully", "complete_alien_grey_fight", "fuses_inserted", "boss_defeated", "", "", "", ""];
            level.br_kinds = ["flag", "flag", "ufo_stage", "ufo_stage", "ufo_stage", "flag", "flag", "flag", "event", "flag", "finish", "", "", "", ""];
            level.br_stages = [-1, -1, 2, 3, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];
            level.br_required = ["dj_fetch_quest_completed", "defense_1", "defense_2", "defense_3", "tones_played_successfully", "complete_alien_grey_fight"];
            level.br_finish_event = "ufo_destroyed";
            level.br_finish_kind = "flag";
            level.br_finish_guard = "none";
            level.br_finish_index = 10;
            return 1;
        case "cp_rave":
            level.br_names = ["pap_fixed", "pap_portal_used", "ritual_1", "photo_1_kev_given", "ritual_2", "photo_2_kev_given", "ritual_3", "third_quest_part_done", "survivor_got_to_island", "ss_intro_finished", "super_slasher_is_trapped", "boss_defeated", "", "", ""];
            level.br_events = ["pap_fixed", "pap_portal_used", "speaker_defense_completed", "photo_1_kev_given", "speaker_defense_completed", "photo_2_kev_given", "speaker_defense_completed", "third_quest_part_done", "survivor_got_to_island", "ss_intro_finished", "super_slasher_is_trapped", "boss_defeated", "", "", ""];
            level.br_kinds = ["flag", "flag", "jmem_stage", "flag", "jmem_stage", "flag", "jmem_stage", "event", "flag", "event", "event", "finish", "", "", ""];
            level.br_stages = [-1, -1, 1, -1, 4, -1, 7, -1, -1, -1, -1, -1, -1, -1, -1];
            level.br_required = ["photo_1_kev_given", "photo_2_kev_given", "third_quest_part_done", "survivor_got_to_island"];
            level.br_finish_event = "super_slasher_death";
            level.br_finish_kind = "event";
            level.br_finish_guard = "none";
            level.br_finish_index = 11;
            return 1;
        case "cp_disco":
            level.br_names = ["power_on", "skq_phase_1", "skq_p2t1_2", "skq_p2t1_3", "skq_p2t2_3", "skq_p2t2_4", "correct_poster_got", "brain_picked", "eye_picked", "heart_picked", "skq_phase_3", "rk_fight_started", "rk_fight_relic_stage", "boss_defeated", ""];
            level.br_events = ["power_on", "skq_phase_1", "skq_p2t1_2", "skq_p2t1_3", "skq_p2t2_3", "skq_p2t2_4", "correct_poster_got", "brain_picked", "eye_picked", "heart_picked", "skq_phase_3", "rk_fight_started", "rk_fight_relic_stage", "boss_defeated", ""];
            level.br_kinds = ["flag", "flag", "flag", "flag", "flag", "flag", "flag", "flag", "flag", "flag", "flag", "flag", "flag", "finish", ""];
            level.br_stages = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];
            level.br_required = ["brain_picked", "eye_picked", "heart_picked", "skq_phase_3"];
            level.br_finish_event = "rat_king_killed";
            level.br_finish_kind = "event";
            level.br_finish_guard = "ratking_final";
            level.br_finish_index = 13;
            return 1;
        case "cp_town":
            level.br_names = ["deathray_step1", "deathray_step4", "deathray_step7", "chemistry_step1", "chemistry_step3", "chemistry_step4", "launchcode_step1", "launchcode_step2", "launchcode_step3", "teleporter_charged", "launchcode_step4", "boss_fight_active", "boss_defeated", "mirrors_collected", "keycard_collected"];
            level.br_events = ["mpq_zom_parts_picked_up", "body_made", "garage_key_found", "chemistry_step1", "chemistry_step3", "chemistry_step4", "launchcode_step1", "launchcode_step2", "launchcode_step3", "teleporter_charged", "launchcode_step4", "boss_fight_active", "boss_defeated", "mirrors_picked_up", "punch_card_acquired"];
            level.br_kinds = ["town_state", "town_state", "town_state", "flag", "flag", "flag", "flag", "flag", "flag", "flag", "flag", "flag", "finish", "town_state", "town_state"];
            level.br_stages = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];
            level.br_required = ["deathray_step7", "chemistry_step4", "launchcode_step4"];
            level.br_finish_event = "boss_fight_finished";
            level.br_finish_kind = "flag";
            level.br_finish_guard = "none";
            level.br_finish_index = 12;
            return 1;
        case "cp_final":
            level.br_names = ["", "bridge_constructed", "neil_head_found", "neil_head_placed", "security_doors_deactivated", "fuse_puzzle_completed", "button_entered_poster", "toggle_puzzle_button_pressed", "completed_toggle_puzzle_once", "neils_head_placed_in_pap", "players_triggered_bossfight", "rhino_stage_1", "rhino_stage_4", "rhino_stage_5", "boss_defeated"];
            level.br_events = ["", "bridge_constructed", "neil_head_found", "neil_head_placed", "security_doors_deactivated", "fuse_puzzle_completed", "button_entered_poster", "toggle_puzzle_button_pressed", "completed_toggle_puzzle_once", "neils_head_placed_in_pap", "players_triggered_bossfight", "rhino_stage_1", "rhino_stage_4", "rhino_stage_5", "boss_defeated"];
            level.br_kinds = ["", "flag", "flag", "flag", "flag", "flag", "flag", "flag", "flag", "flag", "flag", "flag", "flag", "flag", "finish"];
            level.br_stages = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];
            level.br_required = ["neil_head_found", "neil_head_placed", "security_doors_deactivated", "fuse_puzzle_completed", "button_entered_poster", "completed_toggle_puzzle_once", "neils_head_placed_in_pap", "players_triggered_bossfight"];
            level.br_finish_event = "rhino_fight_over";
            level.br_finish_kind = "event";
            level.br_finish_guard = "mammoths";
            level.br_finish_index = 14;
            return 1;
    }
    return 0;
}
// END GENERATED MAP PROFILES
