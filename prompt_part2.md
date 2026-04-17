## 18.2 Scene Responsibilities

### Main
Bootstraps the app, main menu flow, networking initialization, and transitions into the game world.

### GameWorld
Owns:
- arena instance
- player instances
- match state hooks
- world-level replication hooks
- UI attachment point

### Player
Contains:
- movement component
- combat component
- growth/stat component
- visuals
- collision
- networking hooks

### HUD
Displays:
- touch controls
- health
- kill count
- growth level
- leaderboard
- respawn UI

---

# 19. Data Model

## 19.1 Player State
Each player should track at least:
- unique network id
- display name
- position
- facing direction
- velocity
- current health
- max health
- alive/dead state
- growth level
- scale multiplier
- kills
- deaths
- attack cooldown state
- respawn timer state

## 19.2 Match State
The match should track:
- connected players
- scoreboard entries
- spawn point registry
- arena bounds
- server tick or update timing
- optional session uptime

## 19.3 Tuning Data
All gameplay constants should live in configurable resources or data assets where practical.

Examples:
- base health
- base move speed
- attack cooldown
- damage
- knockback force
- scale growth per kill
- speed penalty per growth level
- respawn delay
- camera zoom rules

---

# 20. Networking Specification

## 20.1 Network Entities
Replicated entities and state include:
- players
- player transforms
- facing direction
- health changes
- attack events
- elimination events
- respawn events
- growth updates
- leaderboard updates

## 20.2 Client Input Messages
Clients send:
- movement vector
- attack pressed event
- optional sequence number or timestamp for reconciliation

## 20.3 Server State Updates
Server broadcasts:
- authoritative transforms
- health values
- alive/dead states
- kill events
- growth levels
- leaderboard changes

## 20.4 Smoothing
Remote players should be:
- interpolated between snapshots
- snapped only on severe desync

Local player may use:
- immediate input response
- prediction where practical
- reconciliation when corrected by server

---

# 21. Combat Specification

## 21.1 Attack Flow
1. Player presses attack.
2. Client checks local cooldown for immediate responsiveness.
3. Client plays swing animation immediately.
4. Client sends attack request to server.
5. Server validates:
   - player is alive
   - cooldown is ready
   - attack rate is legal
6. Server evaluates valid targets in front arc.
7. Server applies damage and knockback.
8. Server sends results to all clients.
9. Clients play hit feedback.

## 21.2 Hit Detection
Preferred MVP option:
- short frontal arc or cone in front of the player

Requirements:
- target must be within range
- target must be within allowed angle threshold
- hit detection must be resolved by server

Alternative implementation:
- spawn a short-lived attack hitbox during active frames if that proves easier to manage in Godot

## 21.3 Damage Model
Use a simple MVP damage model:
- fixed damage per swing
- optional later tuning for slight scaling with growth

Keep the initial version simple and data-driven.

---

# 22. Growth Specification

## 22.1 Growth Trigger
A player grows only when credited with a kill.

## 22.2 Growth Effects
Each kill may update:
- growth level
- player scale
- attack range
- max health
- leaderboard score
- slight movement penalty

## 22.3 Reset on Death
For MVP:
- reset to base state on death

This keeps the loop clean, fair, and easy to understand.

Optional future variant:
- retain partial growth after death

---

# 23. Spawn and Respawn Rules

## 23.1 Initial Spawn
When a player joins:
- choose a random valid spawn point
- avoid nearby enemies when possible

## 23.2 Respawn Safety
Respawn selection should prefer:
- low nearby enemy density
- valid ground position
- not directly beside another player

## 23.3 Spawn Protection
MVP can omit invulnerability if spawn placement is good enough.

If needed, add:
- brief invulnerability on respawn
- protection breaks immediately if player attacks

---

# 24. Performance Requirements

## 24.1 Mobile Performance Goal
- target 60 FPS on modern mid-range devices where possible
- acceptable fallback to 30 FPS

## 24.2 Optimization Principles
- low-poly environment
- simple materials
- limited expensive lighting
- lightweight VFX
- simple collision
- avoid unnecessary physics overhead

## 24.3 Networking Performance
- keep replicated data lean
- avoid sending unnecessary full state repeatedly
- structure code so snapshot/delta optimization can be added later

---

# 25. Accessibility and UX

## 25.1 Requirements
- readable UI on phones
- large touch targets
- strong contrast for bars and buttons
- minimal text during gameplay

## 25.2 Optional MVP Nice-to-Haves
- vibration toggle
- adjustable joystick size
- colorblind-friendly health and highlight choices

---

# 26. Security and Abuse Considerations

## 26.1 Basic Protections
- validate player name length/content
- rate-limit attack requests on server
- validate movement distances per tick
- do not trust client-side health or kill updates

## 26.2 Non-Goals for MVP
- full anti-cheat
- account bans
- moderation tools
- robust backend security tooling

---

# 27. Development Milestones

## 27.1 Milestone 1: Offline Prototype
Deliver:
- one arena
- one local player
- top-down camera
- movement
- attack
- dummy hit detection
- local growth scaling

## 27.2 Milestone 2: Basic Multiplayer
Deliver:
- multiple connected players
- synchronized movement
- synchronized facing
- synchronized attacks
- authoritative hit resolution

## 27.3 Milestone 3: Full Gameplay Loop
Deliver:
- health
- eliminations
- kill credit
- respawn
- growth reset on death
- leaderboard

## 27.4 Milestone 4: Mobile Polish
Deliver:
- proper touch controls
- optimized HUD
- audio and VFX pass
- menu/settings flow
- performance pass

---

# 28. Acceptance Criteria

## 28.1 Core Gameplay
- player can join a live arena session
- player can move using touch joystick
- player can press attack button to swing bat
- bat swing can damage nearby players in front arc
- players can be eliminated
- killer gets kill credit
- killer grows larger after a kill
- eliminated player respawns after a delay
- HUD reflects health, kills, and growth
- leaderboard updates during play

## 28.2 Multiplayer
- at least 2+ players can play in the same arena
- remote movement is visible and reasonably smooth
- attack results are synchronized
- growth state is synchronized
- deaths and respawns are synchronized

## 28.3 Mobile UX
- controls are usable on a phone screen
- UI remains readable during gameplay
- camera keeps local player visible even at larger size

## 28.4 Stability
- no crash during join/fight/death/respawn loop
- no duplicate kill credit for one elimination
- player cannot attack faster than cooldown allows

---

# 29. Testing Plan

## 29.1 Functional Tests
- player can join and spawn
- player can move in all directions
- player cannot leave arena bounds
- attack button triggers correct animation and cooldown
- attack only hits targets in valid range/arc
- health decreases correctly
- death triggers respawn timer
- kill increments score
- growth applies after kill
- growth resets on death

## 29.2 Multiplayer Tests
- two players can see each other move
- one player hitting another updates both clients correctly
- simultaneous hits behave predictably
- late joiner receives current world state correctly
- disconnect cleanup removes player correctly

## 29.3 Mobile Tests
- multitouch works for move + attack
- joystick does not stick incorrectly
- performance remains acceptable with several active players

---

# 30. Codex Implementation Guidance

## 30.1 Priorities
Build in this order:
1. local player controller
2. top-down camera
3. melee attack and hit detection
4. health/death/respawn
5. player scaling/growth
6. multiplayer authority layer
7. HUD and touch controls
8. leaderboard
9. polish and optimization

## 30.2 Code Quality Expectations
- clean scene separation
- gameplay constants configurable
- avoid hardcoded magic numbers where possible
- server authority boundaries explicit
- reusable components where practical

## 30.3 Recommended Implementation Style
Use Godot scenes and scripts with clear separation of responsibility:
- movement logic separated from combat logic
- stats separated from visuals
- networking separated from gameplay logic where possible
- touch input encapsulated in UI controls

---

# 31. Open Questions for Future Iteration
These should not block MVP:
- Should growth affect only visuals and health, or also damage?
- Should eliminated players drop mass or pickup orbs?
- Should the arena later include hazards?
- Should there be spawn invulnerability?
- Should attack direction always follow movement, or later support right-stick style aiming?
- Should bots populate low-player sessions?

---

# 32. Final MVP Definition
The MVP is successful if a player can install the game, enter a shared arena, control a stylized bat-wielding fighter from a Brawl Stars-like top-down camera, hit and eliminate other players, grow larger on kills, respawn on death, and continuously compete in a simple online melee survival loop on mobile.

---

# 33. Deliverable Request for Codex
Generate a Godot 4.x project implementing the MVP in this specification with:
- mobile-first controls
- one arena
- one networked player character
- top-down camera
- authoritative multiplayer combat
- kill-to-grow gameplay loop
- clear scene/script organization
- placeholder assets where final art/audio are not yet available

Use placeholder art, UI, audio, and simple environment assets where necessary, but implement the full gameplay architecture so production assets can be swapped in later.
