class_name ShieldPowerup
extends Node

signal activated
signal finished
signal ready_again

@export var drill: Drill
@export var animation_player: AnimationPlayer

# SHIELD
@export var base_duration: float = 2.0
@export var duration_per_level: float = 1.0

# COOLDOWN
@export var base_cooldown: float = 10.0
@export var cooldown_reduction_per_level: float = 1.0
@export var minimum_cooldown: float = 3.0

var shield_active: bool = false
var cooldown_timer: float = 0.0
var shield_timer: float = 0.0


func _process(delta: float) -> void:
	if shield_active:
		shield_timer -= delta

		if shield_timer <= 0.0:
			end_shield()

	if cooldown_timer > 0.0:
		cooldown_timer -= delta

		if cooldown_timer <= 0.0:
			cooldown_timer = 0.0
			ready_again.emit()


func use() -> void:
	if drill == null:
		return

	if shield_active:
		return

	if cooldown_timer > 0.0:
		return

	var level: int = GameData.shield_level

	var duration: float = (
		base_duration
		+ float(level - 1) * duration_per_level
	)

	var cooldown: float = max(
		base_cooldown
		- float(level - 1) * cooldown_reduction_per_level,
		minimum_cooldown
	)

	shield_active = true
	shield_timer = duration
	cooldown_timer = cooldown

	if animation_player != null:
		animation_player.play("shield")

	activated.emit()


func end_shield() -> void:
	shield_active = false
	shield_timer = 0.0

	if animation_player != null:
		animation_player.play("drill")

	finished.emit()


func block_hit() -> bool:
	return shield_active
