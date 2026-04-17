# Phase 02 - Basic Multiplayer

## Objective

Introduce authoritative multiplayer without breaking the local combat feel established in Phase 01.

## Scope

- LAN-style host and join flow
- Clear server-authoritative state ownership
- Client input submission for movement and attacks
- Snapshot-based world replication
- Remote smoothing and local correction hooks
- Peer join, late join sync, and disconnect cleanup

## Key Tasks

- Build the network lifecycle around ENet and explicit connection states
- Keep server-side hit resolution and validation in gameplay code, not UI code
- Separate local prediction from replicated remote interpolation
- Broadcast only the state needed for the current MVP loop
- Preserve the option to migrate from host authority to dedicated servers later

## Exit Criteria

- Two or more peers can join the same session reliably
- Remote movement and facing remain understandable during combat
- Attack results are resolved by the server and synchronized to all peers
- Late joiners receive the current world state without manual resets
- Disconnecting peers are removed cleanly from the world and leaderboard

## Test Focus

- Replication timing helpers
- Snapshot application and correction behavior
- Server-owned combat path using representative player scenes
- Join, leave, and reconnect smoke checks during manual validation

## Main Risks

- Loose authority boundaries will create cheating and desync problems later
- Overly chatty replication will block mobile performance goals
- Remote smoothing can hide state errors if it is not validated against server snapshots
