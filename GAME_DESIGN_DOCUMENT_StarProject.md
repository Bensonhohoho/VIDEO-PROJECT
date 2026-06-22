# Slime Bullet Game Design Document

Last updated: 2026-06-06

## 1. Project Snapshot

**Project name in Godot:** First Game  
**Working design name:** Slime Bullet  
**Engine:** Godot 4.6, Forward Plus  
**Main scene:** `res://scenes/game.tscn`  
**Mini-game design name:** Stay In Line  
**Core genre:** 2D pixel-art platformer with a queue-dodging mini-game loop  
**Current state:** playable prototype with platforming, coins, enemies, hazards, persistent score, a round-score system, and a designed queue mini-game path.

## 2. High Concept

The player controls a knight-like character through a compact pixel platformer level, collecting coins while avoiding hazards and slime enemies. A special queue entrance leads into **Stay In Line**, a short challenge where the player must stay inside a moving queue zone, avoid obstacles, and reach the goal. Queue wins add major score toward a round goal; completing the round triggers victory.

The project currently reads as a light arcade platformer with one extra social/queue challenge mode layered on top of the main level.

## 3. Design Pillars

- **Simple movement first:** platformer controls should stay readable and responsive.
- **Clear consequences:** all damaging objects use the same `take_damage()` contract.
- **Small systems, clean ownership:** bullets handle bullets, player handles player state, managers handle scene/game flow.
- **Mini-game as score accelerator:** coins provide small score gains; queue wins provide larger round progress.
- **Instant queue readability:** safe area, player, hazards, and finish should be distinguishable at a glance.
- **Prototype-friendly scope:** keep architecture lightweight until more enemies, lives, health, checkpoints, or damage types justify extra components.

## 4. Project History Summary

This section compacts available project history from `GUIDELINES.md`, the current scripts/scenes, and Git reflog files. The `git` executable was not available in this shell, so exact commit diffs were not inspected.

| Date | History Signal | Design Meaning |
| --- | --- | --- |
| 2026-04-18 | Initial commit and project submission commits | Base Godot platformer project established. |
| 2026-04-25 | Project upload and fast-forward pull | Asset/project structure expanded with Brackeys platformer assets and current Godot project files. |
| 2026-05-03 | `update slime logic` commit | Slime enemy behavior became a notable focus. Current scripts include normal patrol slime, runaway slime, shooting slime, and slime bullets. |
| 2026-05-16 | `restore-old-version` branch created from older head | A restore/reference branch was created, suggesting experimentation or recovery around that stage. |
| 2026-05-16 | `code review of enemies logic.` and `Update Player.gd`, then revert | Enemy/player logic was reviewed and player changes were tested, amended, then reverted. The current guidelines emphasize decoupling enemy/bullet behavior from player death and game flow. |
| 2026-05-23 | `GUIDELINES.md` created/updated | Architecture decisions were documented: damage sources call `take_damage()`, player emits `died`, and `GameManager` owns restart/game-over behavior. |
| 2026-05-30 | Latest visible submit commit | Current implementation includes persistent scoring, queue mini-game scripts, obstacle spawning, and round completion flow. |

## 5. Target Player Experience

The intended moment-to-moment loop is:

1. Explore the main platformer level.
2. Jump across platforms and avoid falling into the kill zone.
3. Collect coins for persistent score.
4. Avoid or outmaneuver slime enemies.
5. Enter the queue challenge from the main scene.
6. Stay inside the moving queue zone, dodge obstacles, and reach the goal.
7. Earn a larger score reward and progress toward the round target.
8. Complete the round target to trigger a victory state.

## 6. Main Platformer Mode

### Player

- Scene: `res://scenes/player.tscn`
- Script: `res://scripts/player.gd`
- Type: `CharacterBody2D`
- Movement speed: `130.0`
- Jump velocity: `-300.0`
- Controls:
  - Jump: Space
  - Move left: Left Arrow / A
  - Move right: Right Arrow / D

The player animates between idle, run, and jump states and flips horizontally based on movement direction.

### Main Level

- Scene: `res://scenes/game.tscn`
- Includes a tilemap, static platforms, one moving platform, coins, a kill zone, queue entrance, and slime enemies.
- Main camera is attached to the player with zoom `4,4`.
- UI currently includes a score label.

### Coins

- Scene: `res://scenes/coin.tscn`
- Script: `res://scripts/coin.gd`
- Coins call `GameManager.add_point()`.
- Main scene coin reward: `1` saved score point.
- Coins play a collection animation, wait `0.8` seconds, then remove themselves.

## 7. Enemy And Hazard Design

### Basic Slime

- Script: `res://scripts/slime.gd`
- Patrols horizontally at speed `60`.
- Uses left/right raycasts to reverse direction at walls.
- Plays its default sprite animation.

### Runaway Slime

- Script: `res://scripts/runaway_slime.gd`
- Patrol speed: `60`
- Flee speed: `120`
- Flee distance: `80`
- Detects line-of-sight to the player with a physics raycast.
- Runs away when the player is close and visible.

### Shooting Slime

- Script: `res://scripts/shooting_slime.gd`
- Patrol speed: `40`
- Attack range: `160`
- Shoot cooldown: `1.2` seconds
- Fires `res://scenes/slime_bullet.tscn` toward the player's collision/body center.
- Continues patrolling while shooting.

### Slime Bullet

- Script: `res://scripts/slime_bullet.gd`
- Speed: `180`
- Lifetime: `3.0` seconds
- Moves in a setup direction supplied by the shooting slime.
- On hit, calls `target.take_damage(1, self)` if the body supports damage.
- Prevents duplicate hits, disables monitoring, hides, and frees itself after impact.

### Kill Zone

- Scene: `res://scenes/killzone.tscn`
- Script: `res://scripts/killzone.gd`
- Calls `take_damage(1, self)` on bodies that support it.
- Does not reload the scene directly.

## 8. Queue Mini-Game Mode: Stay In Line

### Mini-Game High Concept

Stay In Line is a small 2D arcade mini-game about keeping pace with a moving queue. The player must remain inside the queue zone as it travels toward the finish, dodge incoming obstacles, and reach the goal without stepping out of line.

### Player Fantasy

The player is trying to stay disciplined inside a moving line while pressure builds from timing, movement, and hazards. The fun comes from micro-adjusting position, resisting panic, and threading through obstacles while the safe space keeps drifting forward.

### Core Loop

1. Spawn inside the queue zone.
2. Move with the queue as it travels across the playfield.
3. Dodge obstacles entering from the right.
4. Stay inside the queue until reaching the goal area.
5. Win on goal contact, or restart quickly after leaving the queue or touching an obstacle.

### Entry

- Main scene node: `QueueEntrance`
- Script: `res://scripts/queue_entrance.gd`
- The player enters the area and presses `ui_up` to change scenes.
- Designed target scene: `res://scenes/queue_mini_game.tscn`
- Designed level sequence:
  - `res://scenes/queue_level_1_1.tscn`
  - `res://scenes/queue_level_1_2.tscn`
  - `res://scenes/queue_level_1_3.tscn`

Current implementation gap: those three queue level scenes are referenced but not present in the repo. Because the level list is not empty, the entrance currently tries to load missing level files instead of falling back to `queue_mini_game.tscn`.

### Queue Player

- Script: `res://scripts/queue_player.gd`
- Type: `CharacterBody2D`
- Movement speed: `220`
- Has `reset_to_spawn()` for mini-game retries.

| Action | Input |
| --- | --- |
| Move left/right/up/down | Arrow keys through `ui_*` actions |
| Move left/right/up/down | WASD through direct key checks |

### Queue Zone

- Scene node: `QueuePath/PathFollow2D/QueueZone`
- Script: `res://scripts/queue_zone.gd`
- A rectangular moving safe zone.
- The manager moves the `PathFollow2D` along a designer-authored `Path2D`.
- Default zone size: `240 x 160`
- Queue movement speed: `80`

### Objects And Systems

| Object | Role |
| --- | --- |
| Queue Player | `CharacterBody2D` controlled by the user; owns movement and spawn reset. |
| QueueZone | Moving `Area2D` safe zone; the manager moves its `PathFollow2D` parent. |
| GoalArea | Finish trigger; entering it wins the mini-game. |
| ObstacleSpawner | Creates obstacles at timed intervals and relays obstacle contact. |
| Obstacle | Moving `Area2D` hazard; emits contact once, then keeps moving until cleanup. |
| QueueGameManager | Owns win, fail, restart, signal wiring, UI result text, and stopping active systems. |

### Win And Fail Rules

The mini-game starts after resetting the player, queue, and obstacles. The player must enter and stay inside the queue zone until reaching the goal area.

- Leaving the queue after first entering fails the attempt.
- If the player exits near the finish, the game waits one physics frame so goal contact can resolve fairly.
- Hitting an obstacle fails the attempt unless the drink buff is active.
- Reaching the goal wins the attempt.
- Win reward: `10` round score and saved score.
- Maximum fails: `3`
- Reset/return delay: `0.25` seconds.
- After a win or final fail, the scene returns to `res://scenes/game.tscn`.
- On win, queue movement and obstacle spawning stop before the scene changes.

### Obstacles

- Spawner script: `res://scripts/obstacle_spawner.gd`
- Obstacle scene: `res://Obstacle.tscn`
- Obstacle script: `res://scripts/obstacle.gd`
- Spawn interval: `1.25` seconds
- Obstacle speed: `180`
- Spawn x: `980`
- Cleanup x: `-80`
- Spawn y range: `170` to `310`
- Obstacles emit `player_touched`; `QueueGameManager` decides whether that touch causes a fail.

### Current Tuning

| Value | Current Setting |
| --- | --- |
| Player speed | `220 px/s` |
| Queue speed | `80 px/s` |
| Obstacle speed | `180 px/s` |
| Obstacle spawn interval | `1.25 s` |
| Obstacle spawn range | `y 170-310` |
| Obstacle spawn x | `980` |
| Obstacle cleanup x | `-80` |
| Restart delay | `0.25 s` |

### Feedback And Visual Direction

Implemented feedback:

- Win message: `"You stayed in line!"`
- Queue exit message: `"Out of line!"`
- Obstacle hit message: `"Hit an obstacle!"`
- On fail, the mini-game resets quickly or returns to the main scene after the final fail.
- On win, the result label appears and gameplay systems stop before returning to the main scene.

Current prototype visuals use simple readable shapes:

- Player: blue square/capsule-like avatar.
- Queue zone: translucent green rectangle.
- Goal area: translucent yellow vertical finish zone.
- Obstacles: red square hazards.

Future visual work should preserve instant readability. The safe area, player, hazard, and finish must be recognizable at a glance.

### Stay In Line Success Criteria

The mini-game succeeds when a player immediately understands:

- Stay inside the green queue.
- Avoid red obstacles.
- Reach the yellow goal.
- Failure restarts quickly enough to invite another try.

### Drink Buff

Designed but incomplete in the current project files.

- Uses per mini-game: `2`
- Buff duration: `3.0` seconds
- Effect: ignores obstacle hits only; leaving the queue still fails.
- Implementation gap: `use_drink` is checked in code but is not defined in `project.godot`.
- Implementation gap: drink and buff labels are exported in `QueueGameManager`, but the current queue scene does not include `DrinkUsesLabel` or `BuffTimeLabel`.

## 9. Score, Save, And Round Systems

### Save Manager

- Autoload: `SaveManager`
- Script: `res://scripts/save_manager.gd`
- Save file: `user://save_data.json`
- Persisted value: `total_score`

### Score Types

- **Total score:** persistent score saved to disk.
- **Round score:** temporary session/round score used for a target goal.
- **Target score:** default `30`.

### Score Sources

- Coin collection: `+1` total score only.
- Queue mini-game win: `+10` total score and `+10` round score.

### Victory

When round score reaches target score, `SaveManager.round_completed` is emitted and `GameManager` attempts to show a victory label.

Current implementation gap: `GameManager` expects `../UI/VictoryLabel`, but `scenes/game.tscn` currently only contains `UI/ScoreLabel`. Victory logic exists, but there is no visible `VictoryLabel` in the current main scene.

## 10. Damage And Game Flow Architecture

The project standard is:

```text
Bullet / Hazard -> target.take_damage() -> Player emits died -> GameManager restarts
```

Damageable nodes should expose:

```gdscript
func take_damage(amount: int = 1, source: Node = null) -> void:
```

Damage sources should check first:

```gdscript
if body.has_method("take_damage"):
	body.take_damage(1, self)
```

### Player Death

The player owns death state:

- Ignores damage after already dead.
- Sets velocity to zero.
- Disables physics processing.
- Disables collision shapes with deferred changes.
- Emits `died(source)`.

### Game Manager Death Flow

The game manager owns global consequences:

- Prevents duplicate game-over handling.
- Prints `"You died!"`.
- Applies slow motion with `Engine.time_scale = 0.5`.
- Waits `0.6` seconds.
- Restores time scale to `1.0`.
- Reloads the current scene.

## 11. UI And Feedback

Implemented:

- Main score label displays saved total score.
- Queue score label displays round progress when configured for round score.
- Queue fail-count label displays attempt failures.
- Queue result label displays win/fail messages.
- Main queue entrance displays `"UP"`.
- Main scene includes `"Space to jump"` instruction text.

Designed but incomplete:

- Main victory label.
- Queue drink-uses label.
- Queue buff timer label.

## 12. Art, Audio, And Assets

Primary asset source:

- `brackeys_platformer_assets/`
- License: CC0, according to `LICENSE & CREDITS.txt`

Included asset categories:

- Pixel sprites: knight, slimes, world tileset, platforms, coins, fruit.
- Sounds: tap, power up, jump, hurt, explosion, coin.
- Music: `time_for_adventure.mp3`
- Fonts: PixelOperator8 and PixelOperator8-Bold.

Current visible style:

- Small pixel-art platformer.
- Bright fantasy tiles and character sprites.
- Simple geometric placeholder visuals for queue-zone/player/goal/obstacles.

## 13. Current Known Gaps

- Queue entrance references `queue_level_1_1.tscn`, `queue_level_1_2.tscn`, and `queue_level_1_3.tscn`, but those files are missing.
- `use_drink` input action is missing from `project.godot`.
- `VictoryLabel` is missing from `scenes/game.tscn`.
- Queue drink/buff UI labels are missing from `scenes/queue_mini_game.tscn`.
- `ScoreLabel` in `queue_mini_game.tscn` may need `display_mode = ROUND_SCORE` if the intended display is round progress instead of total score.
- `slime_bullet.gd`, `slime.gd`, `shooting_slime.gd`, and `runaway_slime.gd` contain comments that appear to have been saved or displayed with inconsistent text encoding. The code is readable enough, but comments should be normalized to UTF-8.
- Asset folders are duplicated under both `assets/` and `brackeys_platformer_assets/`.
- Current project name is still `First Game`; decide whether to rename it to `Slime Bullet` or another final title.

## 14. Recommended Next Milestone

Make the current intended loop fully playable:

1. Fix queue entrance scene selection so it can load an existing queue scene.
2. Add or remove the missing queue-level scene references.
3. Add `use_drink` input and the missing drink UI labels, or temporarily disable the drink mechanic.
4. Add `VictoryLabel` to the main UI.
5. Set the queue mini-game score HUD to show round score.
6. Normalize enemy/bullet script comments to UTF-8.
7. Playtest the round loop: platformer -> queue challenge -> return -> repeat -> victory.

## 15. Long-Term Feature Ideas

- Multiple queue challenge layouts with rising speed, smaller queue zones, faster obstacles, or new obstacle patterns.
- A start countdown or short grace period before the queue begins moving.
- Score variants such as time survived, distance traveled, clean-run bonuses, or near-miss bonuses.
- More queue challenge juice: hit flash, screen shake, sound effects, and goal celebration.
- Authored queue levels with different paths, lane densities, and obstacle rhythms.
- Checkpoints or lives for the platformer.
- Health, invincibility frames, knockback, and combat feedback if enemies become more complex.
- Enemy drops or coin routes that encourage risk/reward platforming.
- A more explicit story premise tying slime hazards and queue challenges together.
- Main menu, pause menu, game-over screen, and victory screen.
- Audio feedback for jumping, coin pickup, damage, queue win, queue fail, and victory.
