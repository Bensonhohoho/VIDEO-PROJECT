extends CharacterBody2D

signal died(source)

const SPEED = 130.0
const JUMP_VELOCITY = -300.0

var is_dead := false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	#test
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("move_left", "move_right")
	
	#Flip the sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
		
	#Play animations 
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")
	
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


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


func _disable_collision() -> void:
	for child in find_children("*", "CollisionShape2D"):
		child.set_deferred("disabled", true)
