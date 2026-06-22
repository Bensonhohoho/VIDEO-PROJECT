extends Node2D

@export var placeholder_size := Vector2(28.0, 42.0)
@export var placeholder_color := Color(0.95, 0.45, 0.35, 0.85)

@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	_apply_placeholder_shape()


func configure_placeholder(new_size: Vector2, new_color: Color) -> void:
	placeholder_size = new_size
	placeholder_color = new_color

	if is_node_ready():
		_apply_placeholder_shape()


func _apply_placeholder_shape() -> void:
	var half_size := placeholder_size * 0.5
	visual.color = placeholder_color
	visual.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])
