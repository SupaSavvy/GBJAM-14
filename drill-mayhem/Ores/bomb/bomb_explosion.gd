class_name BombExplosion
extends CPUParticles2D


@onready var white_sparks: CPUParticles2D = $WhiteSparks
@onready var boom: AudioStreamPlayer2D = $Boom


func _ready() -> void:
	emitting = false
	white_sparks.emitting = false


func explode() -> void:
	restart()
	emitting = true

	white_sparks.restart()
	white_sparks.emitting = true
	#print("Playing BOomb")
	boom.play()

	# Wait for the sound to finish before deleting the scene.
	await boom.finished

	queue_free()
