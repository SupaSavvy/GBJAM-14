extends Camera2D


@export var target: Node2D

# SCREEN SHAKE
@export var shake_fade_speed: float = 18.0

var fixed_x: float
var shake_strength: float = 0.0


func _ready() -> void:
	fixed_x = global_position.x


func _process(delta: float) -> void:
	if target != null:
		global_position = Vector2(
			fixed_x,
			target.global_position.y
		)

	update_shake(delta)


func shake(strength: float = 6.0) -> void:
	# If another shake is already happening,
	# don't replace a stronger shake with a weaker one.
	shake_strength = max(
		shake_strength,
		strength
	)


func update_shake(delta: float) -> void:
	if shake_strength > 0.0:
		offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)

		shake_strength = move_toward(
			shake_strength,
			0.0,
			shake_fade_speed * delta
		)

	else:
		offset = Vector2.ZERO
