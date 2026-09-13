class_name Drill
extends CharacterBody2D


# MOVEMENT
@export var min_speed: float = 100.0
@export var max_speed: float = 1000.0
@export var acceleration: float = 30.0

@export var turn_speed: float = 2.0
@export var max_turn_angle: float = 45.0


# DIGGING
@export var ores: Ores
@export var drill_damage: float = 1.0
@export var damage_interval: float = 0.3
@export var dig_radius_pixels: float = 8.0


var current_speed: float = 0.0
var damage_timer: float = 0.0


func _ready() -> void:
	current_speed = min_speed


func _physics_process(delta: float) -> void:
	# TURNING
	var turn_input: float = Input.get_axis("ui_left", "ui_right")

	rotation -= turn_input * turn_speed * delta

	rotation = clamp(
		rotation,
		deg_to_rad(-max_turn_angle),
		deg_to_rad(max_turn_angle)
	)


	# SPEED
	current_speed = move_toward(
		current_speed,
		max_speed,
		acceleration * delta
	)

	var move_direction: Vector2 = Vector2.DOWN.rotated(rotation)
	velocity = move_direction * current_speed


	# DIGGING
	damage_timer -= delta

	if damage_timer <= 0.0:
		var cells: Array[Vector2i] = get_tiles_in_dig_radius()

		for cell: Vector2i in cells:
			ores.damage_cell(cell, drill_damage)

		damage_timer = damage_interval


	# MOVEMENT / COLLISION
	move_and_slide()


func get_tiles_in_dig_radius() -> Array[Vector2i]:
	var cells_in_radius: Array[Vector2i] = []

	# Drill tip position inside the Ores TileMapLayer
	var tip_local_position: Vector2 = ores.to_local(global_position)

	# Find the TileMap cell closest to the drill tip
	var center_cell: Vector2i = ores.local_to_map(tip_local_position)

	# Check the nearby cells around the drill tip
	for x: int in range(-1, 2):
		for y: int in range(-1, 2):
			var cell: Vector2i = center_cell + Vector2i(x, y)

			# Get this tile's center position
			var cell_position: Vector2 = ores.map_to_local(cell)

			# Only include tiles close enough to the drill tip
			if tip_local_position.distance_to(cell_position) <= dig_radius_pixels:
				cells_in_radius.append(cell)

	return cells_in_radius
