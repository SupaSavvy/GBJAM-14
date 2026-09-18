class_name BombBehavior
extends Node


@export var starting_damage: float = 10.0
@export var max_damage: float = 90.0
@export var max_damage_depth: float = 8000.0

@export var speed_loss: float = 30.0
@export var minimum_speed_after_bomb: float = 50.0


func trigger(drill: Drill, depth: int) -> bool:
	# Figure out how far down the player is.
	var depth_percent: float = clamp(
		float(depth) / max_damage_depth,
		0.0,
		1.0
	)

	# Increase bomb damage as the player gets deeper.
	var bomb_damage: float = lerp(
		starting_damage,
		max_damage,
		depth_percent
	)


	# If the Shield is active, block the bomb completely.
	if drill.shieldPU.block_hit():
		return false


	# SCREEN SHAKE
	var camera: Camera2D = drill.get_viewport().get_camera_2d()

	if camera != null and camera.has_method("shake"):
		camera.call(
			"shake",
			6.0
		)


	# DAMAGE
	drill.health -= bomb_damage

	drill.health = max(
		drill.health,
		0.0
	)


	# SLOW THE DRILL
	drill.current_speed -= speed_loss

	drill.current_speed = max(
		drill.current_speed,
		minimum_speed_after_bomb
	)


	# KILL THE PLAYER IF HEALTH REACHES ZERO
	if drill.health <= 0.0:
		drill.die()


	# Bomb successfully hit the player.
	return true
