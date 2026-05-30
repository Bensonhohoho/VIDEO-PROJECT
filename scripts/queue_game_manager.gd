extends Node

@export var player_path: NodePath = ^"../Player"
@export var spawn_point_path: NodePath = ^"../SpawnPoint"
@export var path_follow_path: NodePath = ^"../QueuePath/PathFollow2D"
@export var queue_zone_path: NodePath = ^"../QueuePath/PathFollow2D/QueueZone"
@export var goal_area_path: NodePath = ^"../GoalArea"
@export var obstacle_spawner_path: NodePath = ^"../ObstacleSpawner"
@export var result_label_path: NodePath = ^"../UI/ResultLabel"
@export var fail_count_label_path: NodePath = ^"../UI/FailCountLabel"
@export var queue_move_speed: float = 80.0
@export_file("*.tscn") var main_scene_path := "res://scenes/game.tscn"
@export var max_fail_count: int = 3
@export var queue_score_reward: int = 10
@export var reset_delay: float = 0.25

var player: Node2D
var spawn_point: Marker2D
var path_follow: PathFollow2D
var queue_zone: Area2D
var goal_area: Area2D
var obstacle_spawner: Node
var result_label: Label
var fail_count_label: Label

var fail_count := 0
var player_has_entered_queue := false
var game_started := false
var game_won := false
var is_resetting := false
var is_changing_scene := false


func _ready() -> void:
	# Cache scene nodes once so the signal callbacks can stay small and readable.
	player = get_node_or_null(player_path) as Node2D
	spawn_point = get_node_or_null(spawn_point_path) as Marker2D
	path_follow = get_node_or_null(path_follow_path) as PathFollow2D
	queue_zone = get_node_or_null(queue_zone_path) as Area2D
	goal_area = get_node_or_null(goal_area_path) as Area2D
	obstacle_spawner = get_node_or_null(obstacle_spawner_path)
	result_label = get_node_or_null(result_label_path) as Label
	fail_count_label = get_node_or_null(fail_count_label_path) as Label

	if player == null or spawn_point == null or path_follow == null or queue_zone == null or goal_area == null:
		push_error("QueueGameManager is missing one or more required nodes.")
		return

	queue_zone.body_entered.connect(_on_queue_zone_body_entered)
	queue_zone.body_exited.connect(_on_queue_zone_body_exited)
	goal_area.body_entered.connect(_on_goal_area_body_entered)

	if obstacle_spawner != null and obstacle_spawner.has_signal("player_hit_obstacle"):
		obstacle_spawner.connect("player_hit_obstacle", _on_obstacle_spawner_player_hit_obstacle)

	reset_minigame()


func _physics_process(delta: float) -> void:
	if not game_started or game_won or is_resetting or is_changing_scene:
		return

	# The queue box follows the designer-authored Path2D by moving its
	# PathFollow2D parent forward each physics frame.
	path_follow.progress += queue_move_speed * delta


func reset_minigame() -> void:
	# Reset only the mini-game state so fail_count survives between attempts.
	is_resetting = true
	game_started = false
	game_won = false
	player_has_entered_queue = false

	_show_result("")
	_update_fail_count_label()

	path_follow.progress = 0.0

	if player.has_method("reset_to_spawn"):
		player.call("reset_to_spawn", spawn_point.global_position)
	else:
		player.global_position = spawn_point.global_position

	if queue_zone.has_method("start_moving"):
		queue_zone.call("start_moving")

	if obstacle_spawner != null:
		if obstacle_spawner.has_method("reset_spawning"):
			obstacle_spawner.call("reset_spawning")
		elif obstacle_spawner.has_method("start_spawning"):
			obstacle_spawner.call("start_spawning")

	# Area overlap lists are most reliable after physics has processed the new
	# player and queue positions.
	await get_tree().physics_frame

	if is_changing_scene:
		return

	if queue_zone.overlaps_body(player):
		player_has_entered_queue = true

	is_resetting = false
	game_started = true


func fail_minigame(message: String = "Out of line!") -> void:
	if game_won or is_resetting or is_changing_scene:
		return

	game_started = false
	is_resetting = true
	fail_count += 1

	_stop_active_systems()
	_update_fail_count_label()
	_show_result(message)

	await get_tree().create_timer(reset_delay).timeout

	if fail_count >= max(1, max_fail_count):
		_return_to_main_scene()
	else:
		reset_minigame()


func win_minigame() -> void:
	if game_won or is_resetting or is_changing_scene:
		return

	# This flag blocks late queue-exit or obstacle callbacks from becoming fails.
	game_won = true
	game_started = false

	# Award the queue reward once per successful run. Failed attempts never call
	# this function, and game_won prevents duplicate rewards from repeated signals.
	SaveManager.add_score(queue_score_reward)

	_stop_active_systems()
	_show_result("You stayed in line!")

	await get_tree().create_timer(reset_delay).timeout
	_return_to_main_scene()


func _on_queue_zone_body_entered(body: Node2D) -> void:
	if body != player or game_won or is_resetting or is_changing_scene:
		return

	# Once true, leaving the moving queue zone becomes a fail condition.
	player_has_entered_queue = true


func _on_queue_zone_body_exited(body: Node2D) -> void:
	if body != player or game_won or is_resetting or is_changing_scene:
		return

	if not player_has_entered_queue:
		return

	_handle_queue_exit()


func _on_goal_area_body_entered(body: Node2D) -> void:
	if body != player:
		return

	win_minigame()


func _on_obstacle_spawner_player_hit_obstacle(body: Node2D) -> void:
	if body != player:
		return

	fail_minigame("Hit an obstacle!")


func _handle_queue_exit() -> void:
	# Let same-frame goal detection resolve before treating the queue exit as a
	# loss. This keeps the finish line from feeling unfair when the zone edge and
	# goal overlap in the same physics tick.
	await get_tree().physics_frame

	if game_won or is_resetting or is_changing_scene:
		return

	if goal_area.overlaps_body(player):
		win_minigame()
	else:
		fail_minigame("Out of line!")


func _stop_active_systems() -> void:
	if queue_zone.has_method("stop_moving"):
		queue_zone.call("stop_moving")

	if obstacle_spawner != null and obstacle_spawner.has_method("stop_spawning"):
		obstacle_spawner.call("stop_spawning")


func _return_to_main_scene() -> void:
	if is_changing_scene:
		return

	if main_scene_path.is_empty():
		push_error("QueueGameManager cannot return to the main scene because main_scene_path is empty.")
		return

	is_changing_scene = true
	var error := get_tree().change_scene_to_file(main_scene_path)
	if error != OK:
		push_error("QueueGameManager could not change to main scene: " + main_scene_path)
		is_changing_scene = false


func _show_result(message: String) -> void:
	if result_label == null:
		return

	result_label.text = message
	result_label.visible = not message.is_empty()


func _update_fail_count_label() -> void:
	if fail_count_label == null:
		return

	fail_count_label.text = "Fails: %d / %d" % [fail_count, max(1, max_fail_count)]
