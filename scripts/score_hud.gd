extends Label


func _ready() -> void:
	# CanvasLayer keeps this label locked to the screen instead of the world.
	# The signal keeps the HUD updated when coins or queue rewards change score.
	SaveManager.score_changed.connect(_on_score_changed)
	_update_score_text(SaveManager.get_score())


func _exit_tree() -> void:
	if SaveManager.score_changed.is_connected(_on_score_changed):
		SaveManager.score_changed.disconnect(_on_score_changed)


func _on_score_changed(new_score: int) -> void:
	_update_score_text(new_score)


func _update_score_text(new_score: int) -> void:
	text = "Score: " + str(new_score)
