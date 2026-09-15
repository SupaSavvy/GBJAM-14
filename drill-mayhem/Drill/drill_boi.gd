class_name Drill
extends CharacterBody2D


# MOVEMENT
@export var min_speed: float = 100.0
@export var max_speed: float = 1000.0
@export var acceleration: float = 30.0

@export var turn_speed: float = 2.0
@export var max_turn_angle: float = 45.0


# HORIZONTAL LIMITS
@export var left_limit: float = -200.0
@export var right_limit: float = 200.0


# DIGGING
@export var ores: Ores
@export var drill_damage: float = 1.0
@export var damage_interval: float = 0.08
@export var dig_radius_pixels: float = 8.0


# FUEL / HEALTH
@export var starting_fuel: float = 50.0
@export var max_fuel: float = 100.0
@export var fuel_drain_rate: float = 2.0

@export var max_health: float = 100.0
@export var health_drain_rate: float = 10.0


# TAR
@export var tar_recovery_time: float = 0.5
@export var tar_speed_multiplier: float = 0.35


var current_speed: float = 0.0
var damage_timer: float = 0.0

var gold: int = 0
var fuel: float = 0.0
var health: float = 0.0

var in_tar: bool = false
var tar_timer: float = 0.0


func _ready() -> void:
	current_speed = min_speed
	fuel = starting_fuel
	health = max_health

	# Listen for ore events
	ores.gold_collected.connect(_on_gold_collected)
	ores.stardust_collected.connect(_on_stardust_collected)
	ores.bomb_triggered.connect(_on_bomb_triggered)


func _physics_process(delta: float) -> void:
	# Check whether tar is currently affecting the drill
	check_for_tar(delta)


	# TURNING
	if not in_tar:
		var turn_input: float = Input.get_axis("ui_left", "ui_right")

		rotation -= turn_input * turn_speed * delta

		rotation = clamp(
			rotation,
			deg_to_rad(-max_turn_angle),
			deg_to_rad(max_turn_angle)
		)


	# SPEED
	var target_speed: float = max_speed

	if in_tar:
		target_speed = max_speed * tar_speed_multiplier

	current_speed = move_toward(
		current_speed,
		target_speed,
		acceleration * delta
	)

	var move_direction: Vector2 = Vector2.DOWN.rotated(rotation)
	velocity = move_direction * current_speed


	# FUEL / HEALTH
	if fuel > 0.0:
		fuel -= fuel_drain_rate * delta
		fuel = max(fuel, 0.0)

	else:
		health -= health_drain_rate * delta
		health = max(health, 0.0)

		if health <= 0.0:
			die()


	# DIGGING
	damage_timer -= delta

	if damage_timer <= 0.0:
		var cells: Array[Vector2i] = get_tiles_in_dig_radius()

		# Digging damage increases at specific speed thresholds
		var speed_damage: float = 1.0

		match current_speed:
			var speed when speed >= 150.0:
				speed_damage = 4.0

			var speed when speed >= 70.0:
				speed_damage = 3.0

			var speed when speed >= 40.0:
				speed_damage = 2.0

			var speed when speed >= 20.0:
				speed_damage = 1.0

		for cell: Vector2i in cells:
			ores.damage_cell(cell, speed_damage)

		damage_timer = damage_interval
	# MOVE
	move_and_slide()


	# HARD LEFT / RIGHT LIMITS
	# The drill can never move outside these X positions.
	global_position.x = clamp(
		global_position.x,
		left_limit,
		right_limit
	)


func get_tiles_in_dig_radius() -> Array[Vector2i]:
	var cells_in_radius: Array[Vector2i] = []

	var tip_local_position: Vector2 = ores.to_local(global_position)
	var center_cell: Vector2i = ores.local_to_map(tip_local_position)

	for x: int in range(-1, 2):
		for y: int in range(-1, 2):
			var cell: Vector2i = center_cell + Vector2i(x, y)

			var cell_position: Vector2 = ores.map_to_local(cell)

			if tip_local_position.distance_to(cell_position) <= dig_radius_pixels:
				cells_in_radius.append(cell)

	return cells_in_radius


func check_for_tar(delta: float) -> void:
	var local_position: Vector2 = ores.to_local(global_position)
	var cell: Vector2i = ores.local_to_map(local_position)

	var ore_type: String = ores.get_ore_type(cell)

	# While inside tar, keep refreshing the recovery timer
	if ore_type == "tar":
		in_tar = true
		tar_timer = tar_recovery_time

	# After leaving tar, keep the effect active briefly
	else:
		tar_timer -= delta

		if tar_timer <= 0.0:
			in_tar = false
			tar_timer = 0.0


func _on_gold_collected() -> void:
	ores.gold_behavior.collect(self)


func _on_stardust_collected() -> void:
	ores.stardust_behavior.collect(self)


func _on_bomb_triggered(depth: int) -> void:
	ores.bomb_behavior.trigger(self, depth)


func die() -> void:
	# Temporary death behavior
	queue_free()
