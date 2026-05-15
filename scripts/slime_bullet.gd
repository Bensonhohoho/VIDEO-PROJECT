extends Area2D

@export var speed = 180.0
@export var life_time = 3.0

var direction = Vector2.RIGHT
var has_hit_player = false

func _ready():
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(life_time).timeout
	if not has_hit_player:
		queue_free()

func _physics_process(delta):
	global_position += direction * speed * delta

func setup(new_direction: Vector2):
	direction = new_direction.normalized()

func _on_body_entered(body: Node2D):
	if has_hit_player:
		return

	if body.is_in_group("player"):
		await kill_player(body)
	else:
		queue_free()

func kill_player(player: Node2D):
	has_hit_player = true
	monitoring = false
	set_physics_process(false)
	hide()

	print("You died!")
	Engine.time_scale = 0.5

	var collision_shape = player.get_node_or_null("CollisionShape2D")
	if collision_shape == null:
		collision_shape = player.get_node_or_null("AnimatedSprite2D/CollisionShape2D")

	if collision_shape != null:
		collision_shape.queue_free()

	await get_tree().create_timer(0.6, true, false, true).timeout
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
