extends Node2D

const SPEED = 60

var direction = 1

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft

func _physics_process(delta):
	if direction > 0 and ray_cast_right.is_colliding():
		direction = -1
	elif direction < 0 and ray_cast_left.is_colliding():
		direction = 1

	position.x += direction * SPEED * delta
