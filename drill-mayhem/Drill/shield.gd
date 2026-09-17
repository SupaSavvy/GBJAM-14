class_name ShieldPowerup
extends Node


signal activated
signal expired
signal broken
signal ready_again


@export var shield_duration: float = 3.0
@export var base_cooldown: float = 10.0


var shield_active: bool = false
var cooldown_timer: float = 0.0
var duration_timer: float = 0.0


func _process(delta: float) -> void:
	# Count down the shield duration
	if shield_active:
		duration_timer -= delta

		if duration_timer <= 0.0:
			shield_active = false
			duration_timer = 0.0

			expired.emit()

			start_cooldown()


	# Count down the cooldown
	if cooldown_timer > 0.0:
		cooldown_timer -= delta

		if cooldown_timer <= 0.0:
			cooldown_timer = 0.0

			ready_again.emit()


func use() -> void:
	# Can't use it while already active
	if shield_active:
		return

	# Can't use it during cooldown
	if cooldown_timer > 0.0:
		return

	shield_active = true
	duration_timer = shield_duration

	activated.emit()


func block_hit() -> bool:
	if not shield_active:
		return false

	# Bomb destroys the shield early
	shield_active = false
	duration_timer = 0.0

	broken.emit()

	start_cooldown()

	return true


func start_cooldown() -> void:
	var level: int = GameData.shield_level

	cooldown_timer = max(
		base_cooldown - float(level - 1),
		3.0
	)
