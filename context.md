# Context

## Project Snapshot

- Product: `Tun Tun Tung Sahur Arena`
- Engine: Godot 4.x
- Godot project root: `/Users/mkodi/Personal Coding/Sahur-io/sahur-io`
- Current milestone: playable MVP foundation with phased implementation docs and headless gameplay test coverage

## Key Commands

```bash
godot --path sahur-io
godot --headless --path sahur-io -- --server
godot --headless --path sahur-io --quit
godot --headless --path sahur-io --script res://tests/run_tests.gd
```

## Core Runtime Pieces

- `autoload/GameManager`: scene transitions, guest naming, input-map bootstrap
- `autoload/NetworkManager`: ENet host/join lifecycle and connection signals
- `scenes/main/GameWorld.tscn`: authoritative match scene
- `scenes/player/Player.tscn`: player actor with movement, combat, growth, and prediction hooks
- `scenes/ui/HUD.tscn`: touch controls, leaderboard, respawn overlay, and debug status

## Gameplay Status

- Implemented:
  - top-down 3D arena with spawn points and obstacles
  - host/join menu flow
  - authoritative movement and bat attack validation on the server
  - kill credit, growth scaling, respawn, and live leaderboard
  - touch joystick and attack button with desktop debug input fallback
- Placeholder / follow-up:
  - procedural placeholder visuals only
  - audio manager hooks exist, but no shipped sound assets yet
  - networking uses lightweight custom snapshots and prediction hooks, not a full reconciliation system

## Documentation Protocol

When continuing development:

1. Add or update a phase document in `docs/phases/`.
2. Update `docs/architecture/overview.md` if architecture changes.
3. Refresh this file with the new current milestone, changed commands, and important risks.
4. Extend `docs/testing.md` and `sahur-io/tests/` when gameplay rules or networking behavior change.

## Known Risks

- Needs broader multiplayer soak testing for packet loss and simultaneous-hit edge cases.
- Mobile feel should be tuned on actual device hardware.
- Dedicated-server deployment is scaffolded through headless hosting, but production orchestration is still future work.
