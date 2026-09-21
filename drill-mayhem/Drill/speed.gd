class_name SpeedPowerup
extends Node

signal activated
signal finished
signal ready_again

@export var drill: Drill
@export var animation_player: AnimationPlayer

# SPEED BOOST
@export var base_boost_amount: float = 20.0
@export var boost_per_level: float = 10.0

@export var acceleration_duration: float = 0.5
@export var hold_duration: float = 1.0
@export var falloff_duration: float = 2.0

@export_range(0.0, 1.0) var ending_speed_percent: float = 0.75

# COOLDOWN
@export var base_cooldown: float = 8.0
@export var cooldown_reduction_per_level: float = 1.0
@export var minimum_cooldown: float = 2.0

var cooldown_timer: float = 0.0
var speed_tween: Tween
var active: bool = false


func _process(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta

		if cooldown_timer <= 0.0:
			cooldown_timer = 0.0
			ready_again.emit()


func use() -> void:
	if drill == null:
		return

	if active:
		return

	if cooldown_timer > 0.0:
		return

	active = true
	activated.emit()

	var level: int = GameData.speed_boost_level

	var boost_amount: float = (
		base_boost_amount
		+ float(level - 1) * boost_per_level
	)

	var cooldown: float = max(
		base_cooldown
		- float(level - 1) * cooldown_reduction_per_level,
		minimum_cooldown
	)

	cooldown_timer = cooldown

	if animation_player != null:
		animation_player.play("speed")

	if speed_tween != null:
		speed_tween.kill()

	speed_tween = create_tween()

	# Slowly build up the speed boost.
	speed_tween.tween_property(
		drill,
		"powerup_speed_bonus",
		boost_amount,
		acceleration_duration
	)

	# Hold the full boost.
	speed_tween.tween_interval(hold_duration)

	# Drop down to part of the boosted speed.
	speed_tween.tween_property(
		drill,
		"powerup_speed_bonus",
		boost_amount * ending_speed_percent,
		falloff_duration
	)

	# Finish by returning to normal.
	speed_tween.tween_property(
		drill,
		"powerup_speed_bonus",
		0.0,
		falloff_duration
	)

	speed_tween.finished.connect(_on_speed_finished)


func _on_speed_finished() -> void:
	active = false

	if animation_player != null:
		animation_player.play("drill")

	finished.emit()
