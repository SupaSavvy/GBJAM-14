class_name BombBehavior
extends Node


@export var starting_damage: float = 30.0
@export var max_damage: float = 90.0

# How deep you have to go before bombs reach max damage
@export var max_damage_depth: float = 300.0

@export var bomb_speed_boost: float = 30.0


func trigger(drill: Drill, depth: int) -> void:
	# Turn the current depth into a value between 0 and 1
	var depth_percent: float = clamp(
		float(depth) / max_damage_depth,
		0.0,
		1.0
	)

	# Slowly increase bomb damage as the player gets deeper
	var bomb_damage: float = lerp(
		starting_damage,
		max_damage,
		depth_percent
	)

	# Damage the drill
	drill.health -= bomb_damage
	drill.health = max(drill.health, 0.0)

	# Give the drill a speed boost
	drill.current_speed += bomb_speed_boost
	drill.current_speed = min(
		drill.current_speed,
		drill.max_speed
	)

	if drill.health <= 0.0:
		drill.die()
