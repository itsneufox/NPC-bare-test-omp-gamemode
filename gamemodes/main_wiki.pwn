#include <open.mp>
#include <omp_npcs>

main(){}

enum PlayerData
{
    PlayerDataNPC,
    PlayerDataVehicle
};

new g_PlayerData[MAX_PLAYERS][PlayerData];

// snippet-start: helper-reset
static stock ResetPlayerData(playerid)
{
    g_PlayerData[playerid][PlayerDataNPC] = INVALID_NPC_ID;
    g_PlayerData[playerid][PlayerDataVehicle] = INVALID_VEHICLE_ID;
}
// snippet-end: helper-reset

// snippet-start: helper-destroy-npc
static stock DestroyPlayerNPC(playerid)
{
    new npcid = g_PlayerData[playerid][PlayerDataNPC];
    if (npcid != INVALID_NPC_ID)
    {
        NPC_Destroy(npcid);
        g_PlayerData[playerid][PlayerDataNPC] = INVALID_NPC_ID;
    }
}
// snippet-end: helper-destroy-npc

// snippet-start: helper-destroy-vehicle
static stock DestroyPlayerVehicle(playerid)
{
    new vehicleid = g_PlayerData[playerid][PlayerDataVehicle];
    if (vehicleid != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(vehicleid);
        g_PlayerData[playerid][PlayerDataVehicle] = INVALID_VEHICLE_ID;
    }
}
// snippet-end: helper-destroy-vehicle

public OnPlayerConnect(playerid)
{
    ResetPlayerData(playerid);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    DestroyPlayerNPC(playerid);
    DestroyPlayerVehicle(playerid);
    ResetPlayerData(playerid);
    return 1;
}

public OnPlayerCommandText(playerid, const cmdtext[])
{
    // snippet-start: npc-create
    if (!strcmp(cmdtext, "/createnpc", true))
    {
        if (g_PlayerData[playerid][PlayerDataNPC] != INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "You already have an NPC.");

        new npcid = NPC_Create("wiki_npc");
        if (npcid == INVALID_NPC_ID || !NPC_Spawn(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "Failed to create NPC.");

        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        NPC_SetPos(npcid, x + 2.0, y, z);

        g_PlayerData[playerid][PlayerDataNPC] = npcid;
        return SendClientMessage(playerid, 0x00FF00FF, "NPC %d created next to you.", npcid);
    }
    // snippet-end: npc-create

    // snippet-start: npc-destroy
    if (!strcmp(cmdtext, "/destroynpc", true))
    {
        if (g_PlayerData[playerid][PlayerDataNPC] == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "No NPC to destroy.");

        DestroyPlayerNPC(playerid);
        return SendClientMessage(playerid, 0x00FF00FF, "Your NPC was destroyed.");
    }
    // snippet-end: npc-destroy

    // snippet-start: vehicle-create
    if (!strcmp(cmdtext, "/createvehicle", true))
    {
        DestroyPlayerVehicle(playerid);

        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        g_PlayerData[playerid][PlayerDataVehicle] = CreateVehicle(411, x + 5.0, y, z, 0.0, 1, 1, -1, false);

        return SendClientMessage(playerid, 0x00FF00FF, "Vehicle %d created nearby.", g_PlayerData[playerid][PlayerDataVehicle]);
    }
    // snippet-end: vehicle-create

    // snippet-start: npc-enter-vehicle
    if (!strcmp(cmdtext, "/npcenter", true))
    {
        new npcid = g_PlayerData[playerid][PlayerDataNPC];
        new vehicleid = g_PlayerData[playerid][PlayerDataVehicle];

        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "Use /createnpc first.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "NPC is not valid.");

        if (vehicleid == INVALID_VEHICLE_ID || !IsValidVehicle(vehicleid))
            return SendClientMessage(playerid, 0xFF0000FF, "Use /createvehicle first.");

        if (NPC_EnterVehicle(npcid, vehicleid, 0, NPC_MOVE_TYPE_JOG))
            return SendClientMessage(playerid, 0x00FF00FF, "NPC %d started entering vehicle %d.", npcid, vehicleid);

        return SendClientMessage(playerid, 0xFF0000FF, "NPC %d failed to enter vehicle %d.", npcid, vehicleid);
    }
    // snippet-end: npc-enter-vehicle

    // snippet-start: npc-get-entering-vehicle
    if (!strcmp(cmdtext, "/npcentering", true))
    {
        new npcid = g_PlayerData[playerid][PlayerDataNPC];

        if (npcid == INVALID_NPC_ID)
            return SendClientMessage(playerid, 0xFF0000FF, "Use /createnpc first.");

        if (!NPC_IsValid(npcid))
            return SendClientMessage(playerid, 0xFF0000FF, "NPC is not valid.");

        if (!NPC_IsEnteringVehicle(npcid))
            return SendClientMessage(playerid, 0xFFFF00FF, "NPC %d is not entering a vehicle.", npcid);

        new vehicleid = NPC_GetEnteringVehicle(npcid);
        new seatid = NPC_GetEnteringVehicleSeat(npcid);

        if (vehicleid == INVALID_VEHICLE_ID || vehicleid == 0)
            return SendClientMessage(playerid, 0xFFFF00FF, "NPC %d has no pending target vehicle.", npcid);

        return SendClientMessage(playerid, 0x00FF00FF, "NPC %d is entering vehicle %d (seat %d).", npcid, vehicleid, seatid);
    }
    // snippet-end: npc-get-entering-vehicle

    return 0;
}
