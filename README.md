# BACKROOMS GAME — Design Brief

> **Purpose of this file:** context for an AI coding assistant working inside an existing
> Godot project. It explains the concept, tone, and core mechanics so the AI can generate
> scenes/scripts consistent with the intended game. Keep everything simple — this is a
> small, focused prototype, not a full production.

---

## 0. Engine Version

**Godot 4.7.1 stable** — use GDScript 2.0 syntax and 4.x node names/APIs
(e.g. `CharacterBody3D`, not the old `KinematicBody`). Avoid suggesting code or nodes
from Godot 3.x.

---

## 1. Concept

A short first-person exploration/horror game set in **"The Backrooms"** — an endless,
liminal maze of empty office-style rooms with yellowed walls, damp beige carpet, and
flickering fluorescent lights. There is no visible way out; the only way is deeper in.

**Inspiration:**
- The original Backrooms creepypasta / "noclip into the wrong reality" internet legend.
- *Backrooms* (2026), the A24 feature film directed by Kane Parsons ("Kane Pixels"),
  starring Chiwetel Ejiofor and Renate Reinsve. Premise: a strange doorway appears in the
  basement of a furniture showroom; after a therapist's patient vanishes into a dimension
  beyond reality, she enters the Backrooms to find him. The film is praised for its
  oppressive, claustrophobic "liminal space" atmosphere, uncertainty, and found-footage-style
  dread rather than jump scares or combat.

**Tone to aim for:** quiet dread, not action-horror. Emptiness and repetition are the
enemy, not necessarily monsters (an entity chase can be a later addition, not required
for the first version).

---

## 2. Core Pillars (what the AI should prioritize)

1. **Liminal atmosphere** — dim fluorescent lighting, humming ambient sound, mono-yellow
   color palette, repeating identical rooms.
2. **Disorientation over combat** — the player should feel lost, not threatened by enemies,
   at least in this base version.
3. **Simplicity** — small scope, procedurally repeatable room layout, minimal UI.

---

## 3. Minimum Viable Gameplay Loop

1. Player spawns in a small room with a flickering light and a doorway.
2. Player explores a maze built from repeating/randomized room modules.
3. Ambient hum + occasional light flicker/sound cues build tension.
4. Player finds an **exit door** (goal) somewhere in the maze → win state / "You escaped" screen.
5. Optional stretch goal: a simple **sanity/light meter** that drains in the dark and
   recovers near working lights, encouraging the player to keep moving.

No combat, no inventory, no complex UI for v1.

---

## 4. Suggested Godot Structure

```
res://
├── scenes/
│   ├── Main.tscn            # entry point, loads Level
│   ├── Player.tscn          # CharacterBody3D, first-person camera + controller
│   ├── RoomModule.tscn      # a single reusable room "tile" (walls, floor, ceiling, light)
│   ├── Level.tscn           # arranges RoomModule instances into a maze
│   └── UI/
│       └── HUD.tscn         # minimal: crosshair, optional sanity bar, win screen
├── scripts/
│   ├── player_controller.gd # WASD + mouse look, footsteps, flashlight toggle
│   ├── level_generator.gd   # places/randomizes RoomModule grid, keeps track of exit
│   ├── flicker_light.gd     # random flicker/hum behavior for OmniLight3D
│   └── game_manager.gd      # win/lose state, sanity meter (optional)
└── assets/
    ├── materials/            # yellow wall/carpet/ceiling materials
    └── audio/                 # hum loop, flicker sound, footsteps
```

---

## 5. Key Mechanics to Implement First

- **Player Controller:** first-person `CharacterBody3D`, mouse-look camera, WASD movement,
  no jumping needed (optional), simple footstep sfx on move.
- **Room Module:** one Blender-simple box room (walls/floor/ceiling), yellow wallpaper
  material, a buzzing fluorescent `OmniLight3D` with a flicker script, 1–4 doorway
  openings so modules can connect.
- **Level Generator:** places `RoomModule` instances on a grid (e.g. 5x5), connects
  adjacent doorways, marks one module as the **exit room**. Keep it deterministic/simple
  first (fixed layout), randomize later.
- **Flicker Light script:** randomizes light energy/on-off over time + plays a hum/buzz
  sound — this single effect does most of the atmosphere work.
- **Win Condition:** entering the exit room's trigger `Area3D` shows a "You escaped" UI
  and stops player input.

---

## 6. Explicitly Out of Scope for v1

- Enemies/entities and chase mechanics
- Inventory or item pickups
- Multiple game "levels" beyond the Backrooms (no Level 1, Level 2, etc.)
- Save/load system
- Complex procedural generation (perlin noise mazes, etc.)

These can be proposed as **future stretch goals** but should not block a working, simple
first version.

---

## 7. Notes for the AI Assistant

- The base Godot project already exists — extend it, don't restructure it unnecessarily.
- Prefer built-in Godot nodes (`CharacterBody3D`, `OmniLight3D`, `Area3D`, `AudioStreamPlayer3D`)
  over custom physics or external plugins.
- Comment scripts concisely: one short comment per function/block explaining *why*, not
  line-by-line narration.
- Favor a small number of reusable scenes (e.g. one `RoomModule.tscn`) over many
  one-off scenes.