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
@export var damage_interval: float = 0.08
@export var dig_radius_pixels: float = 8.0


# PLAYER VALUES
@export var max_health: float = 100.0
@export var health_drain_rate: float = 10.0
@export var starting_fuel: float = 50.0
@export var max_fuel: float = 100.0
@export var fuel_drain_rate: float = 2.0



var health: float = 0.0
var current_speed: float = 0.0
var damage_timer: float = 0.0

var gold: int = 0
var fuel: float = 0.0


func _ready() -> void:
	current_speed = min_speed
	fuel = starting_fuel
	health = max_health

	ores.gold_collected.connect(_on_gold_collected)
	ores.stardust_collected.connect(_on_stardust_collected)
	ores.bomb_triggered.connect(_on_bomb_triggered)

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


	# FUEL
	# FUEL / HEALTH
	if fuel > 0.0:
		# Drain fuel normally
		fuel -= fuel_drain_rate * delta
		fuel = max(fuel, 0.0)

	else:
		# Once fuel is empty, start draining health
		health -= health_drain_rate * delta
		health = max(health, 0.0)

	# Die when health reaches 0
	if health <= 0.0:
		die()

	# DIGGING
	damage_timer -= delta

	if damage_timer <= 0.0:
		var cells: Array[Vector2i] = get_tiles_in_dig_radius()

		for cell: Vector2i in cells:
			ores.damage_cell(cell, drill_damage)

		damage_timer = damage_interval


	move_and_slide()

func get_tiles_in_dig_radius() -> Array[Vector2i]:
	var cells_in_radius: Array[Vector2i] = []

	var tip_local_position: Vector2 = ores.to_local(global_position)
	var center_cell: Vector2i = ores.local_to_map(tip_local_position)

	# Check the nearby cells around the drill tip
	for x: int in range(-1, 2):
		for y: int in range(-1, 2):
			var cell: Vector2i = center_cell + Vector2i(x, y)

			var cell_position: Vector2 = ores.map_to_local(cell)

			if tip_local_position.distance_to(cell_position) <= dig_radius_pixels:
				cells_in_radius.append(cell)

	return cells_in_radius


func _on_gold_collected() -> void:
	ores.gold_behavior.collect(self)

func _on_stardust_collected() -> void:
	ores.stardust_behavior.collect(self)
	# Prevent fuel from going above the maximum
	fuel = min(fuel, max_fuel)


func _on_bomb_triggered() -> void:
	ores.bomb_behavior.trigger(self)
	
	
func die() -> void:
	# Temporary death behavior
	queue_free()
