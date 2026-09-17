class_name BombBehavior
extends Node


@export var starting_damage: float = 10.0
@export var max_damage: float = 90.0
@export var max_damage_depth: float = 800.0

@export var speed_loss: float = 30.0
@export var minimum_speed_after_bomb: float = 50.0


func trigger(drill: Drill, depth: int) -> void:
	var depth_percent: float = clamp(
		float(depth) / max_damage_depth,
		0.0,
		1.0
	)

	var bomb_damage: float = lerp(
		starting_damage,
		max_damage,
		depth_percent
	)

	# Let the shield block the bomb first
	if drill.shieldPU.block_hit():
		return

	drill.health -= bomb_damage
	drill.health = max(drill.health, 0.0)

	# Bomb knocks speed down
	drill.current_speed -= speed_loss
	drill.current_speed = max(
		drill.current_speed,
		minimum_speed_after_bomb
	)

	if drill.health <= 0.0:
		drill.die()
