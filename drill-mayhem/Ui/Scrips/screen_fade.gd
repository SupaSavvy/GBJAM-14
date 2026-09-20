extends CanvasLayer


@onready var animation_player: AnimationPlayer = $AnimationPlayer


func fade_to_black() -> void:
	animation_player.play("fade_to_black")

	await animation_player.animation_finished
