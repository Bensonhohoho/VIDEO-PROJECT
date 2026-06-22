extends Label

enum DisplayMode {
	TOTAL_SCORE,
	ROUND_SCORE
}

@export var display_mode: DisplayMode = DisplayMode.TOTAL_SCORE


func _ready() -> void:
	# CanvasLayer keeps this label locked to the screen instead of the world.
	# The signal keeps the HUD updated when coins or queue rewards change score.
	if display_mode == DisplayMode.ROUND_SCORE:
		SaveManager.round_score_changed.connect(_on_round_score_changed)
		_update_round_score_text(SaveManager.get_round_score(), SaveManager.get_target_score())
	else:
		SaveManager.score_changed.connect(_on_score_changed)
		_update_score_text(SaveManager.get_score())


func _exit_tree() -> void:
	if SaveManager.score_changed.is_connected(_on_score_changed):
		SaveManager.score_changed.disconnect(_on_score_changed)
	if SaveManager.round_score_changed.is_connected(_on_round_score_changed):
		SaveManager.round_score_changed.disconnect(_on_round_score_changed)


func _on_score_changed(new_score: int) -> void:
	_update_score_text(new_score)


func _on_round_score_changed(current_score: int, target_score: int) -> void:
	_update_round_score_text(current_score, target_score)


func _update_score_text(new_score: int) -> void:
	text = "Score: " + str(new_score)


func _update_round_score_text(current_score: int, target_score: int) -> void:
	text = "Round: %d / %d" % [current_score, target_score]
