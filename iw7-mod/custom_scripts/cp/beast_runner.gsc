// Beast Runner 0.1.0. Observe only: no quest replacements or gameplay changes.
init()
{
    if (getdvar("mapname") != "cp_final")
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
    level.br_flags = ["power_on", "bridge_constructed", "neil_head_found", "neil_head_placed", "security_doors_deactivated", "fuse_puzzle_completed", "button_entered_poster", "toggle_puzzle_button_pressed", "completed_toggle_puzzle_once", "neils_head_placed_in_pap", "players_triggered_bossfight", "rhino_stage_1", "rhino_stage_4", "rhino_stage_5"];
    setdvar("br_log_path", getdvar("g_log"));
    setdvar("br_enabled", 1);
    setdvar("br_finish_valid", 0);
    for (i = 0; i < level.br_flags.size + 1; i++)
        setdvar("br_split_" + i, -1);
    publish();

    foreach (i, flag in level.br_flags)
        level thread watch_flag(i, flag);
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
    println("[BeastRunner] Armed: first spawn -> second final Mammoth death; game time.");
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
        foreach (i, flag in level.br_flags)
        {
            if (isdefined(level.br_seen[i]))
                record_split(i, flag, level.br_seen[i]);
        }
        publish();
    }
}

watch_flag(index, flag)
{
    level endon("game_ended");
    for (;;)
    {
        level waittill(flag);
        // flag_clear also notifies the same name: accept only a true flag.
        if (!isdefined(level.flag) || !isdefined(level.flag[flag]) || !level.flag[flag])
            continue;
        stamp = gettime();
        level.br_seen[index] = stamp;
        record_split(index, flag, stamp);
        return;
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
        level waittill("rhino_fight_over");
        stamp = gettime();
        if (level.br_state != "running" || !isdefined(level.dead_mammoths) || level.dead_mammoths < 2)
            continue;
        level.br_elapsed = max(0, stamp - level.br_start);
        level.br_splits[14] = level.br_elapsed;
        setdvar("br_split_14", level.br_elapsed);
        // Exclude shortcuts / direct boss mode from complete-quest PBs.
        required = ["neil_head_found", "neil_head_placed", "security_doors_deactivated", "fuse_puzzle_completed", "button_entered_poster", "completed_toggle_puzzle_once", "neils_head_placed_in_pap", "players_triggered_bossfight"];
        valid = 1;
        foreach (flag in required)
        {
            if (!isdefined(level.flag) || !isdefined(level.flag[flag]) || !level.flag[flag])
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
        if (level.br_state == "running")
            level.br_elapsed = max(0, gettime() - level.br_start);
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
    setdvar("br_snapshot", level.br_state + "|" + level.br_elapsed + "|" + level.br_round + "|" + level.br_kills + "|" + level.br_downs + "|" + level.br_revives + "|" + level.br_headshots + "|" + level.br_max_players + "|" + level.br_dc);
}

emit(kind, name, elapsed)
{
    // Stable, versioned, append-only records in iw7-mod's existing g_log.
    // gettime() is stored as an integer; no float seconds or update-count timing.
    logprint("BR1|" + kind + "|" + name + "|" + elapsed + "|" + level.br_round + "|" + level.br_kills + "|" + level.br_downs + "|" + level.br_revives + "|" + level.br_headshots + "|" + level.br_max_players + "|" + level.br_dc + "|" + getdvarint("br_finish_valid") + "\n");
}
