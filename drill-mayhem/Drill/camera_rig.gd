extends Camera2D


@export var target: Node2D

var fixed_x: float


func _ready() -> void:
	fixed_x = global_position.x


func _process(_delta: float) -> void:
	if target == null:
		return

	global_position = Vector2(
		fixed_x,
		target.global_position.y
	)
