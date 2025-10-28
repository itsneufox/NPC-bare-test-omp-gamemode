#include <open.mp>
#include <omp_npc>

main(){}

const INVALID_TIMER_ID = 0;
const DIALOG_HELP = 1000;

new g_NPCCount = 0,
    PlayerNPC[MAX_PLAYERS] = {INVALID_NPC_ID, ...},
    PlayerPatrolPath[MAX_PLAYERS] = {INVALID_PATH_ID, ...};

new PlayerVehicles[MAX_PLAYERS][3]; // [0] = motorcycle, [1] = car, [2] = train
new PlayerText:TXD_DEBUG_NPC[MAX_PLAYERS] = {PlayerText:INVALID_TEXT_DRAW, ...};
new PlayerNPCInfoTimer[MAX_PLAYERS] = {INVALID_TIMER_ID, ...};
new PlayerPatrolTimer[MAX_PLAYERS] = {INVALID_TIMER_ID, ...};

static const HELP_DIALOG_TEXT[] =
    "Command\tDescription\n\
/createnpc\tSpawn armed NPC and start tracking it.\n\
/createunarmednpc\tSpawn an unarmed NPC.\n\
/destroynpc\tDestroy your current NPC.\n\
/claimnpc [id]\tAttach debugger to an existing NPC.\n\
/aim, /aimfire\tAim (or fire) at you.\n\
/hostile, /guard\tToggle hostile/guard behaviour.\n\
/friendly\tStop aiming at you.\n\
/applydance, /setdance\tApply preset animations.\n\
/getanim\tInspect current animation state.\n\
/toggleinfiniteammo\tToggle infinite ammo.\n\
/togglereload\tToggle reloading behaviour.\n\
/createpatrol\tCreate a new patrol path.\n\
/addpatrolpos\tAdd a patrol point at your position.\n\
/startpatrol\tSend NPC along the patrol path.\n\
/npcenterbike [seat]\tPlace NPC into your motorcycle.\n\
/npcentercar [seat]\tPlace NPC into your car.\n\
/npcentertrain [seat]\tPlace NPC into your train.\n\
/npcexitbike|car|train\tForce the NPC to exit vehicles.\n\
/checkarmour\tCheck NPC armour.\n\
/checkammo\tCheck NPC total ammo.\n\
/checkclip\tCheck ammo in clip.\n\
/checkentervehicle\tShow the vehicle the NPC is entering.\n\
/checkenteringvehicleid\tGet entering vehicle ID.\n\
/checkentervehseat\tGet entering vehicle seat.\n\
/checkfacingangle\tGet NPC facing angle.\n\
/checkfightingstyle\tGet NPC fighting style.\n\
/checkhealth\tGet NPC health.\n\
/checkinterior\tGet NPC interior.\n\
/checkkeys\tGet NPC key states.\n\
/checkpathcount\tShow total path count.\n\
/checkpathpoint\tGet current path point coords.\n\
/checkpathpointcount\tGet path point count.\n\
/checkpos\tGet NPC position.\n\
/countnpcs\tShow total NPC count.";

stock StopPlayerNPCInfoTimer(playerid)
{
    if (PlayerNPCInfoTimer[playerid] != INVALID_TIMER_ID && IsValidTimer(PlayerNPCInfoTimer[playerid]))
    {
        KillTimer(PlayerNPCInfoTimer[playerid]);
    }
    PlayerNPCInfoTimer[playerid] = INVALID_TIMER_ID;
}

stock StopPlayerPatrolTimer(playerid)
{
    if (PlayerPatrolTimer[playerid] != INVALID_TIMER_ID && IsValidTimer(PlayerPatrolTimer[playerid]))
    {
        KillTimer(PlayerPatrolTimer[playerid]);
    }
    PlayerPatrolTimer[playerid] = INVALID_TIMER_ID;
}

public OnGameModeInit()
{
    AddPlayerClass(0, 2495.3547, -1688.2319, 13.6774, 351.1646, WEAPON_M4, 500, WEAPON_KNIFE, 1, WEAPON_COLT45, 100);
    return 1;
}

public OnGameModeExit()
{
    // Get number of paths before clearing
    new total = NPC_GetPathCount();

    // Try to destroy them all
    if (NPC_DestroyAllPath())
    {
        printf("[NPC] Destroyed all NPC paths (%d removed).", total);
    }
    else
    {
        printf("[NPC] Failed to destroy NPC paths.");
    }

    return 1;
}


public OnPlayerConnect(playerid)
{
    StopPlayerNPCInfoTimer(playerid);
    StopPlayerPatrolTimer(playerid);

    PlayerNPC[playerid] = INVALID_NPC_ID;
    PlayerPatrolPath[playerid] = INVALID_PATH_ID;
    PlayerVehicles[playerid][0] = INVALID_VEHICLE_ID;
    PlayerVehicles[playerid][1] = INVALID_VEHICLE_ID;
    PlayerVehicles[playerid][2] = INVALID_VEHICLE_ID;

    if (IsPlayerNPC(playerid))
    {
        return 1;
    }

    if (TXD_DEBUG_NPC[playerid] != PlayerText:INVALID_TEXT_DRAW)
    {
        PlayerTextDrawDestroy(playerid, TXD_DEBUG_NPC[playerid]);
        TXD_DEBUG_NPC[playerid] = PlayerText:INVALID_TEXT_DRAW;
    }

    // Create per-player vehicles
    PlayerVehicles[playerid][0] = CreateVehicle(522, 2493.7583, -1683.6482, 12.9099, 270.8069, 225, 155, -1, false);
    PlayerVehicles[playerid][1] = CreateVehicle(411, 2473.9121, -1683.4276, 13.3589, -34.5, 136, 142, -1, false);
    PlayerVehicles[playerid][2] = AddStaticVehicle(538, 2216.4900, -1645.4043, 17.0335, 180, 175, 225);

    TXD_DEBUG_NPC[playerid] = CreatePlayerTextDraw(playerid, 444.0, 109.0, " ");
    PlayerTextDrawLetterSize(playerid, TXD_DEBUG_NPC[playerid], 0.25, 1.0);
    PlayerTextDrawTextSize(playerid, TXD_DEBUG_NPC[playerid], 617.0, 385.466666);
    PlayerTextDrawAlignment(playerid, TXD_DEBUG_NPC[playerid], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, TXD_DEBUG_NPC[playerid], 0xFFFFFFFF);
    PlayerTextDrawUseBox(playerid, TXD_DEBUG_NPC[playerid], true);
    PlayerTextDrawBoxColour(playerid, TXD_DEBUG_NPC[playerid], 0x00000088);
    PlayerTextDrawSetShadow(playerid, TXD_DEBUG_NPC[playerid], false);
    PlayerTextDrawSetOutline(playerid, TXD_DEBUG_NPC[playerid], true);
    PlayerTextDrawBackgroundColour(playerid, TXD_DEBUG_NPC[playerid], 0x000000FF);
    PlayerTextDrawFont(playerid, TXD_DEBUG_NPC[playerid], TEXT_DRAW_FONT_1);
    PlayerTextDrawSetProportional(playerid, TXD_DEBUG_NPC[playerid], true);
    PlayerTextDrawShow(playerid, TXD_DEBUG_NPC[playerid]);

    PlayerNPCInfoTimer[playerid] = SetTimerEx("UpdateNPCInfo", 250, true, "i", playerid);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    StopPlayerNPCInfoTimer(playerid);
    StopPlayerPatrolTimer(playerid);

    // Destroy player's NPC if they have one
    if (NPC_IsValid(PlayerNPC[playerid]))
    {
        NPC_Destroy(PlayerNPC[playerid]);
        PlayerNPC[playerid] = INVALID_NPC_ID;
    }

    // Destroy player's patrol path if they have one
    if (NPC_IsValidPath(PlayerPatrolPath[playerid]))
    {
        NPC_DestroyPath(PlayerPatrolPath[playerid]);
        PlayerPatrolPath[playerid] = INVALID_PATH_ID;
    }

    // Destroy player's vehicles
    if (PlayerVehicles[playerid][0] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(PlayerVehicles[playerid][0]);
        PlayerVehicles[playerid][0] = INVALID_VEHICLE_ID;
    }
    if (PlayerVehicles[playerid][1] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(PlayerVehicles[playerid][1]);
        PlayerVehicles[playerid][1] = INVALID_VEHICLE_ID;
    }
    if (PlayerVehicles[playerid][2] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(PlayerVehicles[playerid][2]);
        PlayerVehicles[playerid][2] = INVALID_VEHICLE_ID;
    }

    if (TXD_DEBUG_NPC[playerid] != PlayerText:INVALID_TEXT_DRAW)
    {
        PlayerTextDrawDestroy(playerid, TXD_DEBUG_NPC[playerid]);
        TXD_DEBUG_NPC[playerid] = PlayerText:INVALID_TEXT_DRAW;
    }

    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    SetPlayerPos(playerid, 217.8511, -98.4865, 1005.2578);
    SetPlayerSkin(playerid, 7);
    SetPlayerFacingAngle(playerid, 113.8861);
    SetPlayerInterior(playerid, 15);
    SetPlayerCameraPos(playerid, 215.2182, -99.5546, 1006.4);
    SetPlayerCameraLookAt(playerid, 217.8511, -98.4865, 1005.2578);
    
    return 1;
}

public OnPlayerSpawn(playerid)
{
    SetPlayerInterior(playerid, 0);
    return 1;
}

public OnPlayerUpdate(playerid)
{
    new Float:health, Float:armour;
    GetPlayerHealth(playerid, health);
    GetPlayerArmour(playerid, armour);

    if (health < 20.0)
        SetPlayerHealth(playerid, 100.0);
    if (armour < 20.0)
        SetPlayerArmour(playerid, 100.0);

    return 1;
}

forward UpdateNPCInfo(playerid);
public UpdateNPCInfo(playerid)
{
    if (!IsPlayerConnected(playerid))
    {
        StopPlayerNPCInfoTimer(playerid);
        return 0;
    }

    if (TXD_DEBUG_NPC[playerid] == PlayerText:INVALID_TEXT_DRAW)
    {
        StopPlayerNPCInfoTimer(playerid);
        return 0;
    }

    // Use only this player's NPC
    new npcid = PlayerNPC[playerid];

    if (npcid == INVALID_NPC_ID || !NPC_IsValid(npcid))
    {
        PlayerTextDrawSetString(playerid, TXD_DEBUG_NPC[playerid], "~r~No NPC created");
        return 1;
    }
    
    new Float:x, Float:y, Float:z;
    NPC_GetPos(npcid, x, y, z);
    
    // Get facing angle if the function exists in your include
    new Float:angle;
    NPC_GetFacingAngle(npcid, angle); // Check if this needs an extra parameter
    
    // Basic NPC stats
    new Float:hp = NPC_GetHealth(npcid);
    new Float:arm = NPC_GetArmour(npcid);
    
    // Weapon info
    new wep = NPC_GetWeapon(npcid);
    new ammo = NPC_GetAmmo(npcid);
    new clip = NPC_GetAmmoInClip(npcid);
    
    // Combat flags
    new bool:reloadEnabled = NPC_IsReloadEnabled(npcid);
    new bool:infAmmo = NPC_IsInfiniteAmmoEnabled(npcid);
    new bool:reloading = NPC_IsReloading(npcid);
    new bool:shooting = NPC_IsShooting(npcid);
    new bool:aiming = NPC_IsAiming(npcid);
    new bool:invul = NPC_IsInvulnerable(npcid);
    
    // Movement and vehicle
    new moving = NPC_IsMoving(npcid);
    new veh = NPC_GetVehicle(npcid);
    
    // Other properties
    new style = NPC_GetFightingStyle(npcid);
    new action = NPC_GetSpecialAction(npcid);
    new vw = NPC_GetVirtualWorld(npcid);
    new interior = NPC_GetInterior(npcid);
    
    new text[512];
    format(text, sizeof(text),
        "~y~NPC DEBUG FOR NPC ID: %d ~n~~w~HP: %.1f~n~ARM: %.1f~n~WEP: %d~n~AMMO: %d / CLIP: %d~n~\
        POS: %.2f %.2f %.2f~n~ANGLE: %.1f~n~MOVING: %d / VEH: %d~n~\
        RELOAD ENABLED: %d~n~INFINITE AMMO: %d~n~RELOADING: %d~n~\
        SHOOTING: %d~n~AIMING: %d~n~INVULNERABLE: %d~n~\
        STYLE: %d / ACTION: %d~n~VW: %d / INT: %d",
        npcid, hp, arm, wep, ammo, clip,
        x, y, z, angle, moving, veh,
        reloadEnabled, infAmmo, reloading,
        shooting, aiming, invul,
        style, action, vw, interior);
    
    PlayerTextDrawSetString(playerid, TXD_DEBUG_NPC[playerid], text);
    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!strcmp(cmdtext, "/help", true))
    {
        ShowPlayerDialog(playerid, DIALOG_HELP, DIALOG_STYLE_TABLIST, "NPC Helper Commands", HELP_DIALOG_TEXT, "", "Close");
        return 1;
    }

    // ============================================================
    // NPC MANAGEMENT
    // ============================================================
    if (!strcmp(cmdtext, "/createnpc", true))
    {
        new name[24];
        format(name, sizeof name, "Bot_%d", g_NPCCount++);

        new npcid = NPC_Create(name);
        if (NPC_IsValid(npcid))
        {
            new Float:x, Float:y, Float:z;
            GetPlayerPos(playerid, x, y, z);

            NPC_Spawn(npcid);
            NPC_SetPos(npcid, x + 3.0, y, z);
            NPC_SetWeapon(npcid, WEAPON_M4);
            NPC_SetAmmo(npcid, 500);

            PlayerNPC[playerid] = npcid;
            SendClientMessage(playerid, 0x00FF00FF, "NPC %s (ID %d) spawned near you!", name, npcid);
        }
        else
        {
            SendClientMessage(playerid, 0xFF0000FF, "Failed to create NPC!");
        }
        return 1;
    }

    if (!strcmp(cmdtext, "/createunarmednpc", true))
    {
        new name[24];
        format(name, sizeof name, "Bot_%d", g_NPCCount++);

        new npcid = NPC_Create(name);
        if (NPC_IsValid(npcid))
        {
            new Float:x, Float:y, Float:z;
            GetPlayerPos(playerid, x, y, z);

            NPC_Spawn(npcid);
            NPC_SetPos(npcid, x + 3.0, y, z);

            PlayerNPC[playerid] = npcid;
            SendClientMessage(playerid, 0x00FF00FF, "Unarmed NPC %s (ID %d) spawned near you!", name, npcid);
        }
        else
        {
            SendClientMessage(playerid, 0xFF0000FF, "Failed to create NPC!");
        }
        return 1;
    }

    if (!strcmp(cmdtext, "/destroynpc", true))
    {
        new npcid = PlayerNPC[playerid];

        if (!NPC_IsValid(npcid))
        {
            SendClientMessage(playerid, 0xFF0000FF, "You don't have a valid NPC to destroy.");
            return 1;
        }

        if (NPC_Destroy(npcid))
        {
            SendClientMessage(playerid, 0x00FF00FF, "Your NPC (ID %d) was destroyed.", npcid);
            PlayerNPC[playerid] = INVALID_NPC_ID; // or 0 if you don't have INVALID_NPC_ID defined
        }
        else
        {
            SendClientMessage(playerid, 0xFF0000FF, "Failed to destroy your NPC (ID %d).", npcid);
        }

        return 1;
    }

    if (!strcmp(cmdtext, "/claimnpc", true, 7))
    {
        new npcid = strval(cmdtext[10]);

        if (cmdtext[10] == '\0')
            return SendClientMessage(playerid, 0xFF0000FF, "Usage: /claimnpc [npcid]");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC ID!");

        // Find which player owns this NPC and update it
        new bool:found = false;
        for (new i = 0; i < MAX_PLAYERS; i++)
        {
            if (PlayerNPC[i] == npcid)
            {
                found = true;
                break;
            }
        }

        if (!found)
        {
            // If not owned by anyone, assign to this player
            PlayerNPC[playerid] = npcid;
        }

        SendClientMessage(playerid, 0x00FF00FF, "Now debugging NPC ID %d", npcid);
        return 1;
    }

    // ============================================================
    // NPC COMBAT
    // ============================================================
    if (!strcmp(cmdtext, "/aim", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);

        NPC_AimAt(npcid, x, y, z, false, 0, true, 0.0, 0.0, 0.6, NPC_ENTITY_CHECK_NONE);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is now aiming at your position.", npcid);
        return 1;
    }

    if (!strcmp(cmdtext, "/aimfire", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);

        NPC_AimAt(npcid, x, y, z, true, 800, true, 0.0, 0.0, 0.6, NPC_ENTITY_CHECK_NONE);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is now firing at your position.", npcid);
        return 1;
    }

    if (!strcmp(cmdtext, "/hostile", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        NPC_AimAtPlayer(npcid, playerid, true, 800, true, 0.0, 0.0, 0.8, 0.0, 0.0, 0.6, NPC_ENTITY_CHECK_PLAYER);
        SendClientMessage(playerid, 0xFF0000FF, "NPC %d is now hostile towards you!", npcid);
        return 1;
    }

    if (!strcmp(cmdtext, "/guard", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        NPC_AimAtPlayer(npcid, playerid, false, 0, true, 0.0, 0.0, 0.0, 0.0, 0.0, 0.6, NPC_ENTITY_CHECK_PLAYER);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is now guarding you.", npcid);
        return 1;
    }

    if (!strcmp(cmdtext, "/friendly", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        NPC_StopAim(npcid);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d stopped aiming.", npcid);
        return 1;
    }

    // ============================================================
    // NPC ANIMATION
    // ============================================================
    if (!strcmp(cmdtext, "/applydance", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        NPC_ApplyAnimation(npcid, "DANCING", "dance_loop", 4.1, true, false, false, false, 0);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d has been applied animation.", npcid);
        
        SetTimerEx("ClearNPCAnimations", 25000, false, "ii", playerid, npcid);

        return 1;
    }

    if (!strcmp(cmdtext, "/setdance", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        NPC_SetAnimation(npcid, 405, 4.1, true, false, false, false, 0);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d has been set to animate.", npcid);
        
        SetTimerEx("ClearNPCAnimations", 25000, false, "ii", playerid, npcid);

        return 1;
    }

    if (!strcmp(cmdtext, "/getanim", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You have no NPC.");

        new animid, time;
        new Float:delta;
        new bool:loop, bool:lockX, bool:lockY, bool:freeze;

        if (!NPC_GetAnimation(npcid, animid, delta, loop, lockX, lockY, freeze, time))
            return SendClientMessage(playerid, 0xFF0000FF, "Failed to get animation data (maybe no active animation).");

        SendClientMessage(playerid, 0xFFFFFFFF, "NPC %d animID: %d | delta: %.2f | loop: %d | lockX: %d | lockY: %d | freeze: %d | time: %d",
            npcid, animid, delta, _:loop, _:lockX, _:lockY, _:freeze, time);

        return 1;
    }

    // ============================================================
    // NPC SETTINGS
    // ============================================================
    if (!strcmp(cmdtext, "/toggleinfiniteammo", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        new bool:infinite = NPC_IsInfiniteAmmoEnabled(npcid);
        NPC_EnableInfiniteAmmo(npcid, !infinite);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d infinite ammo: %s", npcid, !infinite ? "Enabled" : "Disabled");

        return 1;
    }

    if (!strcmp(cmdtext, "/togglereload", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        new bool:reload = NPC_IsReloadEnabled(npcid);
        NPC_EnableReloading(npcid, !reload);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d reloading: %s", npcid, !reload ? "Enabled" : "Disabled");

        return 1;
    }

    // ============================================================
    // PATH MANAGEMENT
    // ============================================================
    if (!strcmp(cmdtext, "/createpatrol", true))
    {
        new pathid = NPC_CreatePath();
        PlayerPatrolPath[playerid] = pathid;

        SendClientMessage(playerid, 0x00FF00FF, "Created a patrol path %d", PlayerPatrolPath[playerid]);

        return 1;
    }

    if (!strcmp(cmdtext, "/clearpatrol", true))
    {
        // Get the number of points before clearing
        new count = NPC_GetPathPointCount(PlayerPatrolPath[playerid]);

        // Try to clear the path
        if (NPC_ClearPath(PlayerPatrolPath[playerid]))
        {
            SendClientMessage(playerid, 0x00FF00FF, "Cleared path %d (%d points removed)", PlayerPatrolPath[playerid], count);
        }
        else
        {
            SendClientMessage(playerid, 0xFF0000FF, "Failed to clear path");
        }

        return 1;
    }

    if (!strcmp(cmdtext, "/deletepatrol", true))
    {
        // Check if path is valid first
        if (!NPC_IsValidPath(PlayerPatrolPath[playerid]))
        {
            SendClientMessage(playerid, 0xFF0000FF, "No valid patrol path to delete.");
            return 1;
        }

        // Get how many points were in it
        new count = NPC_GetPathPointCount(PlayerPatrolPath[playerid]);

        // Try to destroy it
        if (NPC_DestroyPath(PlayerPatrolPath[playerid]))
        {
            SendClientMessage(playerid, 0x00FF00FF, "Destroyed path %d (%d points removed).", PlayerPatrolPath[playerid], count);

            // Reset player's path variable since it's now invalid
            PlayerPatrolPath[playerid] = INVALID_PATH_ID;
            StopPlayerPatrolTimer(playerid);
        }
        else
        {
            SendClientMessage(playerid, 0xFF0000FF, "Failed to destroy patrol path.");
        }

        return 1;
    }

    if (!strcmp(cmdtext, "/addpatrolpos", true))
    {
        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);

        // Try to add patrol point
        if (NPC_AddPointToPath(PlayerPatrolPath[playerid], x, y, z, 1.5))
        {
            SendClientMessage(playerid, 0x00FF00FF, "Added point to path %d at your current location", PlayerPatrolPath[playerid]);
        }
        else
        {
            SendClientMessage(playerid, 0xFF0000FF, "Failed add point to path");
        }
        return 1;
    }

    if (!strcmp(cmdtext, "/startpatrol", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        new count = NPC_GetPathPointCount(PlayerPatrolPath[playerid]);

        if (NPC_IsValidPath(PlayerPatrolPath[playerid]))
        {
            NPC_MoveByPath(npcid, PlayerPatrolPath[playerid], NPC_MOVE_TYPE_WALK);
            SendClientMessage(playerid, 0x00FF00FF, "NPC %d started patrol route with %d points", npcid, count);

            StopPlayerPatrolTimer(playerid);
            PlayerPatrolTimer[playerid] = SetTimerEx("CheckPathProgress", 2000, true, "i", playerid);
        }
        else
        {
            SendClientMessage(playerid, 0xFF0000FF, "Failed to start patrol route");
        }
        return 1;
    }

    // ============================================================
    // VEHICLE COMMANDS
    // ============================================================
    if (!strcmp(cmdtext, "/npcenterbike", true, 13))
    {
        new seatid = strval(cmdtext[14]);
        if (cmdtext[14] == '\0')
            return SendClientMessage(playerid, 0xFF0000FF, "Usage: /npcenterbike [seatid]");

        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        new vehicleid = PlayerVehicles[playerid][0];
        if (vehicleid == INVALID_VEHICLE_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "Your motorcycle is not available.");

        if (NPC_EnterVehicle(npcid, vehicleid, seatid, NPC_MOVE_TYPE_JOG))
            SendClientMessage(playerid, 0x00FF00FF, "NPC %d is entering motorcycle (seat %d).", npcid, seatid);
        else
            SendClientMessage(playerid, 0xFF0000FF, "NPC %d failed to enter motorcycle (seat %d).", npcid, seatid);

        return 1;
    }

    if (!strcmp(cmdtext, "/npcentercar", true, 11))
    {
        new seatid = strval(cmdtext[12]);
        if (cmdtext[12] == '\0')
            return SendClientMessage(playerid, 0xFF0000FF, "Usage: /npcentercar [seatid]");

        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        new vehicleid = PlayerVehicles[playerid][1];
        if (vehicleid == INVALID_VEHICLE_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "Your car is not available.");

        if (NPC_EnterVehicle(npcid, vehicleid, seatid, NPC_MOVE_TYPE_JOG))
            SendClientMessage(playerid, 0x00FF00FF, "NPC %d is entering car (seat %d).", npcid, seatid);
        else
            SendClientMessage(playerid, 0xFF0000FF, "NPC %d failed to enter car (seat %d).", npcid, seatid);

        return 1;
    }

    if (!strcmp(cmdtext, "/npcentertrain", true, 14))
    {
        new seatid = strval(cmdtext[15]);
        if (cmdtext[15] == '\0')
            return SendClientMessage(playerid, 0xFF0000FF, "Usage: /npcentertrain [seatid]");

        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        new vehicleid = PlayerVehicles[playerid][2];
        if (vehicleid == INVALID_VEHICLE_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "Your train is not available.");

        if (NPC_EnterVehicle(npcid, vehicleid, seatid, NPC_MOVE_TYPE_JOG))
            SendClientMessage(playerid, 0x00FF00FF, "NPC %d is entering train (seat %d).", npcid, seatid);
        else
            SendClientMessage(playerid, 0xFF0000FF, "NPC %d failed to enter train (seat %d).", npcid, seatid);

        return 1;
    }

    if (!strcmp(cmdtext, "/npcexitbike", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (NPC_ExitVehicle(npcid))
            SendClientMessage(playerid, 0x00FF00FF, "NPC %d is exiting motorcycle.", npcid);
        else
            SendClientMessage(playerid, 0xFF0000FF, "NPC %d failed to exit motorcycle.", npcid);

        return 1;
    }

    if (!strcmp(cmdtext, "/npcexitcar", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (NPC_ExitVehicle(npcid))
            SendClientMessage(playerid, 0x00FF00FF, "NPC %d is exiting car.", npcid);
        else
            SendClientMessage(playerid, 0xFF0000FF, "NPC %d failed to exit car.", npcid);

        return 1;
    }

    if (!strcmp(cmdtext, "/npcexittrain", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (NPC_ExitVehicle(npcid))
            SendClientMessage(playerid, 0x00FF00FF, "NPC %d is exiting train.", npcid);
        else
            SendClientMessage(playerid, 0xFF0000FF, "NPC %d failed to exit train.", npcid);

        return 1;
    }

    // ============================================================
    // NPC INFORMATION
    // ============================================================
    if (!strcmp(cmdtext, "/checkarmour", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new Float:armour = NPC_GetArmour(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d has %.1f% armour", npcid, armour);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkammo", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new ammo = NPC_GetAmmo(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d has %d bullets remaining on total ammo", npcid, ammo);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkclip", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new clip = NPC_GetAmmoInClip(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d has %d bullets remaining on the clip", npcid, clip);
        return 1;
    }

    if (!strcmp(cmdtext, "/countnpcs", true))
    {
        new npcs[MAX_NPCS];
        new count = NPC_GetAll(npcs);

        SendClientMessage(playerid, 0x00FF00FF, "There are %d NPCs on the server.", count);

        return 1;
    }

    if (!strcmp(cmdtext, "/checkenterveh", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        if (!NPC_IsEnteringVehicle(npcid))
            return SendClientMessage(playerid, 0xFFFF00FF, "NPC %d is not entering a vehicle.", npcid);

        new vehicleid = NPC_GetEnteringVehicle(npcid);
        new seatid = NPC_GetEnteringVehicleSeat(npcid);

        if (vehicleid == INVALID_VEHICLE_ID || vehicleid == 0)
            return SendClientMessage(playerid, 0xFFFF00FF, "NPC %d has no pending target vehicle.", npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is entering vehicle %d (seat %d).", npcid, vehicleid, seatid);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkentervehid", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new vehicleid = NPC_GetEnteringVehicleID(npcid);

        if (vehicleid == INVALID_VEHICLE_ID)
            return SendClientMessage(playerid, 0xFFFF00FF, "NPC %d is not entering any vehicle.", npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is entering vehicle ID: %d", npcid, vehicleid);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkentervehseat", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        if (!NPC_IsEnteringVehicle(npcid))
            return SendClientMessage(playerid, 0xFFFF00FF, "NPC %d is not entering any vehicle.", npcid);

        new seatid = NPC_GetEnteringVehicleSeat(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is entering vehicle seat: %d", npcid, seatid);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkfacingangle", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new Float:angle;
        NPC_GetFacingAngle(npcid, angle);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d facing angle: %.2f", npcid, angle);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkfightingstyle", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new style = NPC_GetFightingStyle(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d fighting style: %d", npcid, style);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkhealth", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new Float:health;
        NPC_GetHealth(npcid, health);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d health: %.2f", npcid, health);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkinterior", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new interior = NPC_GetInterior(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d interior: %d", npcid, interior);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkkeys", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new keys, updown, leftright;
        NPC_GetKeys(npcid, keys, updown, leftright);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d keys: %d, updown: %d, leftright: %d", npcid, keys, updown, leftright);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkpathcount", true))
    {
        new count = NPC_GetPathCount();

        SendClientMessage(playerid, 0x00FF00FF, "Total NPC paths: %d", count);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkpathpoint", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new pathid = PlayerPatrolPath[playerid];
        if (pathid == INVALID_PATH_ID)
            return SendClientMessage(playerid, 0xFFFF00FF, "No patrol path assigned.");

        new pointindex = NPC_GetCurrentPathPointIndex(npcid);
        new Float:x, Float:y, Float:z;

        if (!NPC_GetPathPoint(pathid, pointindex, x, y, z))
            return SendClientMessage(playerid, 0xFFFF00FF, "Failed to get path point.");

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d path point %d: %.2f, %.2f, %.2f", npcid, pointindex, x, y, z);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkpathpointcount", true))
    {
        new pathid = PlayerPatrolPath[playerid];
        if (pathid == INVALID_PATH_ID)
            return SendClientMessage(playerid, 0xFFFF00FF, "No patrol path assigned.");

        new count = NPC_GetPathPointCount(pathid);

        SendClientMessage(playerid, 0x00FF00FF, "Path %d has %d points", pathid, count);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkpos", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new Float:x, Float:y, Float:z;
        NPC_GetPos(npcid, x, y, z);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d position: %.2f, %.2f, %.2f", npcid, x, y, z);
        return 1;
    }

    return 0;
}

forward ClearNPCAnimations(playerid, npcid);
public ClearNPCAnimations(playerid, npcid)
{

    NPC_ClearAnimations(npcid);
    SendClientMessage(playerid, 0x00FF00FF, "NPC %d animations were cleared.", npcid);
}

forward CheckPathProgress(playerid);
public CheckPathProgress(playerid)
{
    if (!IsPlayerConnected(playerid))
    {
        StopPlayerPatrolTimer(playerid);
        return 0;
    }

    new npcid = PlayerNPC[playerid];
    if (npcid == INVALID_NPC_ID || !NPC_IsValid(npcid))
    {
        StopPlayerPatrolTimer(playerid);
        return 0;
    }

    if (!NPC_IsValidPath(PlayerPatrolPath[playerid]))
    {
        StopPlayerPatrolTimer(playerid);
        return 0;
    }

    new currentPoint = NPC_GetCurrentPathPointIndex(npcid);
    new totalPoints = NPC_GetPathPointCount(PlayerPatrolPath[playerid]);

    if (currentPoint != INVALID_NODE_ID)
    {
        SendClientMessage(playerid, 0xFFFF00FF, "NPC %d progress: Point %d of %d", npcid, currentPoint + 1, totalPoints);
    }
    return 1;
}
