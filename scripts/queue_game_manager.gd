extends Node

@export var player_path: NodePath = ^"../Player"
@export var spawn_point_path: NodePath = ^"../SpawnPoint"
@export var path_follow_path: NodePath = ^"../QueuePath/PathFollow2D"
@export var queue_zone_path: NodePath = ^"../QueuePath/PathFollow2D/QueueZone"
@export var goal_area_path: NodePath = ^"../GoalArea"
@export var obstacle_spawner_path: NodePath = ^"../ObstacleSpawner"
@export var result_label_path: NodePath = ^"../UI/ResultLabel"
@export var fail_count_label_path: NodePath = ^"../UI/FailCountLabel"
@export var drink_uses_label_path: NodePath = ^"../UI/DrinkUsesLabel"
@export var buff_time_label_path: NodePath = ^"../UI/BuffTimeLabel"
@export var queue_zone_size: Vector2 = Vector2(240.0, 160.0)
@export var queue_move_speed: float = 80.0
@export var obstacle_speed: float = 180.0
@export var spawn_interval: float = 1.25
@export var score_reward: int = 10
@export var drink_uses_per_minigame: int = 2
@export var drink_buff_duration: float = 3.0
@export var npc_count: int = 4
@export var npc_spacing: float = 64.0
@export var npc_safety_margin: float = 16.0
@export var npc_placeholder_size: Vector2 = Vector2(28.0, 42.0)
@export var npc_placeholder_scene: PackedScene = preload("res://scenes/QueueNPCPlaceholder.tscn")
@export_file("*.tscn") var main_scene_path := "res://scenes/game.tscn"
@export var max_fail_count: int = 3
@export var reset_delay: float = 0.25

var player: Node2D
var spawn_point: Marker2D
var path_follow: PathFollow2D
var queue_zone: Area2D
var goal_area: Area2D
var obstacle_spawner: Node
var result_label: Label
var fail_count_label: Label
var drink_uses_label: Label
var buff_time_label: Label

var fail_count := 0
var drink_uses_remaining := 0
var drink_buff_time_left := 0.0
var player_has_entered_queue := false
var game_started := false
var game_won := false
var is_resetting := false
var is_changing_scene := false
var queue_npc_entries: Array[Dictionary] = []


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
	drink_uses_label = get_node_or_null(drink_uses_label_path) as Label
	buff_time_label = get_node_or_null(buff_time_label_path) as Label

	if player == null or spawn_point == null or path_follow == null or queue_zone == null or goal_area == null:
		push_error("QueueGameManager is missing one or more required nodes.")
		return

	drink_uses_remaining = max(0, drink_uses_per_minigame)
	_apply_level_settings()
	_setup_queue_npcs()

	queue_zone.body_entered.connect(_on_queue_zone_body_entered)
	queue_zone.body_exited.connect(_on_queue_zone_body_exited)
	goal_area.body_entered.connect(_on_goal_area_body_entered)

	if obstacle_spawner != null and obstacle_spawner.has_signal("player_hit_obstacle"):
		obstacle_spawner.connect("player_hit_obstacle", _on_obstacle_spawner_player_hit_obstacle)

	reset_minigame()


func _physics_process(delta: float) -> void:
	if game_started and not game_won and not is_resetting and not is_changing_scene:
		if Input.is_action_just_pressed("use_drink"):
			_use_drink()

		_update_drink_buff(delta)

	if not game_started or game_won or is_resetting or is_changing_scene:
		return

	# The queue box follows the designer-authored Path2D by moving its
	# PathFollow2D parent forward each physics frame.
	path_follow.progress += queue_move_speed * delta
	_update_queue_npc_positions()


func reset_minigame() -> void:
	# Reset only the mini-game state so fail_count survives between attempts.
	is_resetting = true
	game_started = false
	game_won = false
	player_has_entered_queue = false
	drink_buff_time_left = 0.0

	_show_result("")
	_update_fail_count_label()
	_update_drink_ui()

	path_follow.progress = 0.0
	_reset_queue_npcs()

	if player.has_method("reset_to_spawn"):
		player.call("reset_to_spawn", spawn_point.global_position)
	else:
		player.global_position = spawn_point.global_position

	if queue_zone.has_method("start_moving"):
		queue_zone.call("start_moving")
	_set_queue_npcs_active(true)

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
	SaveManager.add_round_score(score_reward)

	_stop_active_systems()
	drink_buff_time_left = 0.0
	_update_drink_ui()

	if SaveManager.is_round_completed():
		_show_result("Goal completed!")
	else:
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

	if _is_drink_buff_active():
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

	_set_queue_npcs_active(false)

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


func _apply_level_settings() -> void:
	# Level scenes tune these exports while keeping the same queue path scene.
	var collision_shape := queue_zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null and collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = queue_zone_size

	var visual := queue_zone.get_node_or_null("Visual") as Polygon2D
	if visual != null:
		var half_size := queue_zone_size * 0.5
		visual.polygon = PackedVector2Array([
			Vector2(-half_size.x, -half_size.y),
			Vector2(half_size.x, -half_size.y),
			Vector2(half_size.x, half_size.y),
			Vector2(-half_size.x, half_size.y)
		])

	if obstacle_spawner != null:
		obstacle_spawner.set("obstacle_speed", obstacle_speed)
		obstacle_spawner.set("spawn_interval", spawn_interval)


func _use_drink() -> void:
	if drink_uses_remaining <= 0 or _is_drink_buff_active():
		return

	# The drink only ignores obstacles. Queue-zone exits still fail normally.
	drink_uses_remaining -= 1
	drink_buff_time_left = drink_buff_duration
	_update_drink_ui()


func _update_drink_buff(delta: float) -> void:
	if drink_buff_time_left <= 0.0:
		return

	drink_buff_time_left = max(0.0, drink_buff_time_left - delta)
	_update_drink_ui()


func _is_drink_buff_active() -> bool:
	return drink_buff_time_left > 0.0


func _update_drink_ui() -> void:
	if drink_uses_label != null:
		drink_uses_label.text = "Drinks: %d" % drink_uses_remaining

	if buff_time_label == null:
		return

	if _is_drink_buff_active():
		buff_time_label.text = "Buff: %.1fs" % drink_buff_time_left
	else:
		buff_time_label.text = "Buff: --"


func _setup_queue_npcs() -> void:
	if npc_count <= 0 or npc_placeholder_scene == null:
		return

	var queue_path := path_follow.get_parent() as Path2D
	if queue_path == null:
		return

	var safe_spacing := _get_safe_npc_spacing()
	var npc_colors := [
		Color(0.95, 0.45, 0.35, 0.85),
		Color(0.3, 0.55, 1.0, 0.85),
		Color(1.0, 0.78, 0.25, 0.85),
		Color(0.5, 0.9, 0.55, 0.85)
	]

	for index in range(npc_count):
		var npc_follow := PathFollow2D.new()
		npc_follow.name = "QueueNPCFollow%d" % (index + 1)
		npc_follow.rotates = false
		npc_follow.loop = false
		npc_follow.add_to_group("queue_npc_path_follow")
		queue_path.add_child(npc_follow)

		var npc := npc_placeholder_scene.instantiate()
		npc_follow.add_child(npc)

		if npc.has_method("configure_placeholder"):
			npc.call("configure_placeholder", npc_placeholder_size, npc_colors[index % npc_colors.size()])

		var side := 1.0 if index % 2 == 0 else -1.0
		var distance_step := floori(float(index) / 2.0) + 1
		queue_npc_entries.append({
			"follow": npc_follow,
			"offset": safe_spacing * distance_step * side
		})

	_reset_queue_npcs()


func _get_safe_npc_spacing() -> float:
	var queue_extent := maxf(queue_zone_size.x, queue_zone_size.y) * 0.5
	var npc_extent := maxf(npc_placeholder_size.x, npc_placeholder_size.y) * 0.5
	return maxf(npc_spacing, queue_extent + npc_extent + npc_safety_margin)


func _reset_queue_npcs() -> void:
	_update_queue_npc_positions()
	_set_queue_npcs_active(true)


func _update_queue_npc_positions() -> void:
	if queue_npc_entries.is_empty():
		return

	var queue_path := path_follow.get_parent() as Path2D
	if queue_path == null or queue_path.curve == null:
		return

	var path_length := queue_path.curve.get_baked_length()
	for entry in queue_npc_entries:
		var npc_follow := entry["follow"] as PathFollow2D
		if npc_follow == null:
			continue

		var target_progress := path_follow.progress + float(entry["offset"])
		var is_on_path := target_progress >= 0.0 and target_progress <= path_length
		npc_follow.visible = is_on_path

		if is_on_path:
			npc_follow.progress = target_progress


func _set_queue_npcs_active(is_active: bool) -> void:
	for entry in queue_npc_entries:
		var npc_follow := entry["follow"] as PathFollow2D
		if npc_follow != null:
			npc_follow.process_mode = Node.PROCESS_MODE_INHERIT if is_active else Node.PROCESS_MODE_DISABLED
