class_name BombBehavior
extends Node

@export var speed_loss: float = 100.0
@export var minimum_speed_after_bomb: float = 20.0


func trigger(drill: Drill, _depth: int) -> bool:
	# Shield completely blocks the bomb.
	if drill.shieldPU.block_hit():
		return false

	# Camera shake
	var camera: Camera2D = drill.get_viewport().get_camera_2d()

	if camera != null and camera.has_method("shake"):
		camera.call("shake", 6.0)

	# Bomb removes one heart.
	drill.hearts -= 1
	drill.hearts = max(drill.hearts, 0)

	drill.health_changed.emit(
		drill.hearts,
		drill.max_hearts
	)

	# Bomb slows the player.
	drill.current_speed -= speed_loss
	drill.current_speed = max(
		drill.current_speed,
		minimum_speed_after_bomb
	)

	# Bomb gives the Void a temporary boost.
	if drill.void_chaser != null:
		drill.void_chaser.add_danger_boost()

	# If this bomb removed the final heart,
	# record the death as a bomb death.
	if drill.hearts <= 0:
		drill.die("bomb")

	return true
