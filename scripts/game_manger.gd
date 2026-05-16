extends Node

@export var restart_delay := 0.6
@export var death_time_scale := 0.5

var score = 0
var is_game_over := false

@onready var score_label: Label = $"Score label"


func _ready():
	Engine.time_scale = 1.0

	var player = get_tree().get_first_node_in_group("player")
	if player != null and player.has_signal("died"):
		player.died.connect(_on_player_died)


func add_point():
	score += 1
	score_label.text = "You collected " + str(score) + " coins."


func _on_player_died(_source: Node = null) -> void:
	if is_game_over:
		return

	is_game_over = true
	print("You died!")
	Engine.time_scale = death_time_scale

	await get_tree().create_timer(restart_delay, true, false, true).timeout

	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
