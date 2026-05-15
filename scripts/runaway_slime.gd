extends Node2D

const SPEED = 60
const FLEE_SPEED = 120

@export var flee_distance = 80.0

var direction = 1
var player: Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft

func _ready():
	animated_sprite.play("default")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	var is_fleeing = can_see_player_in_flee_range()

	if is_fleeing:
		direction = sign(global_position.x - player.global_position.x)
		if direction == 0:
			direction = 1

	if direction > 0 and ray_cast_right.is_colliding():
		direction = -1
	elif direction < 0 and ray_cast_left.is_colliding():
		direction = 1

	var speed = FLEE_SPEED if is_fleeing else SPEED
	position.x += direction * speed * delta

func can_see_player_in_flee_range():
	if player == null:
		return false

	if global_position.distance_to(player.global_position) > flee_distance:
		return false

	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.collision_mask = 3

	var result = get_world_2d().direct_space_state.intersect_ray(query)
	return not result.is_empty() and result["collider"] == player
