extends Node2D


@export var player: Drill

var fixed_x: float


func _ready() -> void:
	fixed_x = global_position.x


func _physics_process(_delta: float) -> void:
	if player == null:
		return

	# Follow the drill vertically only
	global_position.y = player.global_position.y

	# Never follow it horizontally
	global_position.x = fixed_x
