# _Custom Roles for TTT_ Roles Pack for Jingle Jam 2025
A pack of [Custom Roles for TTT](https://github.com/Custom-Roles-for-TTT/TTT-Custom-Roles) roles created based on the generous donations of our community members in support of [Jingle Jam 2025](https://www.jinglejam.co.uk/).

# Roles

## ![Role Icon](/gamemodes/terrortown/content/materials/vgui/ttt/roles/sib/tab_sib.png) Sibling
_Suggested By_: u/Vitaproficiscar\
The Sibling is a Special Innocent role that is assigned a shop-having target. When their target buys something from the shop, the Sibling gets a copy (and sometimes steals the item entirely).
\
\
**ConVars**
```cpp
ttt_sibling_enabled                  0   // Whether or not a Sibling should spawn
ttt_sibling_spawn_weight             1   // The weight assigned to spawning a Sibling
ttt_sibling_min_players              0   // The minimum number of players required to spawn a Sibling
ttt_sibling_starting_health          100 // The amount of health a Sibling starts with
ttt_sibling_max_health               100 // The maximum amount of health a Sibling can have
ttt_sibling_respawn_health           100 // What amount of health to give the Sibling when they are killed and respawned
ttt_sibling_copy_count               1   // How many times the sibling should copy their target's shop purchases. Set to "0" to copy all purchases
ttt_sibling_steal_chance             0.5 // The chance that a sibling will steal their target's shop purchase instead of copying (e.g. 0.5 = 50% chance to steal)
ttt_sibling_target_innocents         1   // Whether the sibling's target can be an innocent role (not including detectives)
ttt_sibling_target_detectives        1   // Whether the sibling's target can be a detective role
ttt_sibling_target_traitors          1   // Whether the sibling's target can be a traitor role
ttt_sibling_target_independents      1   // Whether the sibling's target can be an independent role
ttt_sibling_target_jesters           1   // Whether the sibling's target can be a jester role
ttt_sibling_target_monsters          1   // Whether the sibling's target can be a monster role
```

## ![Role Icon](/gamemodes/terrortown/content/materials/vgui/ttt/roles/rsw/tab_rsw.png) Randoswapper
_Suggested By_: CamelChip\
The Randoswapper is a Jester role that swaps roles with their killer and triggers a Randomat event instead of dying.
\
\
**ConVars**
```cpp
ttt_randoswapper_enabled                  0   // Whether or not a Randoswapper should spawn
ttt_randoswapper_spawn_weight             1   // The weight assigned to spawning a Randoswapper
ttt_randoswapper_min_players              0   // The minimum number of players required to spawn a Randoswapper
ttt_randoswapper_starting_health          100 // The amount of health a Randoswapper starts with
ttt_randoswapper_max_health               100 // The maximum amount of health a Randoswapper can have
ttt_randoswapper_respawn_health           100 // What amount of health to give the Randoswapper when they are killed and respawned
ttt_randoswapper_weapon_mode              1   // How to handle weapons when the Randoswapper is killed. 0 - Don't swap anything. 1 - Swap role weapons (if there are any). 2 - Swap all weapons.
ttt_randoswapper_notify_mode              0   // The logic to use when notifying players that a Randoswapper was killed. Killer is notified unless "ttt_randoswapper_notify_killer" is disabled. 0 - Don't notify anyone. 1 - Only notify traitors and detectives. 2 - Only notify traitors. 3 - Only notify detectives. 4 - Notify everyone
ttt_randoswapper_notify_killer            1   // Whether to notify a Randoswapper's killer
ttt_randoswapper_notify_sound             0   // Whether to play a cheering sound when a Randoswapper is killed
ttt_randoswapper_notify_confetti          0   // Whether to throw confetti when a Randoswapper is a killed
ttt_randoswapper_killer_health            100 // The amount of health the Randoswapper's killer should set to. Set to "0" to kill them
ttt_randoswapper_healthstation_reduce_max 1   // Whether the Randoswapper's max health should be reduced to match their current health when using a health station, instead of being healed
ttt_randoswapper_swap_lovers              1   // Whether the Randoswapper should swap lovers with their attacker or not
ttt_randoswapper_max_swaps                5   // The maximum number of times the Randoswapper can swap before they become a regular Swapper. Set to "0" to allow swapping forever
```

# Special Thanks
- [Game icons](https://game-icons.net/) for the role icons
