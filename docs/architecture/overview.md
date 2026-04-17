# Architecture Overview

## Current Shape

The Godot project lives in `sahur-io/` and is organized around a small set of stable boundaries:

- `core`: app-level bootstrapping and shared configuration
- `network`: ENet connection management and snapshot-oriented authoritative replication
- `player`: movement, combat, growth, and prediction-oriented state helpers
- `arena`: arena bounds and spawn selection
- `ui`: mobile controls and gameplay HUD

## Match Authority

- The server owns authoritative player state, combat resolution, elimination, growth, and respawn timing.
- Clients submit movement vectors and attack requests.
- Clients run local movement and attack previews for responsiveness.
- The server periodically broadcasts authoritative snapshots for smoothing and correction.

## Scene Graph Highlights

- `Main.tscn` swaps between the main menu and the game world.
- `GameWorld.tscn` owns the arena, player registry, camera rig, HUD, and server-side match orchestration.
- `Player.tscn` is a procedural placeholder character built from primitive meshes so art can be replaced later without changing gameplay logic.

## Data-Driven Tuning

Gameplay constants are kept in `resources/data/tuning/` and loaded through the `Config` autoload. That keeps movement, combat, growth, and respawn values editable without rewriting gameplay code.

## Planned Evolution

- Replace custom snapshot payloads with richer delta/state sync if player counts increase.
- Add dedicated server bootstrap and deployment docs once hosting infrastructure is chosen.
- Swap placeholder meshes, VFX, and audio with production assets while preserving current gameplay interfaces.
