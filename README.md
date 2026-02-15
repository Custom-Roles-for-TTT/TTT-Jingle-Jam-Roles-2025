# _Custom Roles for TTT_ Roles Pack for Jingle Jam 2025
A pack of [Custom Roles for TTT](https://github.com/Custom-Roles-for-TTT/TTT-Custom-Roles) roles created based on the generous donations of our community members in support of [Jingle Jam 2025](https://www.jinglejam.co.uk/).

# Roles

## ![Role Icon](/gamemodes/terrortown/content/materials/vgui/ttt/roles/chf/tab_chf.png) Chef
_Suggested By_: Sparth\
The Chef is a Special Innocent role that cooks a chosen food for other players which provides a buff (or, if burnt, causes damage).
\
\
**ConVars**
```cpp
ttt_chef_enabled                0   // Whether or not a Chef should spawn
ttt_chef_spawn_weight           1   // The weight assigned to spawning a Chef
ttt_chef_min_players            0   // The minimum number of players required to spawn a Chef
ttt_chef_starting_health        100 // The amount of health a Chef starts with
ttt_chef_max_health             100 // The maximum amount of health a Chef can have
ttt_chef_is_detective           0   // Whether the Chef should be treated as a detective role
ttt_chef_hat_enabled            1   // Whether the Chef gets a hat
ttt_chef_cook_time              30  // How long (in seconds) it takes to cook food
ttt_chef_overcook_time          5   // How long (in seconds) after food is finished cooking before it burns
ttt_chef_damage_own_stove       0   // Whether a stove's owner can damage it
ttt_chef_warn_damage            1   // Whether to warn a stove's owner is warned when it is damaged
ttt_chef_warn_destroy           1   // Whether to warn a stove's owner is warned when it is destroyed
ttt_chef_burger_time            30  // The amount of time the burger effect should last
ttt_chef_burger_amount          0.5 // The percentage of speed boost that the burger eater should get (e.g. 0.5 = 50% speed boost)
ttt_chef_hotdog_time            30  // The amount of time the hot dog effect should last
ttt_chef_hotdog_interval        1   // How often the hot dog eater's health should be restored
ttt_chef_hotdog_amount          1   // The amount of the hot dog eater's health to restore per interval
ttt_chef_fish_time              30  // The amount of time the fish effect should last
ttt_chef_fish_amount            0.5 // The percentage of damage boost that the fish eater should get (e.g. 0.5 = 50% damage boost)
ttt_chef_burnt_time             30  // The amount of time the burnt food effect should last
ttt_chef_burnt_interval         1   // How often the burnt food eater's health should be removed
ttt_chef_burnt_amount           1   // The amount of the burnt food eater's health to remove per interval
ttt_chef_credits_starting       1   // The number of credits a Chef should start with (only used if "ttt_chef_is_detective" is enabled)
ttt_chef_shop_sync              0   // Whether Chefs should have all weapons that vanilla Detectives have in their weapon shop (only used if "ttt_chef_is_detective" is enabled)
ttt_chef_shop_random_percent    0   // The percent chance that a weapon in the shop will not be shown for the Chef (only used if "ttt_chef_is_detective" is enabled)
ttt_chef_shop_random_enabled    0   // Whether shop randomization should run for the Chef (only used if "ttt_chef_is_detective" is enabled)
```

## ![Role Icon](/gamemodes/terrortown/content/materials/vgui/ttt/roles/cln/tab_cln.png) Clone
_Suggested By_: BoboMcGraw\
The Clone is a Jester role that chooses a player to become a clone of and then wins with that player's team.
\
\
**ConVars**
```cpp
ttt_clone_enabled           0   // Whether or not a Clone should spawn
ttt_clone_spawn_weight      1   // The weight assigned to spawning a Clone
ttt_clone_min_players       0   // The minimum number of players required to spawn a Clone
ttt_clone_starting_health   100 // The amount of health a Clone starts with
ttt_clone_max_health        100 // The maximum amount of health a Clone can have
ttt_clone_is_independent    0   // Whether the Clone should be treated as an independent role
ttt_clone_perfect_clone     0   // Whether the Clone copies their target's model perfectly. If "false", some aspect of the clone will be wrong (such as skin, bodygroup, size, etc.)
ttt_clone_target_detectives 0   // Whether the Clone can target detective roles
ttt_clone_minimum_radius    5   // The minimum radius of the Clone's device in meters. Set to 0 to disable
ttt_clone_can_see_jesters   0   // Whether jesters are revealed (via head icons, color/icon on the scoreboard, etc.) to Clones (only used if "ttt_clone_is_independent" is enabled)
ttt_clone_update_scoreboard 0   // Whether Clones show dead players as missing in action (only used if "ttt_clone_is_independent" is enabled)
```

## ![Role Icon](/gamemodes/terrortown/content/materials/vgui/ttt/roles/mgb/tab_mgb.png) Mind Goblin
_Suggested By_: BoboMcGraw\
The Mind Goblin is a Jester role that possesses their killer, but wants to help them win. They can buff their killer and if their killer wins, so does the Mind Goblin.
\
\
**ConVars**
```cpp
ttt_mindgoblin_enabled                0    // Whether or not a Mind Goblin should spawn
ttt_mindgoblin_spawn_weight           1    // The weight assigned to spawning a Mind Goblin
ttt_mindgoblin_min_players            0    // The minimum number of players required to spawn a Mind Goblin
ttt_mindgoblin_starting_health        150  // The amount of health a Mind Goblin starts with
ttt_mindgoblin_max_health             150  // The maximum amount of health a Mind Goblin can have
ttt_mindgoblin_damage_interval        20   // How much damage the Mind Goblin must take between weapon drops
ttt_mindgoblin_announce               1    // Whether to announce to everyone that there is a Mind Goblin in the round
ttt_mindgoblin_dissolve               1    // Whether the Mind Goblin's body should dissolve when they die
ttt_mindgoblin_possess_damage_cost    75   // The amount of power to spend when a Mind Goblin is increasing the damage of their killer via a possession. Set to 0 to disable
ttt_mindgoblin_possess_damage_factor  0.25 // The damage bonus that the target has against other players (e.g. 0.25 = 25% extra damage)
ttt_mindgoblin_possess_damage_length  10   // How long (in seconds) the target's damage boost lasts
ttt_mindgoblin_possess_heal_amount    25   // The amount of health to heal the target for over time when a Mind Goblin uses the heal power
ttt_mindgoblin_possess_heal_cost      50   // The amount of power to spend when a Mind Goblin is healing their killer via a possession. Set to 0 to disable
ttt_mindgoblin_possess_power_max      100  // The maximum amount of power a Mind Goblin can have when possessing their killer
ttt_mindgoblin_possess_power_rate     10   // The amount of power to regain per second when a Mind Goblin is possessing their killer
ttt_mindgoblin_possess_power_starting 0    // The amount of power to the Mind Goblin starts with
ttt_mindgoblin_possess_resist_cost    75   // The amount of power to spend when a Mind Goblin is giving their killer damage resist via a possession. Set to 0 to disable
ttt_mindgoblin_possess_resist_factor  0.25 // The damage resist that the target has against other players (e.g. 0.25 = 25% less damage)
ttt_mindgoblin_possess_resist_length  10   // How long (in seconds) the target's damage resist lasts
ttt_mindgoblin_possess_speed_cost     25   // The amount of power to spend when a Mind Goblin is speeding up their killer attack via a possession. Set to 0 to disable
ttt_mindgoblin_possess_speed_factor   0.5  // The speed boost to give the target (e.g. 0.5 = 50% faster movement)
ttt_mindgoblin_possess_speed_length   10   // How long (in seconds) the target's speed boost lasts
```

## ![Role Icon](/gamemodes/terrortown/content/materials/vgui/ttt/roles/pin/tab_pin.png) Piñata
_Suggested By_: detection.exe\
The Piñata is an Independent role that drops shop weapons on an interval based on how much damage they take. They also cannot damage another player unless they are damaged by them first.
\
\
**ConVars**
```cpp
ttt_pinata_enabled           0   // Whether or not a Piñata should spawn
ttt_pinata_spawn_weight      1   // The weight assigned to spawning a Piñata
ttt_pinata_min_players       0   // The minimum number of players required to spawn a Piñata
ttt_pinata_starting_health   150 // The amount of health a Piñata starts with
ttt_pinata_max_health        150 // The maximum amount of health a Piñata can have
ttt_pinata_damage_interval   20  // How much damage the Piñata must take between weapon drops
ttt_pinata_announce          1   // Whether to announce to everyone that there is a Piñata in the round
ttt_pinata_can_see_jesters   0   // Whether jesters are revealed (via head icons, color/icon on the scoreboard, etc.) to Piñatas
ttt_pinata_update_scoreboard 0   // Whether Piñatas show dead players as missing in action
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

## ![Role Icon](/gamemodes/terrortown/content/materials/vgui/ttt/roles/sfk/tab_sfk.png) Safekeeper
_Suggested By_: Corvatile\
The Sibling is a Independent role that places a safe somewhere on the map that they must defend. If the safe is placed and unopened when the round ends, they win!
\
\
**ConVars**
```cpp
ttt_safekeeper_enabled            0    // Whether or not a Safekeeper should spawn
ttt_safekeeper_spawn_weight       1    // The weight assigned to spawning a Safekeeper
ttt_safekeeper_min_players        0    // The minimum number of players required to spawn a Safekeeper
ttt_safekeeper_starting_health    100  // The amount of health a Safekeeper starts with
ttt_safekeeper_max_health         100  // The maximum amount of health a Safekeeper can have
ttt_safekeeper_warmup_time_min    30   // Minimum time (in seconds) before the Safekeeper will be given their safe
ttt_safekeeper_warmup_time_max    60   // Maximum time (in seconds) before the Safekeeper will be given their safe
ttt_safekeeper_drop_time          15   // How long (in seconds) before the Safekeeper will automatically drop their safe
ttt_safekeeper_pick_grace_time    0.25 // How long (in seconds) before the pick progress of a safe is reset when a player stops looking at it
ttt_safekeeper_pick_time          15   // How long (in seconds) it takes to pick a safe
ttt_safekeeper_warn_pick_start    1    // Whether to warn a safe's owner when someone starts picking it
ttt_safekeeper_warn_pick_complete 1    // Whether to warn a safe's owner when it is picked
ttt_safekeeper_move_safe          1    // Whether an Safekeeper can move their safe
ttt_safekeeper_move_cooldown      30   // How long a Safekeeper must wait after placing their safe before they can move it again
ttt_safekeeper_weapons_dropped    4    // How many weapons the Safekeeper's safe drops when it is picked open
```

**Hooks**
#### TTTSafekeeperSafePicked(placer, opener, safe)
Called when a Safekeeper's safe is picked open\
*Realm:* Server\
*Parameters:*
- *placer* - The Safekeeper who placed the safe
- *opener* - The player who opened the safe
- *safe* - The safe that was picked open

## ![Role Icon](/gamemodes/terrortown/content/materials/vgui/ttt/roles/sib/tab_sib.png) Sibling
_Suggested By_: u/Vitaproficiscar\
The Sibling is a Special Innocent role that is assigned a shop-having target. When their target buys something from the shop, the Sibling gets a copy (and sometimes steals the item entirely).
\
\
**ConVars**
```cpp
ttt_sibling_enabled             0   // Whether or not a Sibling should spawn
ttt_sibling_spawn_weight        1   // The weight assigned to spawning a Sibling
ttt_sibling_min_players         0   // The minimum number of players required to spawn a Sibling
ttt_sibling_starting_health     100 // The amount of health a Sibling starts with
ttt_sibling_max_health          100 // The maximum amount of health a Sibling can have
ttt_sibling_copy_count          1   // How many times the sibling should copy their target's shop purchases. Set to "0" to copy all purchases. Only used when "ttt_sibling_share_mode" is set to a mode that copies
ttt_sibling_share_mode          3   // How to handle the sibling's "share" logic. 1 - Copy the purchased item. 2 - Chance to steal. 3 - Copy the purchased item with a chance to steal
ttt_sibling_steal_chance        0.5 // The chance that a sibling will steal their target's shop purchase instead of copying (e.g. 0.5 = 50% chance to steal). Only used when "ttt_sibling_share_mode" is set to a mode that steals
ttt_sibling_target_detectives   1   // Whether the sibling's target can be a detective role
ttt_sibling_target_independents 1   // Whether the sibling's target can be an independent role
ttt_sibling_target_innocents    1   // Whether the sibling's target can be an innocent role (not including detectives)
ttt_sibling_target_jesters      1   // Whether the sibling's target can be a jester role
ttt_sibling_target_traitors     1   // Whether the sibling's target can be a traitor role
```

## ![Role Icon](/gamemodes/terrortown/content/materials/vgui/ttt/roles/thf/tab_thf.png) Thief
_Suggested By_: Goatylicious\
The Sibling is an Independent role (that can be made into a Special Innocent or Special Traitor) that can only get weapons by stealing from other players.
\
\
**ConVars**
```cpp
ttt_thief_enabled                     0   // Whether or not a Thief should spawn
ttt_thief_spawn_weight                1   // The weight assigned to spawning a Thief
ttt_thief_min_players                 0   // The minimum number of players required to spawn a Thief
ttt_thief_starting_health             100 // The amount of health a Thief starts with
ttt_thief_max_health                  100 // The maximum amount of health a Thief can have
ttt_thief_respawn_health              100 // What amount of health to give the Thief when they are killed and respawned
ttt_thief_is_innocent                 0   // Whether the Thief should be on the innocent team
ttt_thief_is_traitor                  0   // Whether the Thief should be on the traitor team
ttt_thief_steal_cost                  0   // Whether stealing a weapon from a player requires a credit. Enables credit looting for innocent and independent Thieves on new round
ttt_thief_steal_failure_cooldown      3   // How long (in seconds) after the Thief loses their target before they can try to steal another thing
ttt_thief_steal_success_cooldown      30  // How long (in seconds) after the Thief steals something before they can try to steal another thing
ttt_thief_steal_mode                  0   // How stealing a weapon from a player works. 0 - Steal automatically when in proximity. 1 - Steal using their Thieves' Tools
ttt_thief_steal_notify_delay_min      10  // The minimum delay before a player is notified they've been robbed. Set to "0" to disable notifications
ttt_thief_steal_notify_delay_max      30  // The maximum delay before a player is notified they've been robbed
ttt_thief_steal_proximity_distance    5   // How close (in meters) the Thief needs to be to their target to start stealing. Only used when "ttt_thief_steal_mode 0" is set
ttt_thief_steal_proximity_float_time  3   // The amount of time (in seconds) it takes for the Thief to lose their target after getting out of range. Only used when "ttt_thief_steal_mode 0" is set
ttt_thief_steal_proximity_require_los 1   // Whether the Thief requires line-of-sight to steal something. Only used when "ttt_thief_steal_mode 0" is set
ttt_thief_steal_proximity_time        15  // How long (in seconds) it takes the Thief to steal something from a target. Only used when "ttt_thief_steal_mode 0" is set
ttt_thief_can_see_jesters             0   // Whether jesters are revealed (via head icons, color/icon on the scoreboard, etc.) to Thieves (only used if "ttt_thief_is_innocent" and "ttt_thief_is_traitor" are both disabled)
ttt_thief_update_scoreboard           0   // Whether Thieves show dead players as missing in action (only used if "ttt_thief_is_innocent" and "ttt_thief_is_traitor" are both disabled)
ttt_thief_shop_sync                   0   // Whether Thieves should have all weapons that vanilla Traitors have in their weapon shop (only used if "ttt_thief_is_traitor" is enabled and "ttt_thief_is_innocent" is disabled)
```

## ![Role Icon](/gamemodes/terrortown/content/materials/vgui/ttt/roles/ysm/tab_ysm.png) Yorkshireman
_Suggested By_: jambobinator\
_Depends On_: [[TTT] Guard Dog](https://steamcommunity.com/sharedfiles/filedetails/?id=2120419714) and [Tea set props](https://steamcommunity.com/sharedfiles/filedetails/?id=1676060509)\
The Yorkshireman is an Independent role who craves tea and just wants to mind their own business. With their trusty hound and shotgun by their side to ward of any aggressors, they spent their day just meandering around eating pie and trying to keep their tea craving at bay.
\
\
**ConVars**
```cpp
ttt_yorkshireman_enabled             0   // Whether or not a Yorkshireman should spawn
ttt_yorkshireman_spawn_weight        1   // The weight assigned to spawning a Yorkshireman
ttt_yorkshireman_min_players         0   // The minimum number of players required to spawn a Yorkshireman
ttt_yorkshireman_starting_health     100 // The amount of health a Yorkshireman starts with
ttt_yorkshireman_max_health          100 // The maximum amount of health a Yorkshireman can have
```

# Special Thanks
- [Game icons](https://game-icons.net/) for the role icons
- [The Stig](https://steamcommunity.com/id/The-Stig-294) for the code used to shrink imperfect clones
- [avhatar](https://sketchfab.com/avhatar) for the [original model](https://sketchfab.com/3d-models/simple-safe-2e308cb3fe1d4676beb43e75fdd27e8e) for the Safekeeper
  - Licensed as [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- [Famoso](https://steamcommunity.com/profiles/76561198308951372) for the GMod version of the [safe model](https://steamcommunity.com/sharedfiles/filedetails/?id=3030515670) for the Safekeeper
- [GFXSounds.com](https://gfxsounds.com) for the picking and opening sounds used for the Safekeeper's safe
  - [Safe lock, vault, opening mechanism 6](https://gfxsounds.com/sound-effect/safe-lock-vault-opening-mechanism-6/)
  - [Safe vault, dial lock, turning click 6](https://gfxsounds.com/sound-effect/safe-vault-dial-lock-turning-click-6/)
- [THE PIE GUY](https://steamcommunity.com/profiles/76561198082760562) for the [Pie Bomb](https://steamcommunity.com/sharedfiles/filedetails/?id=316765309) whose model is used by the Yorkshireman
