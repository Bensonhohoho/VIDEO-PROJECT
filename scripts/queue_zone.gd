extends Area2D

var is_moving := true


func stop_moving() -> void:
	# QueueGameManager moves the PathFollow2D parent. This flag is kept so other
	# scripts can still ask the zone whether queue movement should be active.
	is_moving = false


func start_moving() -> void:
	is_moving = true
