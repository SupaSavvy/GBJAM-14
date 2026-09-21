class_name BombBehavior
extends Node




@export var speed_loss: float = 30.0
@export var minimum_speed_after_bomb: float = 50.0


func trigger(drill: Drill, depth: int) -> bool:
	# Shield blocks the bomb completely.
	if drill.shieldPU.block_hit():
		return false

	# SCREEN SHAKE
	var camera: Camera2D = drill.get_viewport().get_camera_2d()

	if camera != null and camera.has_method("shake"):
		camera.call("shake", 6.0)

	# REMOVE ONE HEART
	drill.hearts -= 1
	drill.hearts = max(drill.hearts, 0)

	drill.health_changed.emit(
		drill.hearts,
		drill.max_hearts
	)

	# SLOW THE DRILL
	drill.current_speed -= speed_loss
	drill.current_speed = max(
		drill.current_speed,
		minimum_speed_after_bomb
	)

	# BOOST THE VOID
	if drill.void_chaser != null:
		drill.void_chaser.add_danger_boost()

	# DEATH
	if drill.hearts <= 0:
		drill.die()

	return true
