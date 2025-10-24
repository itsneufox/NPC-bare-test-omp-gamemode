#include <open.mp>
#include <omp_npcs>

main(){}

#define INVALID_NPC_ID (-1)

new g_NPCCount = 0,
    PlayerNPC[MAX_PLAYERS] = {INVALID_NPC_ID, ...};

new Text:TextDraw1;

public OnGameModeInit()
{
    AddPlayerClass(0, 2495.3547, -1688.2319, 13.6774, 351.1646, WEAPON_M4, 500, WEAPON_KNIFE, 1, WEAPON_COLT45, 100);
    AddStaticVehicle(522, 2493.7583, -1683.6482, 12.9099, 270.8069, -1, -1);

    TextDraw1 = TextDrawCreate(444, 109, "initialising npc info...");
    TextDrawLetterSize(TextDraw1, 0.25, 1.0);
    TextDrawTextSize(TextDraw1, 617.0, 385.466666);
    TextDrawAlignment(TextDraw1, TEXT_DRAW_ALIGN_LEFT);
    TextDrawColour(TextDraw1, 0xFFFFFFFF);
    TextDrawUseBox(TextDraw1, true);
    TextDrawBoxColour(TextDraw1, 0x00000088);
    TextDrawSetShadow(TextDraw1, false);
    TextDrawSetOutline(TextDraw1, true);
    TextDrawBackgroundColour(TextDraw1, 0x000000FF);
    TextDrawFont(TextDraw1, TEXT_DRAW_FONT_1);
    TextDrawSetProportional(TextDraw1, true);
    return 1;
}

public OnPlayerConnect(playerid)
{
    PlayerNPC[playerid] = INVALID_NPC_ID;
    TextDrawShowForPlayer(playerid, TextDraw1);
    SetTimerEx("UpdateNPCInfo", 250, true, "i", playerid);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
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
    // Find the latest valid NPC from any player
    new npcid = INVALID_NPC_ID;
    for (new i = MAX_PLAYERS - 1; i >= 0; i--)
    {
        if (PlayerNPC[i] != INVALID_NPC_ID && NPC_IsValid(PlayerNPC[i]))
        {
            npcid = PlayerNPC[i];
            break;
        }
    }
    if (npcid == INVALID_NPC_ID)
    {
        TextDrawSetString(TextDraw1, "~r~No NPC created");
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
    
    TextDrawSetString(TextDraw1, text);
    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!strcmp(cmdtext, "/spawnnpc", true))
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
            NPC_SetAmmo(npcid, 50); // Give 300 ammo

            PlayerNPC[playerid] = npcid;
            SendClientMessage(playerid, 0x00FF00FF, "NPC %s (ID %d) spawned near you!", name, npcid);
        }
        else
        {
            SendClientMessage(playerid, 0xFF0000FF, "Failed to create NPC!");
        }
        return 1;
    }

    if (!strcmp(cmdtext, "/aim", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You have no NPC.");

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
            return SendClientMessage(playerid, 0xFF0000FF, "You have no NPC.");

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
            return SendClientMessage(playerid, 0xFF0000FF, "You have no NPC.");

        NPC_AimAtPlayer(npcid, playerid, true, 800, true, 0.0, 0.0, 0.8, 0.0, 0.0, 0.6, NPC_ENTITY_CHECK_PLAYER);
        SendClientMessage(playerid, 0xFF0000FF, "NPC %d is now hostile towards you!", npcid);
        return 1;
    }

    if (!strcmp(cmdtext, "/guard", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You have no NPC.");

        NPC_AimAtPlayer(npcid, playerid, false, 0, true, 0.0, 0.0, 0.0, 0.0, 0.0, 0.6, NPC_ENTITY_CHECK_PLAYER);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is now guarding you.", npcid);
        return 1;
    }

    if (!strcmp(cmdtext, "/ceasefire", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You have no NPC.");

        NPC_StopAim(npcid);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d stopped aiming.", npcid);
        return 1;
    }

    if (!strcmp(cmdtext, "/dance", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You have no NPC.");

        NPC_ApplyAnimation(npcid, "DANCING", "dance_loop", 4.1, true, false, false, false, 0);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d is now animating.", npcid);
        
        SetTimerEx("ClearNPCAnimations", 10000, false, "ii", playerid, npcid);
        
        return 1;
    }

    if (!strcmp(cmdtext, "/toggleinfiniteammo", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You have no NPC.");

        new bool:infinite = NPC_IsInfiniteAmmoEnabled(npcid);
        NPC_EnableInfiniteAmmo(npcid, !infinite);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d infinite ammo: %s", npcid, !infinite ? "Enabled" : "Disabled");

        return 1;
    }

    if (!strcmp(cmdtext, "/togglereload", true))
    {
        new npcid = PlayerNPC[playerid];
        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You have no NPC.");

        new bool:reload = NPC_IsReloadEnabled(npcid);
        NPC_EnableReloading(npcid, !reload);
        SendClientMessage(playerid, 0x00FF00FF, "NPC %d reloading: %s", npcid, !reload ? "Enabled" : "Disabled");

        return 1;
    }

    if (!strcmp(cmdtext, "/setnpc", true, 7))
    {
        new npcid = strval(cmdtext[8]);

        if (cmdtext[8] == '\0')
            return SendClientMessage(playerid, 0xFF0000FF, "Usage: /setnpc [npcid]");

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

    return 0;
}

forward ClearNPCAnimations(playerid, npcid);
public ClearNPCAnimations(playerid, npcid)
{
    
    NPC_ClearAnimations(npcid);
    SendClientMessage(playerid, 0x00FF00FF, "NPC %d animations were cleared.", npcid);
}
