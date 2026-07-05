@tool
extends Node2D

const HOUSE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/BackgroundImage/T_shop_01.png"),
	preload("res://assets/BackgroundImage/T-Drink Shop.png"),
	preload("res://assets/BackgroundImage/T-Vote.png")
]
const DECORATION_ATLAS: Texture2D = preload("res://assets/sprites/world_tileset.png")
const DECORATION_REGIONS: Array[Rect2] = [
	Rect2(0, 64, 16, 32),
	Rect2(16, 64, 16, 32),
	Rect2(32, 64, 32, 32),
	Rect2(0, 96, 16, 16),
	Rect2(16, 96, 16, 16),
	Rect2(32, 96, 16, 16),
	Rect2(48, 96, 16, 16),
	Rect2(64, 96, 16, 16)
]

@export var queue_path_node: NodePath = ^"../QueuePath"
@export var random_seed: int = 1101

@export_category("House Row")
@export var house_count: int = 7
@export var house_row_start_x: float = -80.0
@export var house_row_end_x: float = 1080.0
@export var house_baseline_y: float = -40.0
@export var house_height: float = 150.0

@export_category("Random Decorations")
@export var decoration_count: int = 28
@export var decoration_bounds := Rect2(-220.0, 0.0, 1480.0, 600.0)
@export var path_clearance: float = 165.0
@export var decoration_spacing: float = 58.0
@export var decoration_scale_range := Vector2(2.0, 3.5)

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_generate_scenery()


func _generate_scenery() -> void:
	_clear_generated_scenery()
	_rng.seed = random_seed

	var house_row := Node2D.new()
	house_row.name = "GeneratedHouseRow"
	house_row.z_index = -10
	add_child(house_row)

	var decorations := Node2D.new()
	decorations.name = "GeneratedDecorations"
	decorations.z_index = -5
	add_child(decorations)

	_generate_house_row(house_row)
	_generate_decorations(decorations)


func _clear_generated_scenery() -> void:
	for child in get_children():
		child.free()


func _generate_house_row(container: Node2D) -> void:
	if house_count <= 0:
		return

	for index in range(house_count):
		var texture := HOUSE_TEXTURES[_rng.randi_range(0, HOUSE_TEXTURES.size() - 1)]
		var sprite := Sprite2D.new()
		var x_ratio := 0.5 if house_count == 1 else float(index) / float(house_count - 1)
		var uniform_scale := house_height / float(texture.get_height())

		sprite.name = "House%d" % (index + 1)
		sprite.texture = texture
		sprite.scale = Vector2.ONE * uniform_scale
		sprite.position = Vector2(
			lerpf(house_row_start_x, house_row_end_x, x_ratio),
			house_baseline_y - house_height * 0.5
		)
		container.add_child(sprite)


func _generate_decorations(container: Node2D) -> void:
	var queue_path := get_node_or_null(queue_path_node) as Path2D
	if queue_path == null or queue_path.curve == null:
		push_warning("ProceduralLevelDecor needs a valid QueuePath to place decorations safely.")
		return

	var placed_positions: Array[Vector2] = []
	var max_attempts := maxi(1, decoration_count * 40)
	var attempts := 0

	while placed_positions.size() < decoration_count and attempts < max_attempts:
		attempts += 1
		var candidate := Vector2(
			_rng.randf_range(decoration_bounds.position.x, decoration_bounds.end.x),
			_rng.randf_range(decoration_bounds.position.y, decoration_bounds.end.y)
		)

		if not _is_valid_decoration_position(candidate, queue_path, placed_positions):
			continue

		placed_positions.append(candidate)
		_add_decoration_sprite(container, candidate, placed_positions.size())


func _is_valid_decoration_position(
	candidate: Vector2,
	queue_path: Path2D,
	placed_positions: Array[Vector2]
) -> bool:
	var candidate_on_path := queue_path.to_local(to_global(candidate))
	var closest_path_point := queue_path.curve.get_closest_point(candidate_on_path)
	var closest_path_global := queue_path.to_global(closest_path_point)

	if to_global(candidate).distance_to(closest_path_global) < path_clearance:
		return false

	for placed_position in placed_positions:
		if candidate.distance_to(placed_position) < decoration_spacing:
			return false

	return true


func _add_decoration_sprite(container: Node2D, position_value: Vector2, index: int) -> void:
	var sprite := Sprite2D.new()
	var region := DECORATION_REGIONS[_rng.randi_range(0, DECORATION_REGIONS.size() - 1)]
	var uniform_scale := _rng.randf_range(decoration_scale_range.x, decoration_scale_range.y)

	sprite.name = "Decoration%d" % index
	sprite.texture = DECORATION_ATLAS
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.position = position_value
	sprite.scale = Vector2.ONE * uniform_scale
	sprite.flip_h = _rng.randi_range(0, 1) == 1
	container.add_child(sprite)
