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
ttt_chef_enabled          0   // Whether or not a Chef should spawn
ttt_chef_spawn_weight     1   // The weight assigned to spawning a Chef
ttt_chef_min_players      0   // The minimum number of players required to spawn a Chef
ttt_chef_starting_health  100 // The amount of health a Chef starts with
ttt_chef_max_health       100 // The maximum amount of health a Chef can have
ttt_chef_hat_enabled      1   // Whether the Chef gets a hat
ttt_chef_cook_time        30  // How long (in seconds) it takes to cook food
ttt_chef_overcook_time    5   // How long (in seconds) after food is finished cooking before it burns
ttt_chef_damage_own_stove 0   // Whether a stove's owner can damage it
ttt_chef_warn_damage      1   // Whether to warn a stove's owner is warned when it is damaged
ttt_chef_warn_destroy     1   // Whether to warn a stove's owner is warned when it is destroyed
ttt_chef_burger_time      30  // The amount of time the burger effect should last
ttt_chef_burger_amount    0.5 // The percentage of speed boost that the burger eater should get (e.g. 0.5 = 50% speed boost)
ttt_chef_hotdog_time      30  // The amount of time the hot dog effect should last
ttt_chef_hotdog_interval  1   // How often the hot dog eater's health should be restored
ttt_chef_hotdog_amount    1   // The amount of the hot dog eater's health to restore per interval
ttt_chef_fish_time        30  // The amount of time the fish effect should last
ttt_chef_fish_amount      0.5 // The percentage of damage boost that the fish eater should get (e.g. 0.5 = 50% damage boost)
ttt_chef_burnt_time       30  // The amount of time the burnt food effect should last
ttt_chef_burnt_interval   1   // How often the burnt food eater's health should be removed
ttt_chef_burnt_amount     1   // The amount of the burnt food eater's health to remove per interval
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
ttt_pinata_enabled         0   // Whether or not a Piñata should spawn
ttt_pinata_spawn_weight    1   // The weight assigned to spawning a Piñata
ttt_pinata_min_players     0   // The minimum number of players required to spawn a Piñata
ttt_pinata_starting_health 150 // The amount of health a Piñata starts with
ttt_pinata_max_health      150 // The maximum amount of health a Piñata can have
ttt_pinata_damage_interval 20  // How much damage the Piñata must take between weapon drops
ttt_pinata_announce        1   // Whether to announce to everyone that there is a Piñata in the round
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

# Special Thanks
- [Game icons](https://game-icons.net/) for the role icons
