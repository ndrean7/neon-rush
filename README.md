# Neon Rush

A fast, original 2D arcade game built with **Godot 4**. Pilot a glowing
ship through a neon grid arena, collect energy orbs, and dodge the drone
swarm. The longer you survive, the faster the drones get.

No assets were borrowed from anywhere: every sprite is generated at
runtime (radial-gradient glow textures), the background grid is drawn in
code, and the ship, drones and orbs are vector shapes styled with
additive-blend glow, particles and a bloom-lit environment.

## How to play

| Action | Control |
| --- | --- |
| Move | `WASD` / Arrow keys, or drag with mouse / touch |
| Restart after game over | `R` or the **Play Again** button |

- **Gold orbs** are worth 10 points. Grab them quickly in a row to build
  a combo — each combo step adds +5 points per orb.
- **Red drones** chase you. **Orange drones** drift straight and bounce
  off the walls. Touching any drone ends the run.
- Orbs expire after 9 seconds (they blink first), so keep moving.
- Your best score is saved on your machine between runs.

## How to run

1. Install **Godot 4.3** (or newer 4.x) from https://godotengine.org.
2. Open this project in the Godot editor (import `project.godot`).
3. Press **Play** (F5). The game runs at 1280×720.

No build step, no extra downloads — the project has zero external assets.

## Project structure

```
project.godot          Godot 4 project (1280x720, Forward+ renderer, glow)
main.tscn              Main scene: camera, bloom environment, HUD
player.tscn            Player ship (Area2D)
enemy.tscn             Drone (Area2D)
pickup.tscn            Energy orb (Area2D)
scripts/
  main.gd              Spawning, score/combo/best, game over, restart
  player.gd            Movement, neon trail, collisions
  enemy.gd             Chaser + drifter drone behaviour
  pickup.gd            Orb behaviour (spin, bob, lifetime)
  textures.gd          Runtime glow-texture generator (no image files)
```

## License

MIT — see [LICENSE](LICENSE). Made by
[0xndrean7](https://github.com/ndrean7).
