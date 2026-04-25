extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	animated_sprite.play("default")


func _on_body_entered(body: Node2D) -> void:
	print("+1 coin!")
	queue_free()
