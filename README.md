# Doom-style Prototype (Godot 4)

## Setup
1. Install Godot 4.2+ (godotengine.org) — no other dependencies needed.
2. Open Godot, "Import", select this folder's `project.godot`.
3. Press F5 (or the Play button) to run. Main.tscn is set as the run scene.

## Controls
- WASD: move
- Mouse: look
- Space: jump
- Left click: shoot (hitscan raycast, 40m range)
- Esc: release mouse cursor

## What's here
- `scripts/player.gd` — FPS movement, mouse look, hitscan shooting, health/damage.
- `scripts/enemy.gd` — chase-and-melee AI: idle until player enters sight range,
  closes distance, attacks on cooldown when in range, flashes on hit, dies at 0 HP.
- `scripts/level_builder.gd` — procedurally builds a 3-room corridor layout out of
  boxes at runtime. No hand-modeled geometry yet — this is a gray box for testing
  movement/combat feel before any art pass. Room list is a plain array of
  `{pos, size}` dicts at the top of the script; add more rooms there to extend
  the layout, or delete it wholesale once you're ready to hand-author real levels.
- `scenes/Main.tscn` — wires it all together: lighting, level, player spawn, HUD.

## Where to go next
- The world-state object for your fuel-vs-walk branching (discussed earlier)
  doesn't exist yet — this prototype is deliberately just movement + combat
  feel. Next step would be a small autoload singleton (Godot's version of a
  global state object) tracking flags like `has_fuel` and `squadmate_alive`,
  which `level_builder.gd` or a future level-loading script reads to decide
  which room variant to spawn.
- Enemy AI is a direct-chase-no-pathfinding stand-in. Swap in a
  `NavigationAgent3D` once real level geometry has walls the enemy needs to
  route around.
- No weapon switching or ammo yet — `_fire()` in player.gd is a single
  hardcoded hitscan weapon. Scarce-resource weapon switching would live here.
