class_name Void
extends Area2D


@export var drill: Drill

# VOID SPEED
@export var starting_speed: float = 20.0
@export var max_void_speed: float = 500.0
@export var time_to_max_speed: float = 120.0


var current_speed: float = 0.0


func _ready() -> void:
	current_speed = starting_speed

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if drill == null:
		return

	# Don't move while the player is still choosing
	# their starting position.
	if not drill.drilling_started:
		return


	# Calculate how much speed the Void should gain each second.
	var acceleration: float = (
		max_void_speed - starting_speed
	) / time_to_max_speed


	# Slowly increase the Void's speed.
	current_speed = move_toward(
		current_speed,
		max_void_speed,
		acceleration * delta
	)


	# Move downward.
	global_position.y += current_speed * delta


func _on_body_entered(body: Node2D) -> void:
	# Only kill the Drill.
	if body is Drill:
		body.die()
