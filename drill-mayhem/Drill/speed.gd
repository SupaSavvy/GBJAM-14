class_name SpeedPowerup
extends Node


signal activated
signal finished
signal ready_again


@export var drill: Drill
@export var animation_player: AnimationPlayer


# SPEED BOOST SETTINGS
@export var base_boost_amount: float = 200.0

# How long the drill stays at full boosted speed
@export var hold_duration: float = 1.0

# How long it takes to fall back down
@export var falloff_duration: float = 2.0

# 0.75 means the powerup ends at 75% of boosted speed
@export_range(0.0, 1.0) var ending_speed_percent: float = 0.75


# COOLDOWN
@export var base_cooldown: float = 8.0
@export var minimum_cooldown: float = 2.0


var cooldown_timer: float = 0.0
var speed_tween: Tween


func _process(delta: float) -> void:
	# Count down the cooldown
	if cooldown_timer > 0.0:
		cooldown_timer -= delta

		if cooldown_timer <= 0.0:
			cooldown_timer = 0.0
			ready_again.emit()


func use() -> void:
	# Can't use the powerup during cooldown
	if cooldown_timer > 0.0:
		return


	# Stop the previous Tween if one is somehow still running
	if speed_tween != null:
		speed_tween.kill()


	# Start the powerup animation
	if animation_player != null:
		animation_player.play("speed_boost")


	# Get the current powerup level
	var level: int = GameData.speed_boost_level


	# Each level adds more boost
	var boost_amount: float = (
		base_boost_amount
		+ (50.0 * float(level - 1))
	)


	# Save the Drill's normal speed at the moment
	# the powerup is activated
	var starting_speed: float = drill.current_speed


	# Find the total boosted speed
	var boosted_speed: float = (
		starting_speed
		+ boost_amount
	)


	# Find 75% of the boosted speed
	var ending_speed: float = (
		boosted_speed
		* ending_speed_percent
	)


	# Convert that desired ending speed into
	# a bonus value for the Drill
	var ending_bonus: float = max(
		ending_speed - starting_speed,
		0.0
	)


	# Give the Drill the full boost immediately
	drill.powerup_speed_bonus = boost_amount

	activated.emit()


	# Create the Tween
	speed_tween = create_tween()


	# Stay at full boost for a little while
	speed_tween.tween_interval(
		hold_duration
	)


	# Gradually reduce the bonus
	speed_tween.tween_property(
		drill,
		"powerup_speed_bonus",
		ending_bonus,
		falloff_duration
	)


	# When everything finishes,
	# call our cleanup function
	speed_tween.finished.connect(
		_on_speed_finished
	)


func _on_speed_finished() -> void:
	# Return to normal Drill animation
	if animation_player != null:
		animation_player.play("drill")


	# Start cooldown
	var level: int = GameData.speed_boost_level

	cooldown_timer = max(
		base_cooldown - float(level - 1),
		minimum_cooldown
	)


	finished.emit()
