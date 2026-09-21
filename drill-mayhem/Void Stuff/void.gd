class_name Void
extends Area2D

@export var drill: Drill

@export var starting_speed: float = 20.0
@export var max_void_speed: float = 140.0
@export var time_to_max_speed: float = 30.0

@export var danger_boost_amount: float = 20.0
@export var danger_boost_duration: float = 3.0

var current_speed: float = 0.0
var danger_boost: float = 0.0
var danger_boost_timer: float = 0.0


func _ready() -> void:
	current_speed = starting_speed

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if drill == null:
		return

	if not drill.drilling_started:
		return

	var acceleration: float = (
		max_void_speed - starting_speed
	) / time_to_max_speed

	current_speed = move_toward(
		current_speed,
		max_void_speed,
		acceleration * delta
	)

	if danger_boost_timer > 0.0:
		danger_boost_timer -= delta

		if danger_boost_timer <= 0.0:
			danger_boost_timer = 0.0
			danger_boost = 0.0

	var final_void_speed: float = (
		current_speed + danger_boost
	)

	global_position.y += final_void_speed * delta


func add_danger_boost() -> void:
	danger_boost = danger_boost_amount
	danger_boost_timer = danger_boost_duration


func _on_body_entered(body: Node2D) -> void:
	if body is Drill:
		body.die("void")
