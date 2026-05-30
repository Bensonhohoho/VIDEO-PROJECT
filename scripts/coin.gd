extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var game_manager: Node = %GameManager

var is_collected := false


func _ready() -> void:
	animated_sprite.play("default")


func _on_body_entered(_body: Node2D) -> void:
	if is_collected:
		return

	is_collected = true
	monitoring = false
	game_manager.add_point()
	animated_sprite.play("default_2")
	await get_tree().create_timer(0.8).timeout
	queue_free()
