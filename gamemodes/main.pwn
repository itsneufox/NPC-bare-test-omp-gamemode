#include <open.mp>
#include <omp_npc>

main(){}

const INVALID_TIMER_ID = 0;
const DIALOG_HELP = 1000;

new g_NPCCount = 0,
    PlayerNPC[MAX_PLAYERS] = {INVALID_NPC_ID, ...},
    PlayerPatrolPath[MAX_PLAYERS] = {INVALID_PATH_ID, ...};

new PlayerVehicles[MAX_PLAYERS][4]; // [0] = motorcycle, [1] = car, [2] = train, [3] = hydra
new PlayerText:TXD_DEBUG_NPC[MAX_PLAYERS] = {PlayerText:INVALID_TEXT_DRAW, ...};
new PlayerNPCInfoTimer[MAX_PLAYERS] = {INVALID_TIMER_ID, ...};
new PlayerPatrolTimer[MAX_PLAYERS] = {INVALID_TIMER_ID, ...};
new PlayerEnterVehicleMonitor[MAX_PLAYERS] = {INVALID_TIMER_ID, ...};

static const HELP_DIALOG_TEXT_1[] =
    "Command\tDescription\n\
/createnpc\tSpawn armed NPC and start tracking it.\n\
/createunarmednpc\tSpawn an unarmed NPC.\n\
/destroynpc\tDestroy your current NPC.\n\
/respawnnpc\tRespawn your current NPC.\n\
/claimnpc [id]\tAttach debugger to an existing NPC.\n\
/aim, /aimfire\tAim (or fire) at you.\n\
/hostile, /guard\tToggle hostile/guard behaviour.\n\
/friendly\tStop aiming at you.\n\
/applydance, /setdance\tApply preset animations.\n\
/getanim\tInspect current animation state.\n\
/resetanim\tReset NPC animation.\n\
/toggleinfiniteammo\tToggle infinite ammo.\n\
/togglereload\tToggle reloading behaviour.\n\
/toggleinvulnerable\tToggle NPC invulnerability.\n\
/setkeys [k] [ud] [lr]\tSet NPC keys/updown/leftright.\n\
/setweapon [id]\tSet NPC weapon.\n\
/setammo [amount]\tSet NPC total ammo.\n\
/setammoclip [amount]\tSet NPC clip ammo.\n\
/sethealth [amount]\tSet NPC health (0.0-100.0).\n\
/setarmour [amount]\tSet NPC armour (0.0-100.0).\n\
/setfacingangle [angle]\tSet NPC facing angle (0.0-360.0).\n\
/setposhere\tTeleport NPC to your position.\n\
/randomrot\tRandomize NPC rotation.\n\
/setspecialaction [id]\tSet NPC special action.\n\
/setsurfingobject [id]\tSet NPC surfing object.\n\
/setsurfingoffset [x] [y] [z]\tSet NPC surfing offsets.\n\
/setsurfingplayerobject [id]\tSet NPC surfing player object.\n\
/setsurfingvehicle [id]\tSet NPC surfing vehicle.\n\
/setvehiclegearstate [state]\tSet NPC vehicle gear state.\n\
/setvehiclehealth [health]\tSet NPC vehicle health.\n\
/sethydrathrusters [dir]\tSet hydra thrusters direction.\n\
/settrainspeed [speed]\tSet train speed.\n\
/setvelocity [x] [y] [z]\tSet NPC velocity.\n\
/setinterior [id]\tSet NPC interior (0-255).\n\
/setvirtualworld [id]\tSet NPC virtual world.\n\
/setfightingstyle [id]\tSet fighting style (4,5,6,7,15,16).\n\
/setskin [id]\tSet NPC skin (0-311).\n\
/createpatrol\tCreate a new patrol path.\n\
/addpatrolpos\tAdd a patrol point at your position.\n\
/removepatrolpoint [index]\tRemove a point from patrol path.\n\
/startpatrol\tSend NPC along the patrol path.\n\
/npcenterbike [seat]\tPlace NPC into your motorcycle.\n\
/npcentercar [seat]\tPlace NPC into your car.\n\
/npcentertrain [seat]\tPlace NPC into your train.\n\
/npcenterhydra [seat]\tPlace NPC into your hydra.\n\
/npcexit\tForce the NPC to exit any vehicle.";

static const HELP_DIALOG_TEXT_2[] =
    "/checkarmour\tCheck NPC armour.\n\
/checkammo\tCheck NPC total ammo.\n\
/checkclip\tCheck ammo in clip.\n\
/checkenterveh\tMonitor NPC vehicle entry (chat messages).\n\
/stopcheckenterveh\tStop monitoring NPC vehicle entry.\n\
/checkfacingangle\tGet NPC facing angle.\n\
/checkrot\tGet NPC rotation.\n\
/checkvelocity\tGet NPC velocity.\n\
/checkvirtualworld\tGet NPC virtual world.\n\
/checkweapon\tGet NPC weapon.\n\
/checkweaponaccuracy\tGet NPC weapon accuracy.\n\
/checkweaponactualclipsize\tGet NPC weapon actual clip size.\n\
/checkweaponactualreloadtime\tGet NPC weapon actual reload time.\n\
/checkweaponclipsize\tGet NPC weapon clip size.\n\
/checkweaponreloadtime\tGet NPC weapon reload time.\n\
/checkweaponskill\tGet NPC weapon skill levels.\n\
/checkskin\tGet NPC skin ID.\n\
/checkspecialaction\tGet NPC special action.\n\
/checksurfingobject\tGet NPC surfing object.\n\
/checksurfingplayerobject\tGet NPC surfing player object.\n\
/checksurfingvehicle\tGet NPC surfing vehicle.\n\
/checksurfingoffset\tGet NPC surfing offset.\n\
/resetsurfing\tReset NPC surfing data.\n\
/checkvehicle\tGet NPC vehicle.\n\
/checkvehicleid\tGet NPC vehicle ID.\n\
/checkvehicleseat\tGet NPC vehicle seat.\n\
/checkvehicletrainspeed\tGet NPC vehicle train speed.\n\
/checkvehiclegearstate\tGet NPC vehicle gear state.\n\
/checkvehiclehealth\tGet NPC vehicle health.\n\
/checkvehiclehydra\tGet NPC vehicle hydra thrusters.\n\
/checkfightingstyle\tGet NPC fighting style.\n\
/checkhealth\tGet NPC health.\n\
/checkinterior\tGet NPC interior.\n\
/checkkeys\tGet NPC key states.\n\
/checkpathcount\tShow total path count.\n\
/checkpathpoint\tGet current path point coords.\n\
/checkpathpointcount\tGet path point count.\n\
/checkpos\tGet NPC position.\n\
/npcopennode [id]\tOpen a navigation node.\n\
/npcplaynode [id]\tMake NPC follow a node path.\n\
/npcpausenode\tPause NPC node playback.\n\
/npcresumenode\tResume NPC node playback.\n\
/npcsetnodepoint [nid] [pid]\tSet node to specific point.\n\
/createobject\tCreate object (model 1271) for surfing tests.\n\
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

stock StopPlayerEnterVehicleMonitor(playerid)
{
    if (PlayerEnterVehicleMonitor[playerid] != INVALID_TIMER_ID && IsValidTimer(PlayerEnterVehicleMonitor[playerid]))
    {
        KillTimer(PlayerEnterVehicleMonitor[playerid]);
    }
    PlayerEnterVehicleMonitor[playerid] = INVALID_TIMER_ID;
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
    StopPlayerEnterVehicleMonitor(playerid);

    PlayerNPC[playerid] = INVALID_NPC_ID;
    PlayerPatrolPath[playerid] = INVALID_PATH_ID;
    PlayerVehicles[playerid][0] = INVALID_VEHICLE_ID;
    PlayerVehicles[playerid][1] = INVALID_VEHICLE_ID;
    PlayerVehicles[playerid][2] = INVALID_VEHICLE_ID;
    PlayerVehicles[playerid][3] = INVALID_VEHICLE_ID;

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
    PlayerVehicles[playerid][3] = CreateVehicle(520, 2502.2227, -1662.8390, 12.4110, 0.0, 1, 1, -1, false);

    TXD_DEBUG_NPC[playerid] = CreatePlayerTextDraw(playerid, 390.0, 109.0, " ");
    PlayerTextDrawLetterSize(playerid, TXD_DEBUG_NPC[playerid], 0.25, 1.0);
    PlayerTextDrawTextSize(playerid, TXD_DEBUG_NPC[playerid], 610.0, 385.466666);
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
    StopPlayerEnterVehicleMonitor(playerid);

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
    if (PlayerVehicles[playerid][3] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(PlayerVehicles[playerid][3]);
        PlayerVehicles[playerid][3] = INVALID_VEHICLE_ID;
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
    new bool:aimingAtPlayer = NPC_IsAimingAtPlayer(npcid, playerid);
    new bool:invul = NPC_IsInvulnerable(npcid);
    new bool:meleeAttacking = NPC_IsMeleeAttacking(npcid);

    // Movement and vehicle
    new bool:spawned = NPC_IsSpawned(npcid);
    new bool:moving = false;
    new bool:movingToPlayer = false;
    new bool:dead = false;
    new bool:streamedIn = false;
    new bool:enteringVehicle = false;

    if (spawned)
    {
        moving = NPC_IsMoving(npcid);
        movingToPlayer = NPC_IsMovingToPlayer(npcid, playerid);
        dead = NPC_IsDead(npcid);
        streamedIn = NPC_IsStreamedIn(npcid, playerid);
        enteringVehicle = NPC_IsEnteringVehicle(npcid);
    }

    // Playback and nodes
    new bool:playingPlayback = NPC_IsPlayingPlayback(npcid);
    new bool:playbackPaused = NPC_IsPlaybackPaused(npcid);
    new bool:playingNode = NPC_IsPlayingNode(npcid);
    new bool:nodePaused = NPC_IsPlayingNodePaused(npcid);
    new veh = NPC_GetVehicle(npcid);
    new vehSeat = NPC_GetVehicleSeat(npcid);
    new Float:vehHealth = 0.0;
    new bool:sirenUsed = false;
    if (veh != INVALID_VEHICLE_ID)
    {
        vehHealth = NPC_GetVehicleHealth(npcid);
        sirenUsed = NPC_IsVehicleSirenUsed(npcid);
    }

    // Velocity
    new Float:velX, Float:velY, Float:velZ;
    NPC_GetVelocity(npcid, velX, velY, velZ);

    // Rotation
    new Float:rotX, Float:rotY, Float:rotZ;
    NPC_GetRot(npcid, rotX, rotY, rotZ);

    // Other properties
    new skin = NPC_GetSkin(npcid);
    new style = NPC_GetFightingStyle(npcid);
    new action = NPC_GetSpecialAction(npcid);
    new vw = NPC_GetVirtualWorld(npcid);
    new interior = NPC_GetInterior(npcid);

    // Keys
    new updown, leftright, keys;
    NPC_GetKeys(npcid, updown, leftright, keys);

    // Surfing
    new surfVeh = NPC_GetSurfingVehicle(npcid);
    new surfObj = NPC_GetSurfingObject(npcid);
    new surfPObj = NPC_GetSurfingPlayerObject(npcid);

    // Entering vehicle
    new enteringVeh = NPC_GetEnteringVehicleID(npcid);
    new enteringSeat = NPC_GetEnteringVehicleSeat(npcid);

    new text[2048];
    format(text, sizeof(text),
        "~y~NPC DEBUG [ID: %d]~n~\
        ~g~STATS~n~\
        ~w~HP: %.0f ARM: %.0f Skin: %d Dead: %s Spawn: %s Stream: %s~n~\
        ~g~POS~n~\
        ~w~X: %.1f Y: %.1f Z: %.1f~n~\
        ~g~ROT~n~\
        ~w~Angle: %.1f RX: %.1f RY: %.1f RZ: %.1f~n~\
        ~g~VEL~n~\
        ~w~X: %.2f Y: %.2f Z: %.2f~n~\
        ~g~MOVEMENT~n~\
        ~w~Moving: %s ToPlayer: %s VW: %d Int: %d~n~\
        ~y~WEAPON~n~\
        ~w~ID: %d Ammo: %d Clip: %d~n~\
        ~y~RELOAD~n~\
        ~w~Enabled: %s Infinite: %s Reloading: %s~n~\
        ~y~COMBAT~n~\
        ~w~Shoot: %s Aim: %s AimAt: %s Melee: %s Invul: %s~n~\
        ~b~VEHICLE~n~\
        ~w~InVeh: %s Seat: %d HP: %.0f Enter: %s Siren: %s~n~\
        ~b~ENTERING VEH~n~\
        ~w~VehID: %d Seat: %d~n~\
        ~p~PLAYBACK~n~\
        ~w~Playing: %s Paused: %s~n~\
        ~p~NODE~n~\
        ~w~Playing: %s Paused: %s~n~\
        ~p~KEYS~n~\
        ~w~UD: %d LR: %d K: %d~n~\
        ~p~SURFING~n~\
        ~w~Veh: %d Obj: %d PObj: %d~n~\
        ~p~OTHER~n~\
        ~w~Style: %d Action: %d",
        npcid,
        hp, arm, skin, dead ? "Y" : "N", spawned ? "Y" : "N", streamedIn ? "Y" : "N",
        x, y, z,
        angle, rotX, rotY, rotZ,
        velX, velY, velZ,
        moving ? "Y" : "N", movingToPlayer ? "Y" : "N", vw, interior,
        wep, ammo, clip,
        reloadEnabled ? "ON" : "OFF", infAmmo ? "ON" : "OFF", reloading ? "Y" : "N",
        shooting ? "Y" : "N", aiming ? "Y" : "N", aimingAtPlayer ? "Y" : "N", meleeAttacking ? "Y" : "N", invul ? "Y" : "N",
        veh != INVALID_VEHICLE_ID ? "Y" : "N", vehSeat, vehHealth, enteringVehicle ? "Y" : "N", sirenUsed ? "Y" : "N",
        enteringVeh, enteringSeat,
        playingPlayback ? "Y" : "N", playbackPaused ? "Y" : "N",
        playingNode ? "Y" : "N", nodePaused ? "Y" : "N",
        updown, leftright, keys,
        surfVeh, surfObj, surfPObj,
        style, action);

    PlayerTextDrawSetString(playerid, TXD_DEBUG_NPC[playerid], text);
    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!strcmp(cmdtext, "/help", true))
    {
        new helpText[4096];
        strcat(helpText, HELP_DIALOG_TEXT_1);
        strcat(helpText, "\n");
        strcat(helpText, HELP_DIALOG_TEXT_2);
        ShowPlayerDialog(playerid, DIALOG_HELP, DIALOG_STYLE_TABLIST, "NPC Helper Commands", helpText, "", "Close");
        return 1;
    }

    // ============================================================
    // NPC MANAGEMENT
    // ============================================================
    if (!strcmp(cmdtext, "/createobject", true))
    {
        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);

        new objectid = CreateObject(1271, x + 5.0, y, z, 0.0, 0.0, 0.0);
        SendClientMessage(playerid, 0x00FF00FF, "Object %d (model 1271) created near you!", objectid);

        return 1;
    }

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

    if (!strcmp(cmdtext, "/respawnnpc", true))
    {
        new npcid = PlayerNPC[playerid];

        if (!NPC_IsValid(npcid))
        {
            SendClientMessage(playerid, 0xFF0000FF, "You don't have a valid NPC to respawn.");
            return 1;
        }

        if (NPC_Respawn(npcid))
        {
            SendClientMessage(playerid, 0x00FF00FF, "Your NPC (ID %d) has been respawned.", npcid);
        }
        else
        {
            SendClientMessage(playerid, 0xFF0000FF, "Failed to respawn your NPC (ID %d).", npcid);
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

    if (!strcmp(cmdtext, "/resetanim", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        NPC_ResetAnimation(npcid);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d animation has been reset.", npcid);

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

    if (!strcmp(cmdtext, "/setweapon ", true, 11))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new weaponid = strval(cmdtext[11]);
        if (weaponid < 0 || weaponid > 46)
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid weapon ID. Must be between 0 and 46.");

        NPC_SetWeapon(npcid, WEAPON:weaponid);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d weapon set to %d", npcid, weaponid);

        return 1;
    }

    if (!strcmp(cmdtext, "/setammo ", true, 9))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new ammo = strval(cmdtext[9]);
        if (ammo < 0)
            return SendClientMessage(playerid, 0xFF0000FF, "Ammo must be positive.");

        NPC_SetAmmo(npcid, ammo);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d ammo set to %d", npcid, ammo);

        return 1;
    }

    if (!strcmp(cmdtext, "/setammoclip ", true, 13))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new ammo = strval(cmdtext[13]);
        if (ammo < 0)
            return SendClientMessage(playerid, 0xFF0000FF, "Ammo must be positive.");

        NPC_SetAmmoInClip(npcid, ammo);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d clip ammo set to %d", npcid, ammo);

        return 1;
    }

    if (!strcmp(cmdtext, "/sethealth ", true, 11))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new Float:health = floatstr(cmdtext[11]);
        if (health < 0.0 || health > 100.0)
            return SendClientMessage(playerid, 0xFF0000FF, "Health must be between 0.0 and 100.0.");

        NPC_SetHealth(npcid, health);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d health set to %.1f", npcid, health);

        return 1;
    }

    if (!strcmp(cmdtext, "/setarmour ", true, 11))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new Float:armour = floatstr(cmdtext[11]);
        if (armour < 0.0 || armour > 100.0)
            return SendClientMessage(playerid, 0xFF0000FF, "Armour must be between 0.0 and 100.0.");

        NPC_SetArmour(npcid, armour);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d armour set to %.1f", npcid, armour);

        return 1;
    }

    if (!strcmp(cmdtext, "/setfacingangle ", true, 16))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new Float:angle = floatstr(cmdtext[16]);
        if (angle < 0.0 || angle > 360.0)
            return SendClientMessage(playerid, 0xFF0000FF, "Angle must be between 0.0 and 360.0.");

        NPC_SetFacingAngle(npcid, angle);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d facing angle set to %.1f", npcid, angle);

        return 1;
    }

    if (!strcmp(cmdtext, "/setposhere", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);

        NPC_SetPos(npcid, x + 2.0, y, z);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d teleported to your position", npcid);

        return 1;
    }

    if (!strcmp(cmdtext, "/setrandomrot", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new Float:x = float(random(360));
        new Float:y = float(random(360));
        new Float:z = float(random(360));

        NPC_SetRot(npcid, x, y, z);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d rotation randomized", npcid);

        return 1;
    }

    if (!strcmp(cmdtext, "/setspecialaction ", true, 18))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new actionid = strval(cmdtext[18]);

        NPC_SetSpecialAction(npcid, SPECIAL_ACTION:actionid);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d special action set to %d", npcid, actionid);

        return 1;
    }

    if (!strcmp(cmdtext, "/setsurfingobject ", true, 18))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new objectid = strval(cmdtext[18]);

        NPC_SetSurfingObject(npcid, objectid);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d surfing object set to %d", npcid, objectid);

        return 1;
    }

    if (!strcmp(cmdtext, "/setsurfingoffset ", true, 18))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new Float:x, Float:y, Float:z;
        new idx = 18;

        // Parse x
        while (cmdtext[idx] == ' ') idx++;
        new startIdx = idx;
        while (cmdtext[idx] != ' ' && cmdtext[idx] != '\0') idx++;
        new xStr[32];
        strmid(xStr, cmdtext, startIdx, idx);
        x = floatstr(xStr);

        // Parse y
        while (cmdtext[idx] == ' ') idx++;
        startIdx = idx;
        while (cmdtext[idx] != ' ' && cmdtext[idx] != '\0') idx++;
        new yStr[32];
        strmid(yStr, cmdtext, startIdx, idx);
        y = floatstr(yStr);

        // Parse z
        while (cmdtext[idx] == ' ') idx++;
        z = floatstr(cmdtext[idx]);

        NPC_SetSurfingOffsets(npcid, x, y, z);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d surfing offset set to %.2f, %.2f, %.2f", npcid, x, y, z);

        return 1;
    }

    if (!strcmp(cmdtext, "/setsurfingplayerobject ", true, 24))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new objectid = strval(cmdtext[24]);

        NPC_SetSurfingPlayerObject(npcid, objectid);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d surfing player object set to %d", npcid, objectid);

        return 1;
    }

    if (!strcmp(cmdtext, "/setsurfingvehicle ", true, 19))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new vehicleid = strval(cmdtext[19]);

        NPC_SetSurfingVehicle(npcid, vehicleid);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d surfing vehicle set to %d", npcid, vehicleid);

        return 1;
    }

    if (!strcmp(cmdtext, "/setvehiclegearstate ", true, 21))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new gearState = strval(cmdtext[21]);

        NPC_SetVehicleGearState(npcid, gearState);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d vehicle gear state set to %d", npcid, gearState);

        return 1;
    }

    if (!strcmp(cmdtext, "/setvehiclehealth ", true, 18))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new Float:health = floatstr(cmdtext[18]);

        NPC_SetVehicleHealth(npcid, health);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d vehicle health set to %.2f", npcid, health);

        return 1;
    }

    if (!strcmp(cmdtext, "/sethydrathrusters ", true, 19))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new direction = strval(cmdtext[19]);

        NPC_SetVehicleHydraThrusters(npcid, direction);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d hydra thrusters set to %d", npcid, direction);

        return 1;
    }

    if (!strcmp(cmdtext, "/settrainspeed ", true, 15))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new Float:speed = floatstr(cmdtext[15]);

        NPC_SetVehicleTrainSpeed(npcid, speed);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d train speed set to %.2f", npcid, speed);

        return 1;
    }

    if (!strcmp(cmdtext, "/setvelocity ", true, 13))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new Float:x, Float:y, Float:z;
        new idx = 13;

        // Parse x
        while (cmdtext[idx] == ' ') idx++;
        new startIdx = idx;
        while (cmdtext[idx] != ' ' && cmdtext[idx] != '\0') idx++;
        new xStr[32];
        strmid(xStr, cmdtext, startIdx, idx);
        x = floatstr(xStr);

        // Parse y
        while (cmdtext[idx] == ' ') idx++;
        startIdx = idx;
        while (cmdtext[idx] != ' ' && cmdtext[idx] != '\0') idx++;
        new yStr[32];
        strmid(yStr, cmdtext, startIdx, idx);
        y = floatstr(yStr);

        // Parse z
        while (cmdtext[idx] == ' ') idx++;
        z = floatstr(cmdtext[idx]);

        NPC_SetVelocity(npcid, x, y, z);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d velocity set to %.2f, %.2f, %.2f", npcid, x, y, z);

        return 1;
    }

    if (!strcmp(cmdtext, "/toggleinvulnerable", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:invulnerable = NPC_IsInvulnerable(npcid);
        NPC_SetInvulnerable(npcid, !invulnerable);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d invulnerable: %s", npcid, !invulnerable ? "Enabled" : "Disabled");

        return 1;
    }

    if (!strcmp(cmdtext, "/setkeys ", true, 9))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new idx = 9;
        new keys = 0, updown = 0, leftright = 0;

        // Parse keys
        while (cmdtext[idx] == ' ') idx++;
        if (cmdtext[idx] == '\0')
            return SendClientMessage(playerid, 0xFF0000FF, "Usage: /setkeys [keys] [updown] [leftright]");
        keys = strval(cmdtext[idx]);

        // Skip to next parameter
        while (cmdtext[idx] != ' ' && cmdtext[idx] != '\0') idx++;
        while (cmdtext[idx] == ' ') idx++;

        // Parse updown if exists
        if (cmdtext[idx] != '\0')
        {
            updown = strval(cmdtext[idx]);
            while (cmdtext[idx] != ' ' && cmdtext[idx] != '\0') idx++;
            while (cmdtext[idx] == ' ') idx++;

            // Parse leftright if exists
            if (cmdtext[idx] != '\0')
            {
                leftright = strval(cmdtext[idx]);
            }
        }

        NPC_SetKeys(npcid, keys, updown, leftright);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d keys: keys=%d, ud=%d, lr=%d", npcid, keys, updown, leftright);

        return 1;
    }

    if (!strcmp(cmdtext, "/setinterior ", true, 13))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new interiorid = strval(cmdtext[13]);
        if (interiorid < 0 || interiorid > 255)
            return SendClientMessage(playerid, 0xFF0000FF, "Interior ID must be between 0 and 255.");

        NPC_SetInterior(npcid, interiorid);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d interior set to %d", npcid, interiorid);

        return 1;
    }

    if (!strcmp(cmdtext, "/setvirtualworld ", true, 16))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new vw = strval(cmdtext[16]);
        if (vw < 0)
            return SendClientMessage(playerid, 0xFF0000FF, "Virtual world must be positive.");

        NPC_SetVirtualWorld(npcid, vw);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d virtual world set to %d", npcid, vw);

        return 1;
    }

    if (!strcmp(cmdtext, "/setfightingstyle ", true, 18))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new styleid = strval(cmdtext[18]);
        // Valid fighting styles: 4, 5, 6, 7, 15, 16
        if (styleid != 4 && styleid != 5 && styleid != 6 && styleid != 7 && styleid != 15 && styleid != 16)
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid style. Valid: 4(Normal), 5(Boxing), 6(KungFu), 7(KneeHead), 15(GrabKick), 16(Elbow)");

        NPC_SetFightingStyle(npcid, FIGHT_STYLE:styleid);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d fighting style set to %d", npcid, styleid);

        return 1;
    }

    if (!strcmp(cmdtext, "/setskin ", true, 9))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new skinid = strval(cmdtext[9]);
        if (skinid < 0 || skinid > 311)
            return SendClientMessage(playerid, 0xFF0000FF, "Skin ID must be between 0 and 311.");

        NPC_SetSkin(npcid, skinid);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d skin set to %d", npcid, skinid);

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

    if (!strcmp(cmdtext, "/removepatrolpoint ", true, 19))
    {
        if (!NPC_IsValidPath(PlayerPatrolPath[playerid]))
        {
            SendClientMessage(playerid, 0xFF0000FF, "No valid patrol path. Use /createpatrol first.");
            return 1;
        }

        new pointIndex = strval(cmdtext[19]);
        new totalPoints = NPC_GetPathPointCount(PlayerPatrolPath[playerid]);

        if (pointIndex < 0 || pointIndex >= totalPoints)
        {
            SendClientMessage(playerid, 0xFF0000FF, "Invalid point index. Valid range: 0-%d", totalPoints - 1);
            return 1;
        }

        if (NPC_RemovePointFromPath(PlayerPatrolPath[playerid], pointIndex))
        {
            SendClientMessage(playerid, 0x00FF00FF, "Removed point %d from path %d (now has %d points)", pointIndex, PlayerPatrolPath[playerid], totalPoints - 1);
        }
        else
        {
            SendClientMessage(playerid, 0xFF0000FF, "Failed to remove point %d from path", pointIndex);
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

    if (!strcmp(cmdtext, "/npcenterhydra", true, 14))
    {
        new seatid = strval(cmdtext[15]);
        if (cmdtext[15] == '\0')
            return SendClientMessage(playerid, 0xFF0000FF, "Usage: /npcenterhydra [seatid]");

        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        new vehicleid = PlayerVehicles[playerid][3];
        if (vehicleid == INVALID_VEHICLE_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "Your hydra is not available.");

        if (NPC_EnterVehicle(npcid, vehicleid, seatid, NPC_MOVE_TYPE_JOG))
            SendClientMessage(playerid, 0x00FF00FF, "NPC %d is entering hydra (seat %d).", npcid, seatid);
        else
            SendClientMessage(playerid, 0xFF0000FF, "NPC %d failed to enter hydra (seat %d).", npcid, seatid);

        return 1;
    }

    if (!strcmp(cmdtext, "/npcexit", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (NPC_ExitVehicle(npcid))
            SendClientMessage(playerid, 0x00FF00FF, "NPC %d is exiting vehicle.", npcid);
        else
            SendClientMessage(playerid, 0xFF0000FF, "NPC %d failed to exit vehicle.", npcid);

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

        // Start monitoring if not already running
        if (PlayerEnterVehicleMonitor[playerid] == INVALID_TIMER_ID)
        {
            PlayerEnterVehicleMonitor[playerid] = SetTimerEx("CheckNPCEnteringVehicle", 200, true, "i", playerid);
            SendClientMessage(playerid, 0x00FF00FF, "Started monitoring NPC %d vehicle entry.", npcid);
        }
        else
        {
            SendClientMessage(playerid, 0xFFFF00FF, "Already monitoring NPC %d vehicle entry.", npcid);
        }
        return 1;
    }

    if (!strcmp(cmdtext, "/stopcheckenterveh", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        if (PlayerEnterVehicleMonitor[playerid] != INVALID_TIMER_ID)
        {
            StopPlayerEnterVehicleMonitor(playerid);
            SendClientMessage(playerid, 0x00FF00FF, "Stopped monitoring NPC %d vehicle entry.", npcid);
        }
        else
        {
            SendClientMessage(playerid, 0xFFFF00FF, "Not currently monitoring vehicle entry.");
        }
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

    if (!strcmp(cmdtext, "/checkrot", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new Float:rotX, Float:rotY, Float:rotZ;
        NPC_GetRot(npcid, rotX, rotY, rotZ);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d rotation: X=%.2f, Y=%.2f, Z=%.2f", npcid, rotX, rotY, rotZ);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkskin", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new skinid = NPC_GetSkin(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d skin: %d", npcid, skinid);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkspecialaction", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new action = NPC_GetSpecialAction(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d special action: %d", npcid, action);
        return 1;
    }

    if (!strcmp(cmdtext, "/checksurfingobject", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new objectid = NPC_GetSurfingObject(npcid);

        if (objectid == INVALID_OBJECT_ID)
            SendClientMessage(playerid, 0xFFFF00FF, "NPC %d is not surfing on any object.", npcid);
        else
            SendClientMessage(playerid, 0x00FF00FF, "NPC %d is surfing on object: %d", npcid, objectid);
        return 1;
    }

    if (!strcmp(cmdtext, "/checksurfingplayerobject", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new objectid = NPC_GetSurfingPlayerObject(npcid);

        if (objectid == INVALID_OBJECT_ID)
            SendClientMessage(playerid, 0xFFFF00FF, "NPC %d is not surfing on any player object.", npcid);
        else
            SendClientMessage(playerid, 0x00FF00FF, "NPC %d is surfing on player object: %d", npcid, objectid);
        return 1;
    }

    if (!strcmp(cmdtext, "/checksurfingvehicle", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new vehicleid = NPC_GetSurfingVehicle(npcid);

        if (vehicleid == INVALID_VEHICLE_ID)
            SendClientMessage(playerid, 0xFFFF00FF, "NPC %d is not surfing on any vehicle.", npcid);
        else
            SendClientMessage(playerid, 0x00FF00FF, "NPC %d is surfing on vehicle: %d", npcid, vehicleid);
        return 1;
    }

    if (!strcmp(cmdtext, "/checksurfingoffset", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new Float:offsetX, Float:offsetY, Float:offsetZ;
        NPC_GetSurfingOffsets(npcid, offsetX, offsetY, offsetZ);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d surfing offset: X=%.2f, Y=%.2f, Z=%.2f", npcid, offsetX, offsetY, offsetZ);
        return 1;
    }

    if (!strcmp(cmdtext, "/resetsurfing", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        NPC_ResetSurfingData(npcid);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d surfing data has been reset.", npcid);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkvehicle", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new vehicleid = NPC_GetVehicle(npcid);

        if (vehicleid == INVALID_VEHICLE_ID)
            SendClientMessage(playerid, 0xFFFF00FF, "NPC %d is not in any vehicle.", npcid);
        else
            SendClientMessage(playerid, 0x00FF00FF, "NPC %d is in vehicle: %d", npcid, vehicleid);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkvehicleid", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new vehicleid = NPC_GetVehicleID(npcid);

        if (vehicleid == INVALID_VEHICLE_ID)
            SendClientMessage(playerid, 0xFFFF00FF, "NPC %d is not in any vehicle.", npcid);
        else
            SendClientMessage(playerid, 0x00FF00FF, "NPC %d vehicle ID: %d", npcid, vehicleid);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkvehicleseat", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        if (NPC_GetVehicle(npcid) == INVALID_VEHICLE_ID)
            return SendClientMessage(playerid, 0xFFFF00FF, "NPC %d is not in any vehicle.", npcid);

        new seatid = NPC_GetVehicleSeat(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d vehicle seat: %d", npcid, seatid);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkvehicletrainspeed", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        if (NPC_GetVehicle(npcid) == INVALID_VEHICLE_ID)
            return SendClientMessage(playerid, 0xFFFF00FF, "NPC %d is not in any vehicle.", npcid);

        new Float:speed = NPC_GetVehicleTrainSpeed(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d vehicle train speed: %.2f", npcid, speed);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkvelocity", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new Float:velX, Float:velY, Float:velZ;
        NPC_GetVelocity(npcid, velX, velY, velZ);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d velocity: X=%.2f, Y=%.2f, Z=%.2f", npcid, velX, velY, velZ);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkvirtualworld", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new vw = NPC_GetVirtualWorld(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d virtual world: %d", npcid, vw);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkweapon", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new weapon = NPC_GetWeapon(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d weapon: %d", npcid, weapon);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkweaponaccuracy", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new weapon = NPC_GetWeapon(npcid);
        new Float:accuracy = NPC_GetWeaponAccuracy(npcid, WEAPON:weapon);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d weapon %d accuracy: %.2f", npcid, weapon, accuracy);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkweaponactualclipsize", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new weapon = NPC_GetWeapon(npcid);
        new clipsize = NPC_GetWeaponActualClipSize(npcid, WEAPON:weapon);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d weapon actual clip size: %d", npcid, clipsize);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkweaponactualreloadtime", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new weapon = NPC_GetWeapon(npcid);
        new reloadtime = NPC_GetWeaponActualReloadTime(npcid, WEAPON:weapon);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d weapon actual reload time: %d ms", npcid, reloadtime);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkweaponclipsize", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new weapon = NPC_GetWeapon(npcid);
        new clipsize = NPC_GetWeaponClipSize(npcid, WEAPON:weapon);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d weapon clip size: %d", npcid, clipsize);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkweaponreloadtime", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new weapon = NPC_GetWeapon(npcid);
        new reloadtime = NPC_GetWeaponReloadTime(npcid, WEAPON:weapon);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d weapon reload time: %d ms", npcid, reloadtime);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkweaponskill", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new pistol = NPC_GetWeaponSkillLevel(npcid, WEAPONSKILL_PISTOL);
        new silenced = NPC_GetWeaponSkillLevel(npcid, WEAPONSKILL_PISTOL_SILENCED);
        new deagle = NPC_GetWeaponSkillLevel(npcid, WEAPONSKILL_DESERT_EAGLE);
        new shotgun = NPC_GetWeaponSkillLevel(npcid, WEAPONSKILL_SHOTGUN);
        new micro = NPC_GetWeaponSkillLevel(npcid, WEAPONSKILL_MICRO_UZI);
        new mp5 = NPC_GetWeaponSkillLevel(npcid, WEAPONSKILL_MP5);
        new ak47 = NPC_GetWeaponSkillLevel(npcid, WEAPONSKILL_AK47);
        new m4 = NPC_GetWeaponSkillLevel(npcid, WEAPONSKILL_M4);
        new sniper = NPC_GetWeaponSkillLevel(npcid, WEAPONSKILL_SNIPERRIFLE);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d weapon skills:", npcid);
        SendClientMessage(playerid, 0xFFFFFFFF, "Pistol:%d Silenced:%d Deagle:%d Shotgun:%d", pistol, silenced, deagle, shotgun);
        SendClientMessage(playerid, 0xFFFFFFFF, "Micro:%d MP5:%d AK47:%d M4:%d Sniper:%d", micro, mp5, ak47, m4, sniper);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkweaponshoottime", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new weapon = NPC_GetWeapon(npcid);
        new shoottime = NPC_GetWeaponShootTime(npcid, WEAPON:weapon);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d weapon %d shoot time: %d ms", npcid, weapon, shoottime);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkweaponstate", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new weaponstate = NPC_GetWeaponState(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d weapon state: %d", npcid, weaponstate);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkpathpointinrange", true, 22))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new pathid = strval(cmdtext[23]);

        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        new bool:hasPoint = NPC_HasPathPointInRange(pathid, x, y, z, 50.0);

        SendClientMessage(playerid, 0x00FF00FF, "Path %d has point near your position (%.2f, %.2f, %.2f): %s", pathid, x, y, z, hasPoint ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkaiming", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:isAiming = NPC_IsAiming(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is aiming: %s", npcid, isAiming ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkaimingat", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:isAimingAtPlayer = NPC_IsAimingAtPlayer(npcid, playerid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is aiming at you: %s", npcid, isAimingAtPlayer ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkanystreamedin", true))
    {
        new bool:anyStreamed = NPC_IsAnyStreamedIn(playerid);

        SendClientMessage(playerid, 0x00FF00FF, "Any NPCs streamed in for you: %s", anyStreamed ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkdead", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:isDead = NPC_IsDead(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is dead: %s", npcid, isDead ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkenteringvehicle", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:isEntering = NPC_IsEnteringVehicle(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is entering vehicle: %s", npcid, isEntering ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkinfiniteammo", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:infiniteAmmo = NPC_IsInfiniteAmmoEnabled(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d infinite ammo enabled: %s", npcid, infiniteAmmo ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkinvulnerable", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:isInvulnerable = NPC_IsInvulnerable(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is invulnerable: %s", npcid, isInvulnerable ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkmeleeattacking", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:isMeleeAttacking = NPC_IsMeleeAttacking(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is melee attacking: %s", npcid, isMeleeAttacking ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkmoving", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:isMoving = NPC_IsMoving(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is moving: %s", npcid, isMoving ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkmovingtowardme", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:isMovingToPlayer = NPC_IsMovingToPlayer(npcid, playerid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is moving toward you: %s", npcid, isMovingToPlayer ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkplayingplayback", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:isPlayingPlayback = NPC_IsPlayingPlayback(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is playing playback: %s", npcid, isPlayingPlayback ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkplaybackpaused", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:isPlaybackPaused = NPC_IsPlaybackPaused(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d playback paused: %s", npcid, isPlaybackPaused ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checknodeopen", true, 14))
    {
        new nodeid = strval(cmdtext[15]);

        new bool:isNodeOpen = NPC_IsNodeOpen(nodeid);

        SendClientMessage(playerid, 0x00FF00FF, "Node %d is open: %s", nodeid, isNodeOpen ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkplayingnode", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:isPlayingNode = NPC_IsPlayingNode(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is playing node: %s", npcid, isPlayingNode ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checknodepaused", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:isNodePaused = NPC_IsPlayingNodePaused(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d node paused: %s", npcid, isNodePaused ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkreloadenabled", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:isReloadEnabled = NPC_IsReloadEnabled(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d reload enabled: %s", npcid, isReloadEnabled ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkreloading", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:isReloading = NPC_IsReloading(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is reloading: %s", npcid, isReloading ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkshooting", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:isShooting = NPC_IsShooting(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is shooting: %s", npcid, isShooting ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkspawned", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:isSpawned = NPC_IsSpawned(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is spawned: %s", npcid, isSpawned ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkstreamedin", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:isStreamedIn = NPC_IsStreamedIn(npcid, playerid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is streamed in for you: %s", npcid, isStreamedIn ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkvalid", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        new bool:isValid = NPC_IsValid(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is valid: %s", npcid, isValid ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkvalidpath", true, 15))
    {
        new pathid = strval(cmdtext[16]);

        new bool:isValidPath = NPC_IsValidPath(pathid);

        SendClientMessage(playerid, 0x00FF00FF, "Path %d is valid: %s", pathid, isValidPath ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkvalidrecord", true, 17))
    {
        new recordid = strval(cmdtext[18]);

        new bool:isValidRecord = NPC_IsValidRecord(recordid);

        SendClientMessage(playerid, 0x00FF00FF, "Record %d is valid: %s", recordid, isValidRecord ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/checksirenused", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new veh = NPC_GetVehicle(npcid);
        if (veh == INVALID_VEHICLE_ID)
            return SendClientMessage(playerid, 0xFFFF00FF, "NPC %d is not in any vehicle.", npcid);

        new bool:sirenUsed = NPC_IsVehicleSirenUsed(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d vehicle siren used: %s", npcid, sirenUsed ? "Yes" : "No");
        return 1;
    }

    if (!strcmp(cmdtext, "/npckill", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        NPC_Kill(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d has been killed.", npcid);
        return 1;
    }

    if (!strcmp(cmdtext, "/npcloadrecord", true, 14))
    {
        new filepath[128];
        new len = strlen(cmdtext);
        if (len <= 15)
            return SendClientMessage(playerid, 0xFF0000FF, "Usage: /npcloadrecord [filepath]");

        strmid(filepath, cmdtext, 15, len);

        new recordid = NPC_LoadRecord(filepath);

        if (recordid == -1)
            SendClientMessage(playerid, 0xFF0000FF, "Failed to load record from: %s", filepath);
        else
            SendClientMessage(playerid, 0x00FF00FF, "Record loaded from %s with ID: %d", filepath, recordid);
        return 1;
    }

    if (!strcmp(cmdtext, "/npcmeleeattack", true, 15))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new time = 1000;
        if (strlen(cmdtext) > 16)
            time = strval(cmdtext[16]);

        new bool:success = NPC_MeleeAttack(npcid, time, false);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d melee attack for %dms: %s", npcid, time, success ? "Success" : "Failed");
        return 1;
    }

    if (!strcmp(cmdtext, "/npcmove", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);

        NPC_Move(npcid, x, y, z, NPC_MOVE_TYPE_JOG, NPC_MOVE_SPEED_AUTO, 0.2);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d moving to your position (%.2f, %.2f, %.2f)", npcid, x, y, z);
        return 1;
    }

    if (!strcmp(cmdtext, "/npcmovetoplayer", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        NPC_MoveToPlayer(npcid, playerid, NPC_MOVE_TYPE_JOG, NPC_MOVE_SPEED_AUTO, 0.2, 500, false);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d now following you", npcid);
        return 1;
    }

    if (!strcmp(cmdtext, "/npcopennode", true, 12))
    {
        new nodeid = strval(cmdtext[13]);

        if (nodeid < 0 || nodeid > 63)
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid node ID. Must be between 0 and 63.");

        new bool:success = NPC_OpenNode(nodeid);

        SendClientMessage(playerid, 0x00FF00FF, "Open node %d: %s", nodeid, success ? "Success" : "Failed");
        return 1;
    }

    if (!strcmp(cmdtext, "/npcpausenode", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:success = NPC_PausePlayingNode(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d pause node: %s", npcid, success ? "Success" : "Failed");
        return 1;
    }

    if (!strcmp(cmdtext, "/npcresumenode", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new bool:success = NPC_ResumePlayingNode(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d resume node: %s", npcid, success ? "Success" : "Failed");
        return 1;
    }

    if (!strcmp(cmdtext, "/npcsetnodepoint ", true, 17))
    {
        new nodeid = strval(cmdtext[17]);

        if (nodeid < 0 || nodeid > 63)
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid node ID. Must be between 0 and 63.");

        new idx = 17;
        while (cmdtext[idx] != ' ' && cmdtext[idx] != '\0') idx++;
        while (cmdtext[idx] == ' ') idx++;

        if (cmdtext[idx] == '\0')
            return SendClientMessage(playerid, 0xFF0000FF, "Usage: /npcsetnodepoint [nodeid] [pointid]");

        new pointid = strval(cmdtext[idx]);

        new bool:success = NPC_SetNodePoint(nodeid, pointid);

        SendClientMessage(playerid, 0x00FF00FF, "Set node %d to point %d: %s", nodeid, pointid, success ? "Success" : "Failed");
        return 1;
    }

    if (!strcmp(cmdtext, "/npcplaynode", true, 12))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new nodeid = strval(cmdtext[13]);

        if (nodeid < 0 || nodeid > 63)
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid node ID. Must be between 0 and 63.");

        new bool:success = NPC_PlayNode(npcid, nodeid, NPC_MOVE_TYPE_JOG, NPC_MOVE_SPEED_AUTO, 0.0, true);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d play node %d: %s", npcid, nodeid, success ? "Success" : "Failed");
        return 1;
    }

    if (!strcmp(cmdtext, "/npcputinvehicle", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        new vehicleid = GetPlayerVehicleID(playerid);
        if (vehicleid == 0)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not in a vehicle.");

        new bool:success = NPC_PutInVehicle(npcid, vehicleid, 1);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d put in vehicle %d (seat 1): %s", npcid, vehicleid, success ? "Success" : "Failed");
        return 1;
    }

    if (!strcmp(cmdtext, "/checkvehiclegearstate", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        if (NPC_GetVehicle(npcid) == INVALID_VEHICLE_ID)
            return SendClientMessage(playerid, 0xFFFF00FF, "NPC %d is not in any vehicle.", npcid);

        new LANDING_GEAR_STATE:gearState = NPC_GetVehicleGearState(npcid);

        if (gearState == LANDING_GEAR_STATE_UP)
            SendClientMessage(playerid, 0x00FF00FF, "NPC %d: Landing gear UP", npcid);
        else
            SendClientMessage(playerid, 0x00FF00FF, "NPC %d: Landing gear DOWN", npcid);

        return 1;
    }

    if (!strcmp(cmdtext, "/checkvehiclehealth", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        if (NPC_GetVehicle(npcid) == INVALID_VEHICLE_ID)
            return SendClientMessage(playerid, 0xFFFF00FF, "NPC %d is not in any vehicle.", npcid);

        new Float:health = NPC_GetVehicleHealth(npcid);

        SendClientMessage(playerid, 0x00FF00FF, "NPC %d vehicle health: %.2f", npcid, health);
        return 1;
    }

    if (!strcmp(cmdtext, "/checkvehiclehydra", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You are not debugging a NPC.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Invalid NPC.");

        if (NPC_GetVehicle(npcid) == INVALID_VEHICLE_ID)
            return SendClientMessage(playerid, 0xFFFF00FF, "NPC %d is not in any vehicle.", npcid);

        new thrusters = NPC_GetVehicleHydraThrusters(npcid);

        if (thrusters == 0)
            SendClientMessage(playerid, 0x00FF00FF, "NPC %d: Hydra thrusters FORWARD (0)", npcid);
        else
            SendClientMessage(playerid, 0x00FF00FF, "NPC %d: Hydra thrusters BACKWARD (1)", npcid);

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

        new Float:health = NPC_GetHealth(npcid);

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
        new Float:x, Float:y, Float:z, Float:stopRange;

        if (!NPC_GetPathPoint(pathid, pointindex, x, y, z, stopRange))
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

forward CheckNPCEnteringVehicle(playerid);
public CheckNPCEnteringVehicle(playerid)
{
    if (!IsPlayerConnected(playerid))
    {
        StopPlayerEnterVehicleMonitor(playerid);
        return 0;
    }

    new npcid = PlayerNPC[playerid];
    if (npcid == INVALID_NPC_ID || !NPC_IsValid(npcid))
    {
        StopPlayerEnterVehicleMonitor(playerid);
        return 0;
    }

    new bool:isEntering = NPC_IsEnteringVehicle(npcid);

    if (isEntering)
    {
        new vehicleid = NPC_GetEnteringVehicle(npcid);
        new seatid = NPC_GetEnteringVehicleSeat(npcid);

        if (vehicleid != INVALID_VEHICLE_ID && vehicleid != 0)
        {
            SendClientMessage(playerid, 0xFFFF00FF, "NPC %d entering vehicle %d (seat %d)", npcid, vehicleid, seatid);
        }
    }

    return 1;
}
