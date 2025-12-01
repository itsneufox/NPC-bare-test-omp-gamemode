# Commands

## HELP & UTILITY
- `/help` - Open the in-game dialog that lists every debug command.
- `/countnpcs` - Count all NPCs currently created on the server (tests `NPC_GetAll`).

## NPC LIFECYCLE
- `/createnpc` - Create and spawn an armed NPC near you (tests `NPC_Create`, `NPC_Spawn`, `NPC_SetPos`, `NPC_SetWeapon`, `NPC_SetAmmo`).
- `/createunarmednpc` - Spawn an unarmed NPC at your position (tests `NPC_Create`, `NPC_Spawn`, `NPC_SetPos`).
- `/destroynpc` - Destroy your tracked NPC and free it (tests `NPC_Destroy`).
- `/respawnnpc` - Respawn your tracked NPC without recreating it (tests `NPC_Respawn`).
- `/claimnpc [npcid]` - Take control of an existing NPC by ID for debugging (tests `NPC_IsValid`).
- `/npckill` - Instantly kill your tracked NPC (tests `NPC_Kill`).

## NPC MOVEMENT
- `/npcmove` - Send the NPC to your current location using `NPC_Move`.
- `/npcmovetoplayer` - Make the NPC follow you with `NPC_MoveToPlayer`.
- `/startpatrol` - Start moving along the currently assigned patrol path (tests `NPC_MoveByPath`).

## NPC COMBAT
- `/aim` - Aim the NPC at your position without firing (tests `NPC_AimAt`).
- `/aimfire` - Aim and fire at your position (tests `NPC_AimAt` with firing enabled).
- `/hostile` - Make the NPC aggressively target you (tests `NPC_AimAtPlayer` with firing).
- `/guard` - Have the NPC aim at you without firing (tests `NPC_AimAtPlayer` without firing).
- `/friendly` - Stop the NPC from aiming (tests `NPC_StopAim`).
- `/npcshoot [playerid]` - Make NPC shoot at specified player (tests `NPC_Shoot`).
- `/npcstopmelee` - Stop NPC melee attack (tests `NPC_StopMeleeAttack`).
- `/npcstopmove` - Stop NPC movement (tests `NPC_StopMove`).

## NPC ANIMATION
- `/applydance` - Apply a dance animation for 25 seconds (tests `NPC_ApplyAnimation`, `NPC_ClearAnimations`).
- `/setdance` - Set an animation directly by ID for 25 seconds (tests `NPC_SetAnimation`, `NPC_ClearAnimations`).
- `/getanim` - Inspect the NPC's current animation data (tests `NPC_GetAnimation`).
- `/resetanim` - Clear the current animation (tests `NPC_ResetAnimation`).

## NPC SETTINGS
- `/toggleinfiniteammo` - Toggle infinite ammo on the NPC (tests `NPC_IsInfiniteAmmoEnabled`, `NPC_EnableInfiniteAmmo`).
- `/togglereload` - Toggle whether the NPC reloads (tests `NPC_IsReloadEnabled`, `NPC_EnableReloading`).
- `/toggleinvulnerable` - Toggle NPC invulnerability (tests `NPC_IsInvulnerable`, `NPC_SetInvulnerable`).
- `/setkeys [keys] [updown] [leftright]` - Set NPC key states (tests `NPC_SetKeys`).
- `/setweapon [id]` - Set NPC weapon (tests `NPC_SetWeapon`).
- `/setammo [amount]` - Set NPC total ammo (tests `NPC_SetAmmo`).
- `/setammoclip [amount]` - Set NPC clip ammo (tests `NPC_SetClipAmmo`).
- `/sethealth [amount]` - Set NPC health (tests `NPC_SetHealth`).
- `/setarmour [amount]` - Set NPC armour (tests `NPC_SetArmour`).
- `/setfacingangle [angle]` - Set NPC facing angle (tests `NPC_SetFacingAngle`).
- `/setposhere` - Teleport NPC to your position (tests `NPC_SetPos`).
- `/randomrot` - Randomize NPC rotation (tests `NPC_SetRot`).
- `/setanim [id]` - Set NPC animation by ID (tests `NPC_SetAnimation`).
- `/setspecialaction [id]` - Set NPC special action (tests `NPC_SetSpecialAction`).
- `/setfightingstyle [id]` - Set NPC fighting style (tests `NPC_SetFightingStyle`).
- `/setskin [id]` - Set NPC skin (tests `NPC_SetSkin`).
- `/setvelocity [x] [y] [z]` - Set NPC velocity (tests `NPC_SetVelocity`).
- `/setinterior [id]` - Set NPC interior (tests `NPC_SetInterior`).
- `/setvirtualworld [id]` - Set NPC virtual world (tests `NPC_SetVirtualWorld`).
- `/setweaponaccuracy [accuracy]` - Set NPC weapon accuracy (tests `NPC_SetWeaponAccuracy`).
- `/setweaponclipsize [size]` - Set NPC weapon clip size (tests `NPC_SetWeaponClipSize`).
- `/setweaponreloadtime [ms]` - Set NPC weapon reload time (tests `NPC_SetWeaponReloadTime`).
- `/setweaponskill [type] [level]` - Set NPC weapon skill level (tests `NPC_SetWeaponSkillLevel`).
- `/setweaponshoottime [ms]` - Set NPC weapon shoot time (tests `NPC_SetWeaponShootTime`).
- `/setweaponstate [state]` - Set NPC weapon state (tests `NPC_SetWeaponState`).

## PATH MANAGEMENT
- `/createpatrol` - Create a new patrol path for your NPC (tests `NPC_CreatePath`).
- `/clearpatrol` - Remove every point from the current patrol path (tests `NPC_ClearPath`, `NPC_GetPathPointCount`).
- `/deletepatrol` - Destroy the current patrol path entirely (tests `NPC_DestroyPath`, `NPC_IsValidPath`).
- `/addpatrolpos` - Append your position to the patrol path (tests `NPC_AddPointToPath`).
- `/removepatrolpoint [index]` - Remove a patrol point by index (tests `NPC_RemovePointFromPath`, `NPC_GetPathPointCount`).

## NODE MANAGEMENT
- `/npcopennode [id]` - Open an NPC navigation node for playback (tests `NPC_OpenNode`).
- `/npcplaynode [id]` - Start following a node path (tests `NPC_PlayNode`).
- `/npcpausenode` - Pause the current node playback (tests `NPC_PausePlayingNode`).
- `/npcresumenode` - Resume a paused node playback (tests `NPC_ResumePlayingNode`).
- `/npcsetnodepoint [nodeid] [pointid]` - Set node to a specific point (tests `NPC_SetNodePoint`).
- `/npcstopnode` - Stop NPC node playback (tests `NPC_StopPlayingNode`).
- `/npcclosenode [nodeid]` - Close a navigation node (tests `NPC_CloseNode`).
- `/npcchangenode [nodeid] [linkid]` - Change NPC to different node via link (tests `NPC_ChangeNode`).
- `/npcupdatenodepoint [nodeid] [pointid]` - Update node point position to player's position (tests `NPC_UpdateNodePoint`).

## VEHICLE COMMANDS
- `/npcenterbike [seat]` - Order the NPC into your debug motorcycle (tests `NPC_EnterVehicle`).
- `/npcentercar [seat]` - Order the NPC into your debug car (tests `NPC_EnterVehicle`).
- `/npcentertrain [seat]` - Order the NPC into your debug train (tests `NPC_EnterVehicle`).
- `/npcenterhydra [seat]` - Order the NPC into your debug hydra (tests `NPC_EnterVehicle`).
- `/npcexit` - Force the NPC to exit its current vehicle (tests `NPC_ExitVehicle`).
- `/npcputinvehicle` - Place the NPC into your current vehicle at passenger seat 1 (tests `NPC_PutInVehicle`).
- `/npcremovefromvehicle` - Remove NPC from vehicle (tests `NPC_RemoveFromVehicle`).
- `/setvehiclegearstate [state]` - Set NPC vehicle gear state (tests `NPC_SetVehicleGearState`).
- `/setvehiclehealth [health]` - Set NPC vehicle health (tests `NPC_SetVehicleHealth`).
- `/sethydrathrusters [direction]` - Set hydra thrusters direction (tests `NPC_SetVehicleHydraThrusters`).
- `/settrainspeed [speed]` - Set train speed (tests `NPC_SetVehicleTrainSpeed`).
- `/npcusesiren [use]` - Use vehicle siren (tests `NPC_UseVehicleSiren`).

## SURFING COMMANDS
- `/resetsurfing` - Clear any surfing data on the NPC (tests `NPC_ResetSurfingData`).
- `/setsurfingobject [id]` - Set NPC surfing object (tests `NPC_SetSurfingObject`).
- `/setsurfingoffset [x] [y] [z]` - Set NPC surfing offsets (tests `NPC_SetSurfingOffsets`).
- `/setsurfingplayerobject [id]` - Set NPC surfing player object (tests `NPC_SetSurfingPlayerObject`).
- `/setsurfingvehicle [id]` - Set NPC surfing vehicle (tests `NPC_SetSurfingVehicle`).
- `/createobject` - Create object with model 1271 for surfing tests (tests `CreateObject`).

## CHECK COMMANDS - NPC STATE
- `/checkdead` - Report whether the NPC is dead (`NPC_IsDead`).
- `/checkspawned` - Report whether the NPC is spawned (`NPC_IsSpawned`).
- `/checkvalid` - Report whether the NPC ID is valid (`NPC_IsValid`).
- `/checkstreamedin` - Show if the NPC is streamed in for you (`NPC_IsStreamedIn`).
- `/checkanystreamedin` - Show if any NPCs are streamed in for you (`NPC_IsAnyStreamedIn`).
- `/checkmoving` - Report if the NPC is currently moving (`NPC_IsMoving`).
- `/checkmovingtowardme` - Report if the NPC is moving toward you (`NPC_IsMovingToPlayer`).
- `/checkaiming` - Report if the NPC is aiming (`NPC_IsAiming`).
- `/checkaimingat` - Report if the NPC is aiming at you (`NPC_IsAimingAtPlayer`).
- `/checkshooting` - Report if the NPC is shooting (`NPC_IsShooting`).
- `/checkmeleeattacking` - Report if the NPC is melee attacking (`NPC_IsMeleeAttacking`).
- `/checkinvulnerable` - Report if the NPC is invulnerable (`NPC_IsInvulnerable`).

## CHECK COMMANDS - NPC STATS
- `/checkhealth` - Show the NPC's health (`NPC_GetHealth`).
- `/checkarmour` - Show the NPC's armour (`NPC_GetArmour`).
- `/checkammo` - Show total ammo for the current weapon (`NPC_GetAmmo`).
- `/checkclip` - Show clip ammo for the current weapon (`NPC_GetClipAmmo`).
- `/checkpos` - Show the NPC's coordinates (`NPC_GetPos`).
- `/checkposmovingto` - Show the NPC's target position when moving (`NPC_GetPosMovingTo`).
- `/checkfacingangle` - Show the NPC's facing angle (`NPC_GetFacingAngle`).
- `/checkrot` - Show the NPC's rotation (`NPC_GetRot`).
- `/checkvelocity` - Show the NPC's velocity (`NPC_GetVelocity`).
- `/checkvirtualworld` - Show the NPC's virtual world (`NPC_GetVirtualWorld`).
- `/checkinterior` - Show the NPC's interior ID (`NPC_GetInterior`).
- `/checkkeys` - Show the NPC's key states (`NPC_GetKeys`).
- `/checkskin` - Show the NPC's skin (`NPC_GetSkin`).
- `/checkcustomskin` - Show the NPC's custom skin ID (`NPC_GetCustomSkin`).
- `/checkfightingstyle` - Show the NPC's fighting style (`NPC_GetFightingStyle`).
- `/checkspecialaction` - Show the NPC's special action (`NPC_GetSpecialAction`).
- `/checkinfiniteammo` - Show if infinite ammo is enabled (`NPC_IsInfiniteAmmoEnabled`).
- `/checkreloadenabled` - Show if reloading is enabled (`NPC_IsReloadEnabled`).
- `/checkreloading` - Show if the NPC is actively reloading (`NPC_IsReloading`).
- `/checksurfingobject` - Show the object the NPC is surfing (`NPC_GetSurfingObject`).
- `/checksurfingplayerobject` - Show the player object the NPC is surfing (`NPC_GetSurfingPlayerObject`).
- `/checksurfingvehicle` - Show the vehicle the NPC is surfing (`NPC_GetSurfingVehicle`).
- `/checksurfingoffset` - Show the NPC's surfing offsets (`NPC_GetSurfingOffsets`).

## CHECK COMMANDS - WEAPON
- `/checkweapon` - Show the NPC's current weapon ID (`NPC_GetWeapon`).
- `/checkweaponstate` - Show the NPC's weapon state with descriptive name (`NPC_GetWeaponState`).
- `/checkweaponshoottime` - Show the shoot time for the current weapon (`NPC_GetWeaponShootTime`).
- `/checkweaponaccuracy` - Show the weapon accuracy value (`NPC_GetWeaponAccuracy`).
- `/checkweaponclipsize` - Show the scripted clip size (`NPC_GetWeaponClipSize`).
- `/checkweaponactualclipsize` - Show the actual clip size (`NPC_GetWeaponActualClipSize`).
- `/checkweaponreloadtime` - Show the scripted reload time (`NPC_GetWeaponReloadTime`).
- `/checkweaponactualreloadtime` - Show the actual reload time (`NPC_GetWeaponActualReloadTime`).
- `/checkweaponskill` - Show all weapon skill levels (`NPC_GetWeaponSkillLevel`).
- `/checkwhonpcaiming` - Show which player the NPC is aiming at (`NPC_GetPlayerAimingAt`).
- `/checkwhonpcmoving` - Show which player the NPC is moving to (`NPC_GetPlayerMovingTo`).

## CHECK COMMANDS - VEHICLE
- `/checkvehicle` - Show the vehicle the NPC is in (`NPC_GetVehicle`).
- `/checkvehicleid` - Show the vehicle ID (`NPC_GetVehicleID`).
- `/checkvehicleseat` - Show the seat occupied by the NPC (`NPC_GetVehicleSeat`).
- `/checkvehicletrainspeed` - Show the train speed (`NPC_GetVehicleTrainSpeed`).
- `/checkvehiclegearstate` - Show the landing gear position (`NPC_GetVehicleGearState`).
- `/checkvehiclehealth` - Show the vehicle health (`NPC_GetVehicleHealth`).
- `/checkvehiclehydra` - Show hydra thruster angles (`NPC_GetVehicleHydraThrusters`).
- `/checkenteringvehicle` - Report if the NPC is entering any vehicle (`NPC_IsEnteringVehicle`).
- `/checksirenused` - Report if the NPC is using the vehicle siren (`NPC_IsVehicleSirenUsed`).

## CHECK COMMANDS - ANIMATION
- `/checkplayingplayback` - Report if an animation playback is running (`NPC_IsPlayingPlayback`).
- `/checkplaybackpaused` - Report if the current playback is paused (`NPC_IsPlaybackPaused`).

## CHECK COMMANDS - PATH/NODE
- `/checkpathcount` - Show the number of paths on the server (`NPC_GetPathCount`).
- `/checkpathpoint` - Show the coordinates of the current path point (`NPC_GetPathPoint`).
- `/checkpathpointcount` - Show how many points are in the path (`NPC_GetPathPointCount`).
- `/checkpathpointinrange [pathid]` - Report if a path has points within 50 units of you (`NPC_HasPathPointInRange`).
- `/checkvalidpath [pathid]` - Report if a path ID is valid (`NPC_IsValidPath`).
- `/checkvalidrecord [recordid]` - Report if a playback record is valid (`NPC_IsValidRecord`).
- `/checkplayingnode` - Report if a node playback is active (`NPC_IsPlayingNode`).
- `/checknodepaused` - Report if node playback is paused (`NPC_IsNodePlaybackPaused`).
- `/checknodeopen` - Report if a navigation node is open (`NPC_IsNodeOpen`).
- `/checknodetype [nodeid]` - Get node type (foot/vehicle/boat) (`NPC_GetNodeType`).
- `/checknodepointpos [nodeid] [pointid]` - Get specific node point position (`NPC_GetNodePointPosition`).
- `/checknodepointcount [nodeid]` - Get node point count (`NPC_GetNodePointCount`).
- `/checknodeinfo [nodeid]` - Get comprehensive node info including type and point count (`NPC_GetNodeInfo`).

## MISC COMMANDS
- `/checkenterveh` - Start chat updates about the vehicle your NPC is entering.
- `/stopcheckenterveh` - Stop chat updates from `/checkenterveh`.
- `/npcloadrecord [filepath]` - Load a playback record from disk (`NPC_LoadRecord`).
- `/npcmeleeattack [duration]` - Trigger a melee attack for the given millisecond (`NPC_MeleeAttack`).
- `/startplayback [name]` - Start playback by name (`NPC_StartPlayback`).
- `/startplaybackex [recordid]` - Start playback by record ID (`NPC_StartPlaybackEx`).
- `/stopplayback` - Stop current playback (`NPC_StopPlayback`).
- `/pauseplayback` - Pause or resume current playback (`NPC_PausePlayback`).
- `/checkrecordcount` - Get count of loaded records (`NPC_GetRecordCount`).
- `/npcunloadrecord [recordid]` - Unload specific record (`NPC_UnloadRecord`).
- `/npcunloadallrecords` - Unload all records (`NPC_UnloadAllRecords`).

---

## Screenshots

<p align="center">
  <img src="assets/print1.png" alt="Screenshot 1"><br>
  <em>Motorcycle and car location</em>
</p>

<p align="center">
  <img src="assets/print2.png" alt="Screenshot 2"><br>
  <em>Train location</em>
</p>


