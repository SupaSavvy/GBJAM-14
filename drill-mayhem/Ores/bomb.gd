class_name BombBehavior
extends Node


@export var bomb_damage: float = 60.0
@export var bomb_speed_boost: float = 250.0


func trigger(drill: Drill) -> void:
	# Damage the drill
	drill.health -= bomb_damage
	drill.health = max(drill.health, 0.0)

	# Give the drill a speed boost
	drill.current_speed += bomb_speed_boost
	drill.current_speed = min(
		drill.current_speed,
		drill.max_speed
	)

	# Kill the drill if the bomb reduced health to 0
	if drill.health <= 0.0:
		drill.die()
