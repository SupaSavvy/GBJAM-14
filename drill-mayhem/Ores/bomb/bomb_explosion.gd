class_name BombExplosion
extends CPUParticles2D


@export var cleanup_time: float = 1.5

@onready var white_sparks: CPUParticles2D = $WhiteSparks


func _ready() -> void:
	# Don't automatically start when entering the scene tree.
	emitting = false
	white_sparks.emitting = false


func explode() -> void:
	# Start both particle systems after we've been positioned.
	restart()
	emitting = true

	white_sparks.restart()
	white_sparks.emitting = true

	print("Explosion particles started at: ", global_position)

	await get_tree().create_timer(cleanup_time).timeout

	queue_free()
