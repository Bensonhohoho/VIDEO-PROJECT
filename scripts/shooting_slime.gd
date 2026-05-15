extends Node2D

const SPEED = 40

@export var attack_range = 160.0
@export var shoot_cooldown = 1.2
@export var bullet_scene: PackedScene = preload("res://scenes/slime_bullet.tscn")

var direction = 1
var player: Node2D
var cooldown_timer = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var shoot_point: Marker2D = $ShootPoint

func _ready():
	animated_sprite.play("default")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	cooldown_timer = max(cooldown_timer - delta, 0.0)
	patrol(delta)

	if can_shoot_player():
		shoot_at_player()

func patrol(delta):
	if direction > 0 and ray_cast_right.is_colliding():
		direction = -1
	elif direction < 0 and ray_cast_left.is_colliding():
		direction = 1

	position.x += direction * SPEED * delta

func shoot_at_player():
	if cooldown_timer > 0.0:
		return

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = shoot_point.global_position
	bullet.setup((get_player_target_position() - shoot_point.global_position).normalized())
	cooldown_timer = shoot_cooldown

func get_player_target_position():
	var collision_shape = player.get_node_or_null("CollisionShape2D")
	if collision_shape == null:
		collision_shape = player.get_node_or_null("AnimatedSprite2D/CollisionShape2D")

	if collision_shape != null:
		return collision_shape.global_position

	return player.global_position

func can_shoot_player():
	if player == null:
		return false

	return global_position.distance_to(player.global_position) <= attack_range
