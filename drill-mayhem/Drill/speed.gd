class_name SpeedPowerup
extends Node


signal activated
signal finished


@export var drill: Drill

# How much speed is added instantly
@export var boost_amount: float = 50.0

# How long it takes to gradually lose part of the boost
@export var falloff_duration: float = 3.0

# The boosted speed eventually settles at 75%
@export_range(0.0, 1.0) var ending_speed_percent: float = 0.75


var speed_tween: Tween


func use() -> void:
	# Stop the old Tween if the powerup is used again
	if speed_tween != null:
		speed_tween.kill()

	var starting_speed: float = drill.current_speed

	# Calculate how fast we are immediately after using the powerup
	var boosted_speed: float = starting_speed + boost_amount

	# Find 75% of that boosted speed
	var ending_speed: float = boosted_speed * ending_speed_percent

	# Since the Drill handles its normal speed separately,
	# convert the desired ending speed into a bonus.
	var ending_bonus: float = max(
		ending_speed - starting_speed,
		0.0
	)

	# Give the player the full boost immediately
	drill.powerup_speed_bonus = boost_amount

	activated.emit()

	# Gradually reduce the bonus
	speed_tween = create_tween()

	speed_tween.tween_property(
		drill,
		"powerup_speed_bonus",
		ending_bonus,
		falloff_duration
	)

	speed_tween.finished.connect(_on_tween_finished)


func _on_tween_finished() -> void:
	finished.emit()
