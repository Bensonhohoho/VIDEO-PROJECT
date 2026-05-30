extends Area2D

@export_file("*.tscn") var target_scene_path := "res://scenes/queue_mini_game.tscn"

var is_changing_scene := false
var player_in_range: Node2D = null


func _physics_process(_delta: float) -> void:
	if player_in_range == null or is_changing_scene:
		return

	if Input.is_action_just_pressed("ui_up"):
		_enter_target_scene()


func _on_body_entered(body: Node2D) -> void:
	if is_changing_scene:
		return

	if not body.is_in_group("player"):
		return

	player_in_range = body


func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null


func _enter_target_scene() -> void:
	is_changing_scene = true
	monitoring = false
	call_deferred("_change_scene")


func _change_scene() -> void:
	if not is_inside_tree():
		return

	var error := get_tree().change_scene_to_file(target_scene_path)
	if error == OK:
		return

	push_error("Could not change to target scene: " + target_scene_path)
	is_changing_scene = false
	monitoring = true
