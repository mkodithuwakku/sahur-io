# Tun Tun Tung Sahur Arena
## Product Specification Document
### Codex-Ready MVP Spec for Godot

Version: 1.0  
Target Engine: Godot 4.x  
Target Platform: Mobile first, with desktop debug support  
Game Type: Multiplayer 3D top-down arena brawler / survival royale  
Primary Inspiration: Brawl Stars camera/view, Slither.io progression loop, simple arcade melee combat

---

# 1. Overview

## 1.1 Game Summary
**Tun Tun Tung Sahur Arena** is a mobile multiplayer 3D top-down action game where players control a stylized bat-wielding character inspired by the meme-style archetype “tun tun tung sahur.” Players spawn into a shared arena and continuously fight in an always-running battle royale style match. The core gameplay loop is simple:

- Move around a top-down 3D arena
- Swing a bat to hit nearby players
- Eliminate opponents
- Grow larger with each kill
- Survive longer and dominate the arena

The game should feel accessible, chaotic, readable, and fast to play on mobile.

## 1.2 Core Fantasy
The player should feel like:
- a funny but dangerous oversized melee fighter
- constantly hunting weaker players while avoiding larger threats
- growing from a vulnerable tiny character into a giant arena menace

## 1.3 MVP Goal
Build a functional online multiplayer mobile prototype in Godot with:
- one arena
- one playable character archetype
- joystick movement
- bat melee attack
- player growth on kills
- continuous drop-in/drop-out arena session
- basic UI
- authoritative multiplayer architecture

---

# 2. Design Pillars

## 2.1 Easy to Understand
Controls and rules should be instantly understandable:
- move
- swing
- hit
- grow
- survive

## 2.2 Short Session Fun
Players should be able to jump in and play immediately without long menus or match setup.

## 2.3 High Readability
The game must remain readable on mobile:
- obvious attack ranges
- clear hit feedback
- clear size differences between players
- minimal UI clutter

## 2.4 Skill Through Positioning
Combat should reward:
- spacing
- timing of swings
- chasing weakened/smaller targets
- avoiding larger players

## 2.5 Scalable MVP
The initial architecture should support future additions like:
- skins
- abilities
- multiple arenas
- AI bots
- leaderboards
- account progression

---

# 3. Target Audience

## 3.1 Intended Players
- mobile arcade players
- casual multiplayer players
- players who enjoy meme aesthetics
- players who like simple but competitive games
- fans of games like Brawl Stars, Agar.io, Slither.io, Surviv.io style progression

## 3.2 Session Length
- typical session: 2–8 minutes
- players can join and leave quickly
- no hard match rounds required in MVP

---

# 4. Platform and Technical Constraints

## 4.1 Primary Platform
- iOS and Android

## 4.2 Secondary Platform
- PC/macOS debug build for development and testing

## 4.3 Engine
- Godot 4.x only

## 4.4 Networking Model
For MVP, use **authoritative dedicated server architecture** if feasible in Godot.  
If a fully dedicated setup is too large for the first pass, structure the code so it can later migrate from host-authoritative to dedicated authoritative.

Preferred direction:
- server owns authoritative game state
- clients send input
- server validates movement and attacks
- server replicates resulting state

---

# 5. Core Gameplay Loop

## 5.1 Loop
1. Player enters the game
2. Player spawns at random safe point in arena
3. Player moves using virtual joystick
4. Player swings bat using attack button
5. If a swing connects, target takes damage/knockback
6. If target dies, attacker gets a kill
7. On kill, attacker grows in size and gains score/power
8. Larger player becomes stronger but easier to spot and target
9. Eliminated player respawns after a short delay
10. Loop repeats continuously

## 5.2 Match Structure
MVP uses a **continuous arena mode**:
- no formal round ending
- no shrinking zone required in MVP
- players continually respawn
- leaderboard shows current dominance
- game world is persistent during server uptime

This preserves the “always-on” feeling similar to Slither.io.

---

# 6. Core Mechanics

## 6.1 Player Movement
### Goals
- smooth, responsive
- easy on touchscreen
- readable direction of facing

### Behavior
- left joystick controls movement direction
- player rotates to face either:
  - movement direction, or
  - attack direction if attacking
- movement is on an XZ plane
- no jumping in MVP
- collision with arena boundaries and obstacles

### Requirements
- movement should feel arcade-like, not realistic
- acceleration should be light; not slippery
- larger players may have slightly reduced speed for balance

### MVP Rule
- base move speed decreases slightly as player size increases

Suggested formula:
- `move_speed = base_speed / (1 + size_penalty_factor * (growth_level - 1))`

This should be configurable in tuning data.

## 6.2 Bat Attack
### Goals
- satisfying melee hit
- short cooldown
- clear range and timing
- simple to replicate over network

### Behavior
- player taps attack button to swing bat
- attack has:
  - startup
  - active hit window
  - recovery/cooldown
- hit is detected in a short cone or arc in front of player
- successful hit applies:
  - damage
  - knockback
  - hit effects

### Attack Design
Recommended MVP values:
- attack range: short
- attack arc: around 70–100 degrees
- cooldown: fast enough to encourage active dueling
- one hit per swing per target

### Server Authority
- server confirms whether a hit occurred
- client can play swing animation immediately for responsiveness
- actual damage outcome comes from server

## 6.3 Health and Elimination
### Behavior
- all players have health
- when health reaches zero, player is eliminated
- attacker receives kill credit if appropriate
- eliminated player disappears or ragdolls briefly, then respawns after delay

### MVP Rule
- simple health model with no healing pickups
- player respawns with base size and full health

Optional future variant:
- partial persistence of progression after death

## 6.4 Growth System
### Purpose
This is the main progression system and should mirror the satisfying “get bigger as you win” loop.

### Behavior
When a player gets a kill:
- growth level increases
- player model scales up
- attack reach may increase slightly
- max health may increase slightly
- move speed decreases slightly
- scoreboard score increases

### Constraints
Growth must not break gameplay readability or collision.

### Rules
- clamp maximum growth
- hitboxes scale in a controlled way
- camera on local player adjusts slightly to accommodate larger size

### Suggested Growth Effects Per Kill
- model scale +X%
- max health +Y%
- attack range +small amount
- movement speed -small amount

These must be tuning variables, not hardcoded assumptions.

## 6.5 Knockback
### Purpose
Adds impact and helps melee combat feel satisfying.

### Behavior
- hit target is pushed away from attacker
- stronger/larger attackers may deal slightly more knockback
- knockback must not stun-lock indefinitely

### MVP Rule
- short impulse only
- no wall stun
- no combo system

## 6.6 Respawn
### Behavior
- on death, player enters short respawn timer
- respawn at random valid spawn point away from nearby threats
- return at base size, full health, zero temporary streak bonuses

### Suggested Respawn UX
- 2–4 second delay
- spectate camera or top-down death view during respawn timer

---

# 7. Camera

## 7.1 Camera Style
The game camera should resemble a **Brawl Stars style top-down/isometric-like view**:
- angled downward
- centered on local player
- fixed tilt
- slightly zoomed out
- camera follows smoothly

## 7.2 Camera Behavior
- follow player with smoothing
- rotate minimally or stay fixed
- avoid disorienting spins
- zoom out slightly as player grows larger

## 7.3 Camera Constraints
- must preserve visibility on mobile
- no manual camera control in MVP
- maintain consistent battlefield awareness

---

# 8. Controls

## 8.1 Mobile Controls
### Left Side
- virtual joystick for movement

### Right Side
- attack button for bat swing

## 8.2 Control Requirements
- joystick should support drag from resting thumb area
- attack button should be large and responsive
- support multitouch
- client prediction for movement should make controls feel immediate

## 8.3 Desktop Debug Controls
For development builds:
- WASD or arrow keys = movement
- mouse or key = attack
- optional mouse-facing debug mode

---

# 9. Arena Design

## 9.1 Arena Goals
- readable
- supports constant encounters
- some navigation variety
- does not block movement too heavily

## 9.2 MVP Arena
One arena only:
- moderate size
- flat ground
- top-down readable materials
- a few obstacles like rocks, pillars, crates, or bushes
- boundary walls or impassable edges

## 9.3 Arena Features
- spawn points around map
- central high-conflict zone
- some safer edge routes
- no vertical platforming in MVP

## 9.4 Obstacles
Obstacles should:
- break line of sight
- create ambush opportunities
- not clutter the arena too much
- have simple collision

---

# 10. Art Direction

## 10.1 Visual Style
Stylized, funny, readable, arcade 3D.

## 10.2 Character Style
The player character should be an original stylized comedic melee fighter inspired by the requested meme energy, but implemented as a simple, readable, bat-carrying top-down brawler character.

### Character Readability Requirements
- exaggerated silhouette
- visible bat
- strong idle stance
- readable from top-down distance
- clear team-color-like tinting or outline system for local vs others if needed

## 10.3 Growth Visuals
As players grow:
- model scale increases
- bat may scale proportionally
- optional VFX burst on growth
- optional subtle material accent/glow for dominant players

## 10.4 Environment Style
- bright enough for readability
- simple geometry
- low-clutter top-down visibility
- optimized for mobile

## 10.5 Animation Requirements
Character:
- idle
- run
- attack swing
- hit react
- death/elimination
- respawn intro optional

Bat:
- attached to hand/bone
- swing animation aligned with hit window

---

# 11. Audio

## 11.1 MVP Audio Requirements
- background music loop
- swing sound
- hit sound
- elimination sound
- growth sound
- UI click sounds

## 11.2 Audio Goals
- comedic, punchy, energetic
- short and readable
- no excessive overlap

---

# 12. Multiplayer Architecture

## 12.1 Preferred Model
Authoritative server model.

## 12.2 Responsibilities
### Client
- capture input
- render local and remote players
- predict immediate local responsiveness where reasonable
- play animations and VFX
- show UI

### Server
- validate player connections
- process movement inputs
- resolve combat
- apply damage
- process eliminations
- assign respawns
- maintain leaderboard
- broadcast authoritative state

## 12.3 Networking Scope for MVP
Must support:
- joining existing arena session
- multiple concurrent players
- synchronized movement
- synchronized attacks
- synchronized health and death
- synchronized growth/scale
- synchronized leaderboard

## 12.4 Anti-Cheat Principles
Basic MVP protections:
- server validates movement speed
- server validates attack rate/cooldown
- server validates hit range
- clients cannot directly set health, kills, or size

## 12.5 Latency Handling
MVP should prioritize playability over perfection:
- client-side movement smoothing
- interpolation for remote players
- local attack animation starts instantly
- server authoritative hit confirmation
- reconciliation hooks left possible for future improvement

---

# 13. Game Systems

## 13.1 Session Flow
### Entry
- open app
- tap play
- connect to arena
- spawn in

### In-Match
- move, attack, eliminate, grow, respawn

### Exit
- leave to menu anytime

## 13.2 Scoring
Track:
- kills
- deaths
- current growth level
- current score
- survival time optional

## 13.3 Leaderboard
Live in-match leaderboard showing:
- player name
- kills or score
- top players only

The leaderboard should update in real time.

## 13.4 Player Identity
MVP:
- guest username generation
- optional editable nickname
- no account system required for first build

Future:
- Google/Apple login
- cosmetics and saved progression

---

# 14. User Interface

## 14.1 MVP Screens
- splash/loading screen
- main menu
- matchmaking/connecting screen
- in-game HUD
- death/respawn overlay
- settings popup

## 14.2 Main Menu
Should include:
- game title
- play button
- name entry field or guest name display
- settings button
- quit button for desktop builds

## 14.3 In-Game HUD
Should include:
- movement joystick
- attack button
- health bar
- kill count or score
- growth level indicator
- mini leaderboard
- respawn timer when dead
- network/ping debug text optional in debug builds

## 14.4 Death Overlay
Should include:
- “You were eliminated”
- killer name if available
- respawn countdown

## 14.5 Settings
MVP settings:
- sound volume
- music volume
- vibration on/off
- graphics quality basic toggle if needed

---

# 15. Core Balance Rules

## 15.1 Intended Risk-Reward
Larger players:
- have more reach
- have more presence
- are more threatening
- may be slightly slower
- become bigger targets

Smaller players:
- are weaker
- are faster
- can outmaneuver larger players
- can swarm or ambush

## 15.2 Balance Objectives
- growth should feel rewarding, not unbeatable
- large players should dominate careless opponents
- skilled small players should still have counterplay
- time-to-kill should remain relatively short and arcade-like

## 15.3 Configurable Tuning Variables
All of these should be data-driven:
- base health
- base move speed
- size growth per kill
- health growth per kill
- speed penalty per growth level
- attack cooldown
- attack range
- attack arc
- damage per swing
- knockback force
- respawn delay
- max size cap

---

# 16. MVP Scope

## 16.1 Included in MVP
- one playable melee character
- one bat attack
- one arena
- mobile touch controls
- multiplayer join/play flow
- health and elimination
- respawn
- growth on kills
- leaderboard
- basic sound and UI
- server-authoritative core gameplay
- desktop debug support

## 16.2 Explicitly Excluded from MVP
- multiple weapons
- ranged attacks
- abilities/supers
- skins/cosmetics
- ranked matchmaking
- parties/friends
- account login
- inventory/shop
- battle pass
- multiple maps
- AI bots unless needed for testing
- advanced monetization
- replay system
- clan/guild systems

---

# 17. Post-MVP Expansion Ideas

- multiple character archetypes
- charge attacks
- dash mechanic
- map hazards
- shrinking arena zone
- collectible buffs or food orbs
- skins and emotes
- persistent progression
- seasonal events
- spectator mode
- bots for empty servers
- region-based matchmaking
- cosmetic bat variants

---

# 18. Technical Architecture

## 18.1 Recommended Project Structure

```text
project/
  scenes/
    main/
      Main.tscn
      MainMenu.tscn
      GameWorld.tscn
    player/
      Player.tscn
      PlayerModel.tscn
      Bat.tscn
    ui/
      HUD.tscn
      Leaderboard.tscn
      RespawnOverlay.tscn
      VirtualJoystick.tscn
      AttackButton.tscn
    arena/
      Arena01.tscn
      SpawnPoint.tscn
      Obstacle_Rock.tscn
      Obstacle_Crate.tscn
    network/
      ServerBootstrap.tscn
  scripts/
    core/
      game_manager.gd
      config.gd
      event_bus.gd
    player/
      player_controller.gd
      player_stats.gd
      player_growth.gd
      player_combat.gd
      player_network.gd
    ui/
      hud.gd
      leaderboard.gd
      virtual_joystick.gd
      respawn_overlay.gd
    network/
      network_manager.gd
      server_game_state.gd
      replication_manager.gd
    arena/
      arena_manager.gd
      spawn_manager.gd
    utils/
      math_utils.gd
      debug_draw.gd
  resources/
    data/
      tuning/
        player_tuning.tres
        combat_tuning.tres
        match_tuning.tres
