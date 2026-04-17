# Testing Guide

## Automated Test Suite

The project includes a repo-native headless Godot test runner under `sahur-io/tests/`. It focuses on stable gameplay rules that should remain correct as the MVP expands.

## Run From The Repository Root

```bash
godot --headless --path sahur-io --script res://tests/run_tests.gd
```

If you are running inside a restricted sandbox that blocks Godot from writing its user log directory, point `HOME` at a writable folder first:

```bash
HOME="$PWD/.godot-home" godot --headless --path sahur-io --script res://tests/run_tests.gd
```

## Current Coverage

- tuning formulas for movement, health, scale, and camera growth
- player state transitions for damage, defeat, respawn, and growth
- combat cooldown and active hit-window timing
- spawn selection based on occupied positions
- leaderboard and snapshot generation
- replication helper timing and interpolation behavior
- representative server-side player combat flow using the real `Player.tscn`

## Test Layout

- `sahur-io/tests/run_tests.gd`: headless entry point and summary output
- `sahur-io/tests/support/test_suite.gd`: lightweight assertion helpers
- `sahur-io/tests/cases/`: gameplay-focused test suites

## Extending The Suite

1. Add a new `test_*.gd` file under `sahur-io/tests/cases/`.
2. Inherit from `res://tests/support/test_suite.gd`.
3. Add one or more methods whose names begin with `test_`.
4. Register the suite in `sahur-io/tests/run_tests.gd`.

Keep new tests deterministic, fast, and focused on gameplay rules or scene behavior that can run headlessly.
