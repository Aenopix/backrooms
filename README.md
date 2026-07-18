# Backrooms

A short first-person exploration/horror prototype built in Godot 4.7, set in **The Backrooms** — an endless, liminal maze of identical office rooms with yellowed walls, damp carpet, and flickering fluorescent lights. There's no visible way out. The only way is deeper in.

Inspired by the original Backrooms creepypasta and *Backrooms* (2026, A24). The goal is quiet dread, not action-horror — disorientation and repetition do the work, not enemies or combat.

## Gameplay

You spawn in a maze of connected rooms lit only by buzzing, flickering fluorescents. Explore until you find the exit room, marked by a steady green light. Stay away from the dark too long and your sanity drains; standing under a lit fixture lets it recover.

- Procedurally generated maze (randomized depth-first carving) — every room is reachable, and the exit is always the room farthest from spawn
- Flickering lights with a procedurally synthesized hum, no audio files required
- A sanity meter that drains in the dark and recovers under working lights
- Fade-to-black win screen with a restart button once you reach the exit

## Controls

| Action | Key |
|---|---|
| Move | `W A S D` |
| Look | Mouse |
| Toggle flashlight | `F` |
| Release / recapture mouse | `Esc` |

## Running it

Requires **Godot 4.7.1**. Clone the repo, open it in the editor, and hit Play — `Main.tscn` is set as the entry scene.

## Project structure

```
res://
├── scenes/
│   ├── Main.tscn          # entry point — instances Level + HUD
│   ├── Player.tscn        # CharacterBody3D, first-person camera + controller
│   ├── RoomModule.tscn    # reusable room tile, geometry built procedurally at runtime
│   ├── Level.tscn         # generates the maze and spawns the player
│   └── UI/
│       └── HUD.tscn       # crosshair, sanity bar, win screen + restart button
├── scripts/
│   ├── player_controller.gd  # movement, mouse look, flashlight, footsteps, sanity check
│   ├── level_generator.gd    # DFS maze carving, exit placement, room instancing
│   ├── room_module.gd        # builds a room's walls/floor/ceiling/light from scratch
│   ├── flicker_light.gd      # random flicker + procedural hum audio
│   ├── game_manager.gd       # autoload: sanity state + win signal
│   └── hud.gd                # win-screen fade, restart handling
└── assets/
    ├── materials/          # yellow wall / carpet / ceiling materials
    └── environment/        # dim, fogged world environment
```

## Notes

- The maze layout is deterministic by default (fixed seed on `Level`'s `level_generator.gd`) — toggle `randomize_layout` on if you want a new layout every run.
- Fluorescent lights cast shadows so they don't bleed through walls into neighboring rooms.
- No combat, inventory, or multiple levels — out of scope for this prototype.
