# Commands

## NPC Management
- `/spawnnpc` - To test NPC_Create, NPC_Spawn, NPC_SetPos, NPC_SetWeapon, NPC_SetAmmo
- `/setnpc [npcid]` - To test NPC_IsValid

## NPC Combat
- `/aim` - To test NPC_AimAt
- `/aimfire` - To test NPC_AimAt (with firing enabled)
- `/hostile` - To test NPC_AimAtPlayer (with firing enabled)
- `/guard` - To test NPC_AimAtPlayer (without firing)
- `/ceasefire` - To test NPC_StopAim

## NPC Settings
- `/toggleinfiniteammo` - To test NPC_IsInfiniteAmmoEnabled and NPC_EnableInfiniteAmmo
- `/togglereload` - To test NPC_IsReloadEnabled and NPC_EnableReloading

## NPC Animation
- `/dance` - To test NPC_ApplyAnimation and NPC_ClearAnimations
