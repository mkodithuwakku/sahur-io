# Phase 01 - Offline Prototype

## Objective

Build the first playable combat slice locally before networking complexity is introduced.

## Scope

- One top-down 3D arena with clear bounds and spawn points
- One controllable player character
- Camera framing inspired by the specification's Brawl Stars-style presentation
- Local movement with readable facing direction
- Bat swing with short frontal hit validation
- Local growth feedback after a successful elimination surrogate or scripted kill
- Tuning resources for movement, combat, growth, and camera behavior

## Key Tasks

- Establish project structure for `core`, `player`, `arena`, `ui`, and `network`
- Implement player state containers separate from visuals
- Keep combat, growth, and movement logic data-driven
- Use placeholder meshes and materials so art can be replaced later
- Add desktop debug controls alongside touch-ready HUD scaffolding

## Exit Criteria

- A local player can move, attack, and grow in the arena
- Attack range and attack arc are readable and tunable
- Arena bounds and obstacle collisions work consistently
- Camera still frames larger player sizes correctly
- Core gameplay constants live in resources instead of hardcoded values

## Test Focus

- Movement, growth, and camera tuning formulas
- Attack cooldown and active window timing
- Attack arc math and local combat rule validation

## Main Risks

- Combat can feel unresponsive if startup and cooldown values are not tuned early
- Growth can damage readability if scale and camera rules drift apart
- Tight coupling between visuals and gameplay will slow later networking work
