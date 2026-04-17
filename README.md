# Tun Tun Tung Sahur Arena

Godot 4.x multiplayer MVP for a mobile-first top-down arena brawler.

## Repo Layout

- `sahur-io/`: Godot project
- `docs/`: architecture notes and development phase logs
- `context.md`: quick-start context for future work
- `prompt_part1.md`, `prompt_part2.md`: original product specification split into two files

## Run

```bash
godot --path sahur-io
```

## Multiplayer Flow

1. Launch one instance and choose `Host Match`.
2. Launch another instance and choose `Join Match`.
3. Enter the host IP address, or use `127.0.0.1` for local testing.

## Headless Server

```bash
godot --headless --path sahur-io -- --server
```

## Documentation

- [Current Context](./context.md)
- [Architecture Overview](./docs/architecture/overview.md)
- [Development Phases](./docs/phases/README.md)
