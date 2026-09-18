class_name ShieldPowerup
extends Node


signal activated
signal expired
signal ready_again


@export var drill: Drill
@export var animation_player: AnimationPlayer


# SHIELD SETTINGS
@export var base_duration: float = 3.0
@export var duration_per_level: float = 0.5


# COOLDOWN
@export var base_cooldown: float = 7.0
@export var minimum_cooldown: float = 3.0


var shield_active: bool = false

var duration_timer: float = 0.0
var cooldown_timer: float = 0.0


func _process(delta: float) -> void:

	# Count down how long the Shield stays active
	if shield_active:
		duration_timer -= delta

		if duration_timer <= 0.0:
			duration_timer = 0.0
			end_shield()


	# Count down the cooldown
	if cooldown_timer > 0.0:
		cooldown_timer -= delta

		if cooldown_timer <= 0.0:
			cooldown_timer = 0.0
			ready_again.emit()


func use() -> void:

	# Don't activate another Shield while one is already active
	if shield_active:
		return

	# Don't activate during cooldown
	if cooldown_timer > 0.0:
		return


	var level: int = GameData.shield_level


	# Higher levels make the Shield last longer
	var shield_duration: float = (
		base_duration
		+ (duration_per_level * float(level - 1))
	)


	shield_active = true
	duration_timer = shield_duration


	if animation_player != null:
		animation_player.play("shield")


	activated.emit()


func block_hit() -> bool:

	# While the Shield is active,
	# every bomb hit is blocked.
	if shield_active:
		return true

	return false


func end_shield() -> void:

	shield_active = false
	duration_timer = 0.0


	# Return to normal Drill animation
	if animation_player != null:
		animation_player.play("drill")


	# Start cooldown after the Shield expires
	var level: int = GameData.shield_level

	cooldown_timer = max(
		base_cooldown - float(level - 1),
		minimum_cooldown
	)


	expired.emit()
