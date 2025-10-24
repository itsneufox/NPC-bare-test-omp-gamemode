# Commands

## NPC Management
- `/createnpc` - Creates and spawns a new NPC near you (tests NPC_Create, NPC_Spawn, NPC_SetPos, NPC_SetWeapon, NPC_SetAmmo)
- `/destroynpc` - Destroys your current NPC (tests NPC_Destroy)
- `/claimnpc [npcid]` - Claim an NPC by ID for debugging (tests NPC_IsValid)
- `/countnpcs` - Count all NPCs on the server (tests NPC_GetAll)

## NPC Combat
- `/aim` - Make NPC aim at your position without firing (tests NPC_AimAt)
- `/aimfire` - Make NPC aim and fire at your position (tests NPC_AimAt with firing)
- `/hostile` - Make NPC hostile and fire at you (tests NPC_AimAtPlayer with firing enabled)
- `/guard` - Make NPC guard you without firing (tests NPC_AimAtPlayer without firing)
- `/friendly` - Make NPC stop aiming (tests NPC_StopAim)

## NPC Settings
- `/toggleinfiniteammo` - Toggle infinite ammo for your NPC (tests NPC_IsInfiniteAmmoEnabled and NPC_EnableInfiniteAmmo)
- `/togglereload` - Toggle reloading for your NPC (tests NPC_IsReloadEnabled and NPC_EnableReloading)

## NPC Animation
- `/dance` - Make NPC perform dance animation for 10 seconds (tests NPC_ApplyAnimation and NPC_ClearAnimations)

## Path Management
- `/createpatrol` - Create a new patrol path (tests NPC_CreatePath)
- `/clearpatrol` - Clear all points from the current patrol path (tests NPC_ClearPath, NPC_GetPathPointCount)
- `/deletepatrol` - Delete the current patrol path (tests NPC_DestroyPath, NPC_IsValidPath, NPC_GetPathPointCount)
- `/addpatrolpos` - Add your current position to the patrol path (tests NPC_AddPointToPath)
- `/startpatrol` - Make your NPC start following the patrol path (tests NPC_MoveByPath, NPC_IsValidPath, NPC_GetPathPointCount)

## Vehicle Commands
- `/npcenterbike [seatid]` - Make NPC enter the motorcycle at specified seat (tests NPC_EnterVehicle)
- `/npcentercar [seatid]` - Make NPC enter the car at specified seat (tests NPC_EnterVehicle)
- `/npcentertrain [seatid]` - Make NPC enter the train at specified seat (tests NPC_EnterVehicle)
- `/npcexitbike` - Make NPC exit the motorcycle (tests NPC_ExitVehicle)
- `/npcexitcar` - Make NPC exit the car (tests NPC_ExitVehicle)
- `/npcexittrain` - Make NPC exit the train (tests NPC_ExitVehicle)
