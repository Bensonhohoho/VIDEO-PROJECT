extends Node

signal score_changed(new_score: int)

const SAVE_PATH := "user://save_data.json"

var total_score := 0


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


func get_score() -> int:
	return total_score


func reset_save() -> void:
	total_score = 0
	save_game()
	score_changed.emit(total_score)
