# Phase 03 - Continuous Arena Loop

## Objective

Turn the combat sandbox into the always-on multiplayer loop described in the specification.

## Scope

- Health and elimination rules
- Kill credit assignment
- Growth rewards on confirmed kills
- Respawn timer and spawn safety selection
- Growth reset on death
- Live leaderboard and local HUD state

## Key Tasks

- Track full player state including health, deaths, respawn timer, and last attacker
- Move kill-driven growth through a single authoritative path
- Choose spawn points away from active threats when possible
- Keep leaderboard scoring deterministic and cheap to compute
- Reflect state changes into HUD and snapshot payloads

## Exit Criteria

- Players can fight, die, respawn, and re-enter the arena continuously
- A valid attacker receives kill credit exactly once per elimination
- Growth increases the intended stats and resets on death
- Respawns do not place players directly into obvious danger when safer options exist
- HUD and leaderboard reflect authoritative match state during live play

## Test Focus

- Player health, death, respawn, and growth state transitions
- Spawn selection against occupied positions
- Leaderboard ordering and snapshot payload generation
- End-to-end server combat resolution on representative player nodes

## Main Risks

- Duplicate kill credit or stale respawn state will damage the core progression loop
- Poor spawn selection will make the game feel unfair on small player counts
- Leaderboard and HUD drift will reduce trust in the multiplayer state
