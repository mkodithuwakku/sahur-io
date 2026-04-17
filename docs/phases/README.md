# Development Phases

This roadmap translates `prompt_part1.md` and `prompt_part2.md` into a practical implementation sequence for the Godot project. It keeps the MVP shippable in slices while preserving the authoritative multiplayer architecture described in the specification.

## Recommended Order

| Phase | Status | Outcome |
| --- | --- | --- |
| [Phase 01 - Offline Prototype](./phase-01-offline-prototype.md) | Complete | Single-player combat slice with arena, movement, attack, growth, and camera feel |
| [Phase 02 - Basic Multiplayer](./phase-02-basic-multiplayer.md) | Complete | Host/join flow, authority boundaries, replication, and synchronized combat |
| [Phase 03 - Continuous Arena Loop](./phase-03-continuous-arena-loop.md) | Complete | Health, eliminations, respawn, growth reset, spawn safety, and leaderboard loop |
| [Phase 04 - Mobile Polish](./phase-04-mobile-polish.md) | Planned | Touch UX refinement, readability, presentation, and device performance work |
| [Phase 05 - Production Readiness](./phase-05-production-readiness.md) | Planned | Soak testing, CI, deployment, release workflow, and operational hardening |

## Phase Boundaries

- Each phase should leave the game playable end-to-end, even if visuals and content remain placeholder quality.
- Authority and tuning data should stay explicit so later phases can polish without rewriting core gameplay rules.
- Automated tests should expand with each phase, starting with gameplay rules and ending with repeatable multiplayer smoke coverage.

## Supporting Documents

- [Historical Snapshot - MVP Foundation](./phase-01-mvp-foundation.md)
- [Architecture Overview](../architecture/overview.md)
- [Testing Guide](../testing.md)
