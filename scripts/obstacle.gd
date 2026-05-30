extends Area2D

signal player_touched(body: Node2D)

@export var speed: float = 180.0
@export var movement_direction: Vector2 = Vector2.LEFT
@export var cleanup_x: float = -80.0

var has_hit_player := false


func _ready() -> void:
	# Obstacles announce player contact, but the QueueGameManager decides what
	# happens next. That keeps restart logic in one place.
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	# Move horizontally across the queue gameplay area.
	var direction := movement_direction.normalized()
	global_position += direction * speed * delta

	# Remove old obstacles after they leave the left side of the scene.
	if global_position.x < cleanup_x:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if has_hit_player:
		return

	has_hit_player = true
	player_touched.emit(body)
