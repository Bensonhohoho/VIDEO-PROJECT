extends StaticBody2D

@export var placeholder_size := Vector2(6.0, 10.0)
@export var placeholder_color := Color(0.38, 0.2, 0.62, 0.95)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	_apply_placeholder_shape()


func configure_placeholder(new_size: Vector2) -> void:
	placeholder_size = new_size

	if is_node_ready():
		_apply_placeholder_shape()


func _apply_placeholder_shape() -> void:
	var half_size := placeholder_size * 0.5
	var rectangle := collision_shape.shape as RectangleShape2D
	if rectangle != null:
		rectangle.size = placeholder_size

	visual.color = placeholder_color
	visual.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])
