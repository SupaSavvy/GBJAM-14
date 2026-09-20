class_name Drill
extends CharacterBody2D


signal health_changed(current_health: float, max_health: float)
signal fuel_changed(current_fuel: float, max_fuel: float)
signal speed_changed(current_speed: float)


# MOVEMENT
@export var starting_move_speed: float = 150.0

@export var min_speed: float = 50.0
@export var max_speed: float = 1000.0
@export var acceleration: float = 5.0

#@export var turn_speed: float = 2.0
#@export var max_turn_angle: float = 45.0
#@export_range(0.1,2.0,0.1) var turn_sensitivity: float = 1.0

# GRID MOVEMENT
@export var grid_move_speed: float = 300.0

var target_x: float = 0.0
var tile_width: float = 0.0


# STARTING POSITION
var drilling_started: bool = false


# HORIZONTAL LIMITS
@export var left_limit: float = -4.0
@export var right_limit: float = 144.0


# DIGGING
@export var ores: Ores
@onready var drill_sound: AudioStreamPlayer2D = $DrillSound

@export var drill_damage: float = 3.0
@export var dig_radius_pixels: float = 8.0

@export var damage_interval: float = 0.08
@export var slow_damage_interval: float = 0.08
@export var fast_damage_interval: float = 0.001
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

#LEADERBOARD MECHANICS
var current_depth: int = 0
var deepest_depth: int = 0

#RUN STATS
var stones_mined: int = 0
var bombs_hit: int = 0
var gold_collected_this_run: int = 0


func _ready() -> void:
	current_speed = min_speed
	fuel = starting_fuel
	health = max_health
	drill_particles.emitting = false

	# Ore signals
	ores.gold_collected.connect(_on_gold_collected)
	ores.stardust_collected.connect(_on_stardust_collected)
	ores.bomb_triggered.connect(_on_bomb_triggered)
	ores.stone_mined.connect(_on_stone_mined)

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
	tile_width = float(ores.tile_set.tile_size.x)
	target_x = global_position.x


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

			# Start the grid from wherever the player chose.
			target_x = global_position.x

			velocity = Vector2.ZERO
			rotation = 0.0

			drill_particles.emitting = true
			drill_sound.play()

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
	# GRID LEFT / RIGHT MOVEMENT
	# --------------------------------------------------
	if not in_tar:

		# One press = one tile left.
		if Input.is_action_just_pressed("ui_left"):
			target_x -= tile_width

		# One press = one tile right.
		if Input.is_action_just_pressed("ui_right"):
			target_x += tile_width


	# Don't allow the target to go outside the level.
	target_x = clamp(
		target_x,
		left_limit,
		right_limit
	)


	# Smoothly slide toward the selected column.
	global_position.x = move_toward(
		global_position.x,
		target_x,
		grid_move_speed * delta
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


	# Add temporary powerup speed on top of normal speed.
	var final_speed: float = (
		current_speed
		+ powerup_speed_bonus
	)


	# Drill now always travels straight downward.
	velocity.x = 0.0
	velocity.y = final_speed


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


		# Damage increases at specific speed thresholds.
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


		# Faster movement = shorter time between damage ticks.
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


	# --------------------------------------------------
	# DRILLING PARTICLES
	# --------------------------------------------------
	update_drill_particles()


	# --------------------------------------------------
	# KEEP DRILL INSIDE HORIZONTAL BOUNDARIES
	# --------------------------------------------------
	global_position.x = clamp(
		global_position.x,
		left_limit,
		right_limit
	)


	# --------------------------------------------------
	# STUFF TO TRACK LEADERBOARD
	# --------------------------------------------------
	var drill_local_position: Vector2 = ores.to_local(
		global_position
	)

	var drill_cell: Vector2i = ores.local_to_map(
		drill_local_position
	)

	current_depth = drill_cell.y

	deepest_depth = max(
		deepest_depth,
		current_depth
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
	gold_collected_this_run += 1

	ores.gold_behavior.collect(self)

	#print("Gold This Run: ", gold_collected_this_run)

func _on_stardust_collected() -> void:
	ores.stardust_behavior.collect(
		self
	)


func _on_bomb_triggered(depth: int) -> void:
	var bomb_hit: bool = ores.bomb_behavior.trigger(
		self,
		depth
	)

	if bomb_hit:
		bombs_hit += 1
		#print("Bombs Hit: ", bombs_hit)

	health_changed.emit(
		health,
		max_health
	)

	speed_changed.emit(
		current_speed + powerup_speed_bonus
	)

func _on_stone_mined() -> void:
	stones_mined += 1

	#print("Stones Mined: ", stones_mined)


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
	GameData.submit_depth(deepest_depth)

	queue_free()
