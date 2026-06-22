extends Node2D

@export var score_per_placeholder := 5
@export var max_placeholders := 10
@export var placeholder_size := Vector2(6.0, 10.0)
@export var placeholder_scene: PackedScene = preload("res://scenes/ScoreCollisionPlaceholder.tscn")
@export var marker_parent_path: NodePath = ^"../ScorePlaceholderMarkers"

var spawned_placeholders: Array[Node2D] = []


func _ready() -> void:
	# Authored markers keep score blockers out of entrances and critical paths.
	_refresh_placeholders(SaveManager.get_score())

	if not SaveManager.score_changed.is_connected(_refresh_placeholders):
		SaveManager.score_changed.connect(_refresh_placeholders)


func _exit_tree() -> void:
	if SaveManager.score_changed.is_connected(_refresh_placeholders):
		SaveManager.score_changed.disconnect(_refresh_placeholders)


func _refresh_placeholders(current_score: int) -> void:
	_clear_placeholders()

	if placeholder_scene == null or score_per_placeholder <= 0:
		return

	var marker_parent := get_node_or_null(marker_parent_path)
	if marker_parent == null:
		return

	var markers := _get_spawn_markers(marker_parent)
	var score_count := floori(float(current_score) / float(score_per_placeholder))
	var placeholder_count := mini(score_count, mini(max_placeholders, markers.size()))

	for index in range(placeholder_count):
		var marker := markers[index]
		var placeholder := placeholder_scene.instantiate() as Node2D
		add_child(placeholder)
		placeholder.global_position = marker.global_position

		if placeholder.has_method("configure_placeholder"):
			placeholder.call("configure_placeholder", placeholder_size)

		spawned_placeholders.append(placeholder)


func _get_spawn_markers(marker_parent: Node) -> Array[Marker2D]:
	var markers: Array[Marker2D] = []

	for child in marker_parent.get_children():
		if child is Marker2D:
			markers.append(child)

	return markers


func _clear_placeholders() -> void:
	for placeholder in spawned_placeholders:
		if is_instance_valid(placeholder):
			placeholder.queue_free()

	spawned_placeholders.clear()
