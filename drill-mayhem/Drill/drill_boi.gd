class_name Drill
extends CharacterBody2D


signal health_changed(current_health: float, max_health: float)
signal fuel_changed(current_fuel: float, max_fuel: float)
signal speed_changed(current_speed: float)


# MOVEMENT
@export var starting_move_speed: float = 150.0

@export var min_speed: float = 100.0
@export var max_speed: float = 1000.0
@export var acceleration: float = 30.0

@export var turn_speed: float = 2.0
@export var max_turn_angle: float = 45.0


# STARTING POSITION
var drilling_started: bool = false


# HORIZONTAL LIMITS
@export var left_limit: float = -4.0
@export var right_limit: float = 144.0


# DIGGING
@export var ores: Ores

@export var drill_damage: float = 3.0
@export var damage_interval: float = 0.08
@export var dig_radius_pixels: float = 8.0

@export var slow_damage_interval: float = 0.08
@export var fast_damage_interval: float = 0.02
@export var interval_max_speed: float = 150.0


# FUEL / HEALTH
@export var starting_fuel: float = 50.0
@export var max_fuel: float = 100.0
@export var fuel_drain_rate: float = 2.0

@export var max_health: float = 100.0
@export var health_drain_rate: float = 10.0


# TAR
@export var tar_recovery_time: float = 0.5
@export var tar_speed_multiplier: float = 0.35


# MOVEMENT STATE
var current_speed: float = 0.0

# Extra speed added by the Speed Powerup
var powerup_speed_bonus: float = 0.0


# DIGGING STATE
var damage_timer: float = 0.0


# PLAYER STATE
var fuel: float = 0.0
var health: float = 0.0

var in_tar: bool = false
var tar_timer: float = 0.0


# POWERUPS
@onready var speedPU: SpeedPowerup = $Powerups/Speed
@onready var shieldPU: ShieldPowerup = $Powerups/Shield

@onready var drill_particles: CPUParticles2D = $DrillParticles



func _ready() -> void:
	current_speed = min_speed
	fuel = starting_fuel
	health = max_health
	drill_particles.emitting = false

	# Ore signals
	ores.gold_collected.connect(_on_gold_collected)
	ores.stardust_collected.connect(_on_stardust_collected)
	ores.bomb_triggered.connect(_on_bomb_triggered)

	# Starting UI values
	health_changed.emit(
		health,
		max_health
	)

	fuel_changed.emit(
		fuel,
		max_fuel
	)

	speed_changed.emit(
		current_speed
	)


func _physics_process(delta: float) -> void:

	# --------------------------------------------------
	# STARTING POSITION
	# --------------------------------------------------
	# Before drilling starts, the player can move left/right.
	if not drilling_started:
		var start_direction: float = Input.get_axis(
			"ui_left",
			"ui_right"
		)

		velocity.x = start_direction * starting_move_speed
		velocity.y = 0.0

		move_and_slide()

		global_position.x = clamp(
			global_position.x,
			left_limit,
			right_limit
		)

		if Input.is_action_just_pressed("ui_accept"):
			drilling_started = true
			velocity = Vector2.ZERO
			drill_particles.emitting = true

		return


	# --------------------------------------------------
	# POWERUP INPUT
	# --------------------------------------------------
	check_powerup_input()


	# --------------------------------------------------
	# TAR
	# --------------------------------------------------
	check_for_tar(delta)


	# --------------------------------------------------
	# TURNING
	# --------------------------------------------------
	if not in_tar:
		var turn_input: float = Input.get_axis(
			"ui_left",
			"ui_right"
		)

		rotation -= turn_input * turn_speed * delta

		rotation = clamp(
			rotation,
			deg_to_rad(-max_turn_angle),
			deg_to_rad(max_turn_angle)
		)


	# --------------------------------------------------
	# SPEED
	# --------------------------------------------------
	var target_speed: float = max_speed

	if in_tar:
		target_speed = max_speed * tar_speed_multiplier

	current_speed = move_toward(
		current_speed,
		target_speed,
		acceleration * delta
	)


	# Add temporary powerup speed on top of normal speed
	var final_speed: float = (
		current_speed
		+ powerup_speed_bonus
	)

	var move_direction: Vector2 = Vector2.DOWN.rotated(
		rotation
	)

	velocity = move_direction * final_speed

	speed_changed.emit(
		final_speed
	)


	# --------------------------------------------------
	# FUEL / HEALTH
	# --------------------------------------------------
	if fuel > 0.0:
		fuel -= fuel_drain_rate * delta
		fuel = max(
			fuel,
			0.0
		)

		fuel_changed.emit(
			fuel,
			max_fuel
		)

	else:
		health -= health_drain_rate * delta
		health = max(
			health,
			0.0
		)

		health_changed.emit(
			health,
			max_health
		)

		if health <= 0.0:
			die()


	# --------------------------------------------------
	# DIGGING
	# --------------------------------------------------
	damage_timer -= delta

	if damage_timer <= 0.0:
		var cells: Array[Vector2i] = get_tiles_in_dig_radius()


		# Damage increases at specific speed thresholds
		var speed_damage: float = drill_damage

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
			ores.damage_cell(
				cell,
				speed_damage
			)


		# Faster movement = shorter time between damage ticks
		var speed_percent: float = clamp(
			current_speed / interval_max_speed,
			0.0,
			1.0
		)

		var current_damage_interval: float = lerp(
			slow_damage_interval,
			fast_damage_interval,
			speed_percent
		)

		damage_timer = current_damage_interval


	# --------------------------------------------------
	# MOVEMENT
	# --------------------------------------------------
	move_and_slide()

	#-------------------------------------------------
	#DRILLING PARTICLES

	update_drill_particles()
	#-------------------------------------------------
	# Keep Drill inside horizontal boundaries
	global_position.x = clamp(
		global_position.x,
		left_limit,
		right_limit
	)


func get_tiles_in_dig_radius() -> Array[Vector2i]:
	var cells_in_radius: Array[Vector2i] = []

	var tip_local_position: Vector2 = ores.to_local(
		global_position
	)

	var center_cell: Vector2i = ores.local_to_map(
		tip_local_position
	)


	for x: int in range(-1, 2):
		for y: int in range(-1, 2):
			var cell: Vector2i = (
				center_cell
				+ Vector2i(x, y)
			)

			var cell_position: Vector2 = ores.map_to_local(
				cell
			)

			if tip_local_position.distance_to(
				cell_position
			) <= dig_radius_pixels:
				cells_in_radius.append(
					cell
				)


	return cells_in_radius


func check_for_tar(delta: float) -> void:
	var local_position: Vector2 = ores.to_local(
		global_position
	)

	var cell: Vector2i = ores.local_to_map(
		local_position
	)

	var ore_type: String = ores.get_ore_type(
		cell
	)


	# While inside Tar, keep refreshing the timer
	if ore_type == "tar":
		in_tar = true
		tar_timer = tar_recovery_time

	else:
		tar_timer -= delta

		if tar_timer <= 0.0:
			in_tar = false
			tar_timer = 0.0


func check_powerup_input() -> void:
	if Input.is_action_just_pressed(
		"power_up_1"
	):
		use_powerup(
			GameData.equipped_powerup_1
		)

	if Input.is_action_just_pressed(
		"power_up_2"
	):
		use_powerup(
			GameData.equipped_powerup_2
		)


func use_powerup(powerup_name: String) -> void:
	match powerup_name:
		"speed":
			speedPU.use()

		"shield":
			shieldPU.use()

		_:
			pass


func _on_gold_collected() -> void:
	ores.gold_behavior.collect(
		self
	)


func _on_stardust_collected() -> void:
	ores.stardust_behavior.collect(
		self
	)


func _on_bomb_triggered(depth: int) -> void:
	ores.bomb_behavior.trigger(
		self,
		depth
	)

	# Update UI after bomb effects
	health_changed.emit(
		health,
		max_health
	)

	speed_changed.emit(
		current_speed
		+ powerup_speed_bonus
	)



func update_drill_particles() -> void:
	var cells: Array[Vector2i] = get_tiles_in_dig_radius()

	for cell: Vector2i in cells:
		var ore_type: String = ores.get_ore_type(cell)

		if ore_type == "":
			continue

		set_particle_color(ore_type)
		return


func set_particle_color(ore_type: String) -> void:
	match ore_type:
		"stone":
			drill_particles.color = Color.GRAY

		"gold":
			drill_particles.color = Color.GOLD

		"stardust":
			drill_particles.color = Color.WHITE

		"bomb":
			drill_particles.color = Color.WHITE

		"tar":
			drill_particles.color = Color.BLACK

		_:
			drill_particles.color = Color.WHITE


func die() -> void:
	queue_free()
