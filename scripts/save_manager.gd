extends Node

signal score_changed(new_score: int)
signal round_score_changed(current_score: int, target_score: int)
signal round_completed(current_score: int, target_score: int)

const SAVE_PATH := "user://save_data.json"

var total_score := 0
var current_round_score := 0
var target_score := 30
var minigames_completed_this_round := 0
var round_started := false
var round_is_completed := false


func _ready() -> void:
	# Load once when the autoload is created so every scene can ask for the
	# current saved score immediately.
	load_game()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		total_score = 0
		score_changed.emit(total_score)
		return

	var save_file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null:
		push_error("SaveManager could not open save file for reading.")
		total_score = 0
		score_changed.emit(total_score)
		return

	var save_text := save_file.get_as_text()
	var parsed_data = JSON.parse_string(save_text)
	if not (parsed_data is Dictionary):
		push_error("SaveManager found invalid save data.")
		total_score = 0
		score_changed.emit(total_score)
		return

	total_score = int(parsed_data.get("total_score", 0))
	score_changed.emit(total_score)


func save_game() -> void:
	var save_data := {
		"total_score": total_score
	}

	var save_file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		push_error("SaveManager could not open save file for writing.")
		return

	save_file.store_string(JSON.stringify(save_data))


func add_score(amount: int) -> void:
	if amount <= 0:
		return

	total_score += amount
	save_game()
	score_changed.emit(total_score)


func start_new_round(new_target_score: int = 30) -> void:
	# Round score is temporary game-loop state. It is not written to the save file.
	target_score = max(1, new_target_score)
	current_round_score = 0
	minigames_completed_this_round = 0
	round_started = true
	round_is_completed = false
	round_score_changed.emit(current_round_score, target_score)


func ensure_round_started(new_target_score: int = 30) -> void:
	if round_started:
		round_score_changed.emit(current_round_score, target_score)
		return

	start_new_round(new_target_score)


func add_round_score(amount: int) -> void:
	if amount <= 0 or round_is_completed:
		return

	if not round_started:
		start_new_round(target_score)

	# Queue wins increase both the saved total score and this round's goal score.
	add_score(amount)
	current_round_score += amount
	minigames_completed_this_round += 1
	round_score_changed.emit(current_round_score, target_score)

	if current_round_score >= target_score:
		round_is_completed = true
		round_completed.emit(current_round_score, target_score)


func get_score() -> int:
	return total_score


func get_round_score() -> int:
	return current_round_score


func get_target_score() -> int:
	return target_score


func get_round_level_index() -> int:
	return minigames_completed_this_round


func is_round_completed() -> bool:
	return round_is_completed


func reset_save() -> void:
	total_score = 0
	save_game()
	score_changed.emit(total_score)
	start_new_round(target_score)
