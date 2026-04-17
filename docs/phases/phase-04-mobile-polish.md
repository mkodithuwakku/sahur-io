# Phase 04 - Mobile Polish

## Objective

Convert the functional MVP into a readable, device-tested mobile experience.

## Scope

- Touch joystick and attack button tuning
- HUD readability and layout refinement on phone-sized screens
- Audio and VFX pass using production-ready placeholders or final assets
- Menu and settings polish
- Accessibility and quality-of-life toggles called out in the specification
- Real-device performance pass for input, rendering, and network cadence

## Key Tasks

- Tune touch dead zones, joystick size, and attack button reliability
- Validate that health, growth, and leaderboard information stay legible during combat
- Add basic settings for audio, vibration, and optional control adjustments
- Replace silent combat hooks with real feedback assets
- Profile frame rate, memory, and network behavior on target mobile devices

## Exit Criteria

- Move and attack controls feel dependable on touchscreen
- The HUD stays readable across common phone aspect ratios
- Camera framing remains stable as the player grows
- Combat feedback communicates swings, hits, eliminations, and growth clearly
- Performance is acceptable on target test hardware

## Test Focus

- Manual device testing for multitouch behavior
- Performance captures during several-player sessions
- UX smoke checks for settings, menu flow, and accessibility options

## Main Risks

- Controls that work on desktop can still fail badly on phones
- Visual polish can regress readability if feedback becomes too noisy
- Performance issues often appear only after real-device testing
