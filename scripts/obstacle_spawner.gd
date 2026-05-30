extends Node2D

signal player_hit_obstacle(body: Node2D)

@export var obstacle_scene: PackedScene = preload("res://Obstacle.tscn")
@export var obstacle_speed: float = 180.0
@export var spawn_interval: float = 1.25
@export var min_spawn_y: float = 170.0
@export var max_spawn_y: float = 310.0
@export var spawn_x: float = 980.0
@export var cleanup_x: float = -80.0

@onready var timer: Timer = $Timer


func _ready() -> void:
	# Randomize the order of obstacle lanes each time the scene starts.
	randomize()

	timer.timeout.connect(_on_timer_timeout)
	timer.wait_time = spawn_interval
	timer.start()


func stop_spawning() -> void:
	# The manager calls this when the player wins or the scene is restarting.
	timer.stop()


func start_spawning() -> void:
	timer.wait_time = spawn_interval
	timer.start()


func reset_spawning() -> void:
	# Remove any obstacles left from the previous attempt before the next try.
	stop_spawning()
	clear_obstacles()
	start_spawning()


func clear_obstacles() -> void:
	for child in get_children():
		if child is Area2D:
			child.set_deferred("monitoring", false)
			child.queue_free()


func _on_timer_timeout() -> void:
	_spawn_obstacle()


func _spawn_obstacle() -> void:
	if obstacle_scene == null:
		push_warning("ObstacleSpawner needs an obstacle_scene before it can spawn.")
		return

	var obstacle := obstacle_scene.instantiate() as Area2D
	if obstacle == null:
		push_warning("ObstacleSpawner expected obstacle_scene to be an Area2D.")
		return

	var spawn_y := randf_range(min_spawn_y, max_spawn_y)
	obstacle.global_position = Vector2(spawn_x, spawn_y)

	# Pass tuning values from the spawner into each obstacle instance.
	obstacle.set("speed", obstacle_speed)
	obstacle.set("cleanup_x", cleanup_x)

	if obstacle.has_signal("player_touched"):
		obstacle.connect("player_touched", _on_obstacle_player_touched)

	add_child(obstacle)


func _on_obstacle_player_touched(body: Node2D) -> void:
	player_hit_obstacle.emit(body)
