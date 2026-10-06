# Iron / Echo — parry combat prototype

Installed in Roblox Studio's **2MG**. The place uses each player's default R15 Roblox avatar and a standard R15 training partner.

## Play

| Input | Action |
|---|---|
| WASD | Move |
| Left mouse | Four distinct light swings; fourth hit pushes the opponent back |
| F | Tap to parry; hold to block |
| Q + movement | Directional dodge; stationary Q dodges backward |
| R or middle mouse | Critical attack: red glow and guaranteed frontal block break |
| Right mouse during light windup | Feint |
| Right mouse during dodge | Roll cancel |
| T | Cycle Passive → Block → Parry drill → Sparring |
| G | Restore health/posture and reset both positions |
| X | Toggle target lock |

Walk toward the partner before attacking. Use Passive to learn attack animations, Block to test posture pressure, Parry drill to practice incoming strikes, and Sparring for an opponent that approaches, attacks, feints, and sometimes parries. The partner resets after defeat; players respawn normally. Resetting practice keeps session counters.

## Reference analysis and design

The reference was the public [Deepwoken combat mechanics documentation](https://deepwoken.fandom.com/wiki/Combat_Mechanics) and its indexed combat descriptions, consulted October 6, 2026. The design takes its attack/parry/counterattack rhythm, held guard after the initial parry, posture pressure, light-attack feints, directional dodges and roll cancellation as reference. This is an independent prototype with original geometry and procedural animations. It does not use Deepwoken's source code or animation assets, and does not claim to reproduce its exact current balance.

The core interaction is a readable windup followed by a committed active strike. M1 damage starts at the late contact pose, 0.46 seconds after input, following the visible swing beginning at 0.27 seconds. The finisher contacts at 0.53 seconds and pushes an unguarded opponent about 8 studs away. Its longer recovery prevents immediate continuation at close range. The fifth attack restarts at swing one. Blocking, parrying or dodging the fourth hit prevents its push.

A timed parry negates damage, adds attacker posture and briefly interrupts the attacker. Successful parries refresh the defender's cooldown. Holding F after the parry window raises a frontal guard, which trades posture for protection. Feints are allowed in the preparation phase, before the committed cut. Critical attacks commit once started and always break an ordinary frontal block, even at zero accumulated posture. The red body highlight and sword light remain visible through the critical's windup and contact. Crits remain parryable and dodgeable.

The current animation pass uses the user's raised one-handed guard image and two supplied combat clips. The hilt rests low and to the right, the blade points upward and forward, and its sharpened edge faces the opponent. The right shoulder, elbow and wrist move independently of the torso through a two-bone arm solver; the left arm counterbalances wide cuts. Each M1 has a wide chamber, accelerating strike, late contact and full follow-through: descending forehand, rising backhand, horizontal cross-body cut, then an overhead finisher. Torso rotation, lean, hips and the independent arm motion carry the stroke. The sword's local X cutting edge follows the blade-tip motion rather than presenting the broad flat of the blade. The four active swing paths measure 6.54 to 9.54 studs at the tip. The parry uses its own rapid crossing lift and outward deflection before settling into a held block; a successful clash flashes gold at the blade.

Server hit detection samples the same weapon curves, sweeping the sharpened blade from 1.15 to 3.76 studs below the hilt with a 1.45-stud character contact allowance. The grip, guard and blunt ricasso are excluded from the sampled blade segment. Local prediction and server hit detection use the same attack profile. Canceling a roll stops its movement and removes its invulnerability; a brief recovery allows another action. Defensive parries become available during the latter part of hit stun to avoid uninterrupted light chains.

## Tune

Edit `ReplicatedStorage.ParryCombat.Config` in Studio. The local equivalent is `CombatConfig.lua`.

| Setting | Initial value |
|---|---|
| Light contact / active / recovery | 0.46 / 0.09 / 0.21 seconds |
| Fourth-hit contact / active / recovery | 0.53 / 0.10 / 0.38 seconds |
| Critical contact / active / recovery | 0.72 / 0.12 / 0.42 seconds |
| Parry window / missed cooldown | 0.26 / 1.15 seconds |
| Dodge duration / invulnerability | 0.48 / 0.26 seconds |
| Dodge cooldown | 1.05 seconds |
| Earliest roll cancel / recovery | 0.09 / 0.08 seconds |
| Light / finisher / critical damage | 12 / 16 / 24 |
| Light / finisher block posture | 25 / 32 |
| Critical block effect | Always breaks frontal block; 30% chip damage |
| Guard break threshold | 100 posture |

## Source layout

- `CombatConfig.lua`: shared timings and combat values.
- `CombatAnimations.lua`: R15 one-handed guard, four broad M1 pose curves, arm solver and critical animation.
- `CombatService.lua`: server state machine, hit detection, damage, posture and opponent behavior.
- `CombatServer.server.lua`: registration, weapons, remote input validation and training controls.
- `CombatClient.client.lua`: inputs, prediction, R15 joint animation, effects, camera and HUD.
- `InstallArena.lua`: creates the training arena and initial prototype objects in Edit mode.
- `RefineAssets.lua`: replaces the initial sword with the refined model.
- `InstallDefaultAvatar.lua`: removes the custom StarterCharacter and creates a standard R15 training partner.
- `InstallCombat.command.lua`: complete generated installer. Paste its contents into Studio's Command Bar in Edit mode to reinstall the prototype in an empty place. It replaces this prototype's named objects, StarterCharacter, and applies its lighting/spawn setup.
- `PlaytestCombat.lua`: live integration checks; execute on the server during a Studio playtest. Temporary fighters are cleaned up afterward.
- `PlaytestAnimations.lua`: client-side forward-kinematics checks for the raised guard, arm reach, swing size and edge alignment.
- `InstallRefinement.command.lua`: applies the current scripts and asset refinements to an existing prototype arena in Edit mode.
- `BuildInstaller.ps1`: regenerates both installer files from the editable Lua sources.
- `backups/v1-studio-sources.json`: original installed scripts captured before the refinement.
- `backups/v2-animations.lua`: previous animation curves, before the reference guard and edge-leading cuts.

Studio locations: `ServerScriptService.CombatService`, `ServerScriptService.CombatServer`, `StarterPlayer.StarterPlayerScripts.CombatClient`, `ReplicatedStorage.ParryCombat`, and `Workspace.ParryArena`.

## Validation

The combat scripts started without runtime errors. The HUD, target camera, all four M1 poses, articulated joints, and sword closeup were visually inspected. The critical's red highlight and weapon light were verified during a live attack. All three audio assets loaded successfully, and their playback and advancing audio positions were verified during actual hit, block and parry outcomes.

All 23 live server integration checks passed, covering late M1 contact, damage, feints, committed heavies, parries and cooldown refresh, early parry punishment, block posture, zero-posture critical guard break, critical parry, dodge protection, roll cancellation, cooldowns, recovery, range, walls, four-step chain order, finisher damage, chain reset and physical knockback. The measured fourth-hit push was 8.32 studs; a blocked finisher caused no push.

A subsequent four-click input test in the running game confirmed the 1 → 2 → 3 → 4 order, four hits for 52 total damage, and approximately 13 studs of separation after the finisher. Temporary QA scripts, preview models, camera overrides and listeners were removed afterward.

The R15 revision was installed in 2MG. The default player and training partner both spawned with R15 joints and equipped the sword. All 23 mechanic checks passed again, including late M1 contact, parry, critical guard break and finisher knockback. Six animation checks passed using forward kinematics of the actual R15 shoulder, elbow and wrist: raised guard, parry deflection and all four broad, edge-leading cuts. The weakest cutting-edge/tangential-motion alignment was above 0.998 (1.0 is exact), and the measured sword-path error was under 0.000005 studs. A live first swing dealt damage only after the original late contact timing.

## Audio

Three distinct spatial effects play on confirmed server combat outcomes. Block audio is pitched down and muffled; parry audio is brighter. Small pitch variations reduce repetition. These are free Creator Store source sounds, configured for this combat system:

- [Sword Hit (Impact), BushSeed](https://create.roblox.com/store/asset/7171761940)
- [Sword parry / clash, Schnogrind](https://create.roblox.com/store/asset/5763723309)
- [Metal Block Impact, DevSnek's UGC](https://create.roblox.com/store/asset/87182755732271)

Sound IDs, volumes and playback speeds are editable under `Config.Sounds`.

This version targets desktop keyboard/mouse and standard R15 avatars. High-latency multiplayer behavior and mobile/gamepad controls have not been tested. Procedural poses run locally for all tagged fighters using replicated action states; they require no animation uploads. Hit detection uses a server-side blade sweep, range prefilter and line-of-sight check. The GUI training mode is shared between players in a server.

Local Lua files are backups, not an automatic live sync. The installed Studio changes persist when you stop the playtest, but save the place through Studio to keep a `.rbxl` copy.
