# Slime Bullet GD Project Guidelines

This document records the architecture decisions learned while refactoring damage,
player death, bullets, and game flow.

## Core Principle

Keep each script responsible for its own domain:

- Bullets handle bullet behavior.
- The player handles player state.
- The game manager handles game flow.
- Hazards only apply damage.

Avoid letting temporary gameplay objects, such as bullets, control global game
state.

## Damage Contract

Godot does not provide a built-in universal damage function. In this project, any
node that can receive damage should expose this method:

```gdscript
func take_damage(amount: int = 1, source: Node = null) -> void:
```

Damage sources should check for the method before calling it:

```gdscript
if body.has_method("take_damage"):
	body.take_damage(1, self)
```

This keeps damage sources independent from concrete node types like `Player`.

## Bullet Responsibilities

Bullet scripts should only handle bullet-specific behavior:

- Movement.
- Lifetime cleanup.
- Collision detection.
- Preventing duplicate hits.
- Calling `take_damage()` on valid targets.
- Removing or disabling the bullet after impact.

Bullet scripts should not:

- Change `Engine.time_scale`.
- Reload the current scene.
- Decide how the player respawns.
- Delete or modify the player's internal nodes directly.
- Contain player-specific death logic such as `kill_player()`.

The bullet may pass itself as the damage source:

```gdscript
target.take_damage(1, self)
```

After that, the target and game flow systems decide what happens next.

## Player Responsibilities

`player.gd` owns player state and player-level consequences of damage:

- Tracking whether the player is already dead.
- Deciding whether damage causes death.
- Stopping player movement after death.
- Disabling player collision after death.
- Emitting a `died` signal.

Recommended shape:

```gdscript
signal died(source)

var is_dead := false

func take_damage(_amount: int = 1, source: Node = null) -> void:
	if is_dead:
		return

	die(source)

func die(source: Node = null) -> void:
	is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	_disable_collision()
	died.emit(source)
```

The player should not decide the whole game mode or scene restart policy unless
the project is still in a very small prototype stage.

## Game Manager Responsibilities

Game start, game over, restart, respawn timing, and scene reload belong in a
manager script such as `game_manager.gd`.

The manager should listen to the player's `died` signal and handle game-level
effects:

- Printing or displaying death/game-over feedback.
- Applying slow motion.
- Waiting before restart.
- Restoring `Engine.time_scale`.
- Reloading the current scene or moving to a game-over screen.

Example:

```gdscript
func _on_player_died(_source: Node = null) -> void:
	if is_game_over:
		return

	is_game_over = true
	Engine.time_scale = death_time_scale

	await get_tree().create_timer(restart_delay, true, false, true).timeout

	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
```

Only this layer should control global flow.

## Hazard Responsibilities

Hazards such as kill zones should behave like damage sources, not like game
managers.

Recommended shape:

```gdscript
func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1, self)
```

Avoid giving each hazard its own scene reload timer. That duplicates game flow
logic and makes future respawn changes harder.

## Signals Over Direct Control

Use signals when one node needs to announce that something happened without
owning the response.

Good example:

- Player emits `died`.
- Game manager decides how the level reacts.

Avoid this pattern:

- Bullet detects player.
- Bullet edits player internals.
- Bullet changes global time.
- Bullet reloads the scene.

That makes a short-lived object responsible for long-lived game rules.

## Collision Cleanup

When disabling a dead player's collision, prefer disabling collision shapes
rather than deleting them with `queue_free()`.

Use deferred changes during physics callbacks:

```gdscript
for child in find_children("*", "CollisionShape2D"):
	child.set_deferred("disabled", true)
```

This keeps the scene tree intact and avoids editing physics state at an unsafe
time.

## When To Add More Architecture

Keep the current lightweight pattern while the game is small:

- `take_damage()` on damageable nodes.
- `died` signal on the player.
- Game flow in `game_manager.gd`.

Consider adding a `HealthComponent` or `DamageInfo` object only when the project
needs more features, such as:

- Enemies that can also take damage.
- Multiple damage types.
- Knockback.
- Invincibility frames.
- Armor or resistances.
- Checkpoints or multiple lives.
- Damage numbers or combat UI.

Do not add these abstractions before they remove real duplication.

## Current Project Convention

For this project, the recommended dependency direction is:

```text
Bullet / Hazard -> take_damage() on target -> Player emits died -> GameManager restarts
```

The reverse direction should be avoided:

```text
Bullet / Hazard -> Player internals -> Engine.time_scale -> reload_current_scene()
```
