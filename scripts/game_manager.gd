extends Node

@export var restart_delay := 0.6
@export var death_time_scale := 0.5
@export var coin_score_reward := 1
@export var target_score := 30
@export var victory_label_path: NodePath = ^"../UI/VictoryLabel"

var is_game_over := false
var victory_label: Label


func _ready():
	Engine.time_scale = 1.0
	victory_label = get_node_or_null(victory_label_path) as Label

	# Start a fresh one-round goal only once. Returning from minigames keeps the
	# same autoload round state until the target has been reached.
	SaveManager.ensure_round_started(target_score)
	if not SaveManager.round_completed.is_connected(_on_round_completed):
		SaveManager.round_completed.connect(_on_round_completed)
	_update_victory_state()

	var player = get_tree().get_first_node_in_group("player")
	if player != null and player.has_signal("died"):
		player.died.connect(_on_player_died)


func _exit_tree() -> void:
	if SaveManager.round_completed.is_connected(_on_round_completed):
		SaveManager.round_completed.disconnect(_on_round_completed)


func add_point():
	# Coins now feed the same saved total as the queue mini-game reward.
	SaveManager.add_score(coin_score_reward)


func _on_player_died(_source: Node = null) -> void:
	if is_game_over:
		return

	is_game_over = true
	print("You died!")
	Engine.time_scale = death_time_scale

	await get_tree().create_timer(restart_delay, true, false, true).timeout

	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func _on_round_completed(current_score: int, current_target_score: int) -> void:
	_show_victory(current_score, current_target_score)


func _update_victory_state() -> void:
	if SaveManager.is_round_completed():
		_show_victory(SaveManager.get_round_score(), SaveManager.get_target_score())
	elif victory_label != null:
		victory_label.visible = false


func _show_victory(current_score: int, current_target_score: int) -> void:
	if victory_label == null:
		return

	victory_label.text = "Victory! Goal Completed: %d / %d" % [current_score, current_target_score]
	victory_label.visible = true
