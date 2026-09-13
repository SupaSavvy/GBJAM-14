class_name Drill
extends CharacterBody2D


@export var drill_speed: float = 100.0
@export var dirt: TileMapLayer


func _physics_process(_delta: float) -> void:
	velocity = Vector2.ZERO

	if Input.is_action_pressed("drill"):
		velocity.y = drill_speed
		dig()

	move_and_slide()


func dig() -> void:
	if dirt == null:
		return

	var dirt_position: Vector2 = dirt.to_local(global_position)

	var cell: Vector2i = dirt.local_to_map(dirt_position)

	if dirt.get_cell_source_id(cell) != -1:
		dirt.erase_cell(cell)
