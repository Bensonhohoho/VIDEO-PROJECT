extends CharacterBody2D

@export var move_speed: float = 220.0


func _physics_process(_delta: float) -> void:
	# This tiny fallback controller is only here because the queue mini-game does
	# not reuse the platformer Player movement script.
	var input_direction := _get_input_direction()
	velocity = input_direction * move_speed
	move_and_slide()


func reset_to_spawn(spawn_position: Vector2) -> void:
	# The mini-game manager uses this when preparing the scene.
	global_position = spawn_position
	velocity = Vector2.ZERO


func _get_input_direction() -> Vector2:
	# Godot's built-in ui_* actions cover arrow keys. The direct key checks make
	# WASD work without requiring project-wide input map changes.
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var wasd_direction := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	)

	if wasd_direction.length_squared() > 0.0:
		direction = wasd_direction.normalized()

	return direction
