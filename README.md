# Tun Tun Tung Sahur Arena

Godot 4.x multiplayer MVP for a mobile-first top-down arena brawler inspired by Brawl Stars-style camera framing and Slither.io-style growth progression.

## Repository Info

- Engine: Godot 4.x
- Project root: `sahur-io/`
- Main branch: `main`
- Current state: playable MVP foundation with placeholder art/audio hooks, LAN-style host/join flow, authoritative combat, growth, respawn, HUD, and top-down arena gameplay

## Features

- One 3D top-down arena with obstacles and spawn points
- Host and join flow for local multiplayer testing
- Bat melee combat with server-authoritative hit resolution
- Kill-to-grow progression loop
- Respawn and live leaderboard system
- Mobile-first HUD with virtual joystick and attack button
- Desktop debug controls for development

## Repo Layout

- `sahur-io/`: Godot project
- `docs/`: architecture notes and development phase logs
- `context.md`: quick-start context for future work
- `prompt_part1.md`, `prompt_part2.md`: original product specification split into two files

## Requirements

- Godot 4.x installed and available as `godot` on your PATH
- macOS, Linux, or Windows with Godot desktop support

## Run Locally

From the repository root:

```bash
godot --path sahur-io
```

You can also open the project manually in the Godot editor by selecting the `sahur-io/project.godot` file.

## Local Multiplayer Test

1. Start one game instance with `godot --path sahur-io`.
2. In the menu, choose `Host Match`.
3. Start a second instance with the same command.
4. In the second instance, choose `Join Match`.
5. Use `127.0.0.1` as the server IP for same-machine testing.

## Headless Server

```bash
godot --headless --path sahur-io -- --server
```

Then connect a client with:

```bash
godot --path sahur-io
```

## Controls

- Desktop movement: `WASD` or arrow keys
- Desktop attack: `Space` or left mouse button
- Leave match: `Esc`
- Mobile controls: on-screen virtual joystick and `BAT` attack button

## Validation

```bash
godot --headless --path sahur-io --quit
```

## Documentation

- [Current Context](./context.md)
- [Architecture Overview](./docs/architecture/overview.md)
- [Development Phases](./docs/phases/README.md)
