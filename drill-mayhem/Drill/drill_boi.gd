class_name Drill
extends CharacterBody2D

signal health_changed(current_hearts: int, max_hearts: int)
signal fuel_changed(current_fuel: float, max_fuel: float)
signal speed_changed(current_speed: float)

# MOVEMENT
@export var min_speed: float = 5.0
@export var max_speed: float = 50.0
@export var acceleration: float = 0.00025
@export var grid_move_speed: float = 300.0

var target_x: float = 0.0
var tile_width: float = 0.0
var drilling_started: bool = false

# LIMITS
@export var left_limit: float = 6.0
@export var right_limit: float = 48.0

# REFERENCES
@export var void_chaser: Void
@export var ores: Ores

@onready var drill_sound: AudioStreamPlayer2D = $DrillSound

# DIGGING
@export var drill_damage: float = 3.0
@export var dig_radius_pixels: float = 12.0
@export var slow_damage_interval: float = 0.08
@export var fast_damage_interval: float = 0.001
@export var interval_max_speed: float = 150.0

var damage_timer: float = 0.0

# FUEL
@export var starting_fuel: float = 50.0
@export var max_fuel: float = 100.0
@export var fuel_drain_rate: float = 2.0
@export var heart_drain_interval: float = 5.0

var fuel: float = 0.0
var heart_drain_timer: float = 0.0

# HEARTS
var max_hearts: int = 3
var hearts: int = 3

# TAR
@export var tar_recovery_time: float = 0.5
@export var tar_speed_multiplier: float = 0.50
@export var tar_slowdown_speed: float = 30.0

var in_tar: bool = false
var tar_timer: float = 0.0

# SPEED
var current_speed: float = 0.0
var powerup_speed_bonus: float = 0.0

# POWERUPS
@onready var speedPU: SpeedPowerup = $Powerups/Speed
@onready var shieldPU: ShieldPowerup = $Powerups/Shield

# PARTICLES
@onready var drill_particles: CPUParticles2D = $DrillParticles
@onready var black_particles: CPUParticles2D = $DrillParticles/Black
@onready var red_particles: CPUParticles2D = $DrillParticles/Red
@onready var gold_particles: CPUParticles2D = $DrillParticles/Gold

# RUN STATS
var current_depth: int = 0
var deepest_depth: int = 0
var stones_mined: int = 0
var bombs_hit: int = 0
var gold_collected_this_run: int = 0

# DEATH
var is_dead: bool = false
var death_cause: String = ""


func _ready() -> void:
	current_speed = min_speed
	fuel = starting_fuel

	max_hearts = clamp(GameData.health_level, 3, 5)
	hearts = max_hearts

	drill_particles.emitting = false
	black_particles.emitting = false
	red_particles.emitting = false
	gold_particles.emitting = false

	ores.gold_collected.connect(_on_gold_collected)
	ores.stardust_collected.connect(_on_stardust_collected)
	ores.bomb_triggered.connect(_on_bomb_triggered)
	ores.stone_mined.connect(_on_stone_mined)

	health_changed.emit(hearts, max_hearts)
	fuel_changed.emit(fuel, max_fuel)
	speed_changed.emit(current_speed)

	tile_width = float(ores.tile_set.tile_size.x)
	target_x = global_position.x


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# STARTING POSITION
	if not drilling_started:
		if Input.is_action_just_pressed("ui_left"):
			target_x -= tile_width

		if Input.is_action_just_pressed("ui_right"):
			target_x += tile_width

		target_x = clamp(target_x, left_limit, right_limit)
		target_x = snap_x_to_grid(target_x)

		global_position.x = move_toward(
			global_position.x,
			target_x,
			grid_move_speed * delta
		)

		velocity = Vector2.ZERO

		if Input.is_action_just_pressed("ui_accept"):
			drilling_started = true
			target_x = snap_x_to_grid(global_position.x)
			global_position.x = target_x

			drill_particles.emitting = true
			drill_sound.play()

		return

	# POWERUPS
	check_powerup_input()

	# TAR
	check_for_tar(delta)

	# GRID MOVEMENT
	if not in_tar:
		if Input.is_action_just_pressed("ui_left"):
			target_x -= tile_width

		if Input.is_action_just_pressed("ui_right"):
			target_x += tile_width

	target_x = clamp(target_x, left_limit, right_limit)
	target_x = snap_x_to_grid(target_x)

	global_position.x = move_toward(
		global_position.x,
		target_x,
		grid_move_speed * delta
	)

	# SPEED
	var target_speed: float = max_speed

	if in_tar:
		target_speed = max_speed * tar_speed_multiplier

		current_speed = move_toward(
			current_speed,
			target_speed,
			tar_slowdown_speed * delta
		)

	else:
		current_speed = move_toward(
			current_speed,
			target_speed,
			acceleration * delta
		)

	var final_speed: float = current_speed + powerup_speed_bonus

	velocity.x = 0.0
	velocity.y = final_speed

	speed_changed.emit(final_speed)

	# FUEL / HEARTS
	if fuel > 0.0:
		fuel -= fuel_drain_rate * delta
		fuel = max(fuel, 0.0)

		heart_drain_timer = 0.0
		fuel_changed.emit(fuel, max_fuel)

	else:
		heart_drain_timer += delta

		if heart_drain_timer >= heart_drain_interval:
			heart_drain_timer = 0.0

			hearts -= 1
			hearts = max(hearts, 0)

			health_changed.emit(hearts, max_hearts)

			if hearts <= 0:
				die("fuel")
				return

	# DIGGING
	damage_timer -= delta

	if damage_timer <= 0.0:
		var cells: Array[Vector2i] = get_tiles_in_dig_radius()
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
			ores.damage_cell(cell, speed_damage)

		var speed_percent: float = clamp(
			current_speed / interval_max_speed,
			0.0,
			1.0
		)

		damage_timer = lerp(
			slow_damage_interval,
			fast_damage_interval,
			speed_percent
		)

	move_and_slide()

	update_drill_particles()

	global_position.x = clamp(
		global_position.x,
		left_limit,
		right_limit
	)

	# DEPTH
	var drill_local_position: Vector2 = ores.to_local(global_position)
	var drill_cell: Vector2i = ores.local_to_map(drill_local_position)

	current_depth = drill_cell.y
	deepest_depth = max(deepest_depth, current_depth)


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

	if ore_type == "tar":
		if not in_tar and void_chaser != null:
			void_chaser.add_danger_boost()

		in_tar = true
		tar_timer = tar_recovery_time

	else:
		tar_timer -= delta

		if tar_timer <= 0.0:
			in_tar = false
			tar_timer = 0.0


func check_powerup_input() -> void:
	if Input.is_action_just_pressed("power_up_1"):
		use_powerup(GameData.equipped_powerup_1)

	if Input.is_action_just_pressed("power_up_2"):
		use_powerup(GameData.equipped_powerup_2)


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


func _on_stardust_collected() -> void:
	ores.stardust_behavior.collect(self)


func _on_bomb_triggered(depth: int) -> void:
	var bomb_hit: bool = ores.bomb_behavior.trigger(self, depth)

	if bomb_hit:
		bombs_hit += 1

	health_changed.emit(hearts, max_hearts)
	speed_changed.emit(current_speed + powerup_speed_bonus)


func _on_stone_mined() -> void:
	stones_mined += 1


func update_drill_particles() -> void:
	if not drilling_started:
		drill_particles.emitting = false
		gold_particles.emitting = false
		red_particles.emitting = false
		black_particles.emitting = false
		return

	drill_particles.emitting = true
	gold_particles.emitting = current_speed >= 40.0
	red_particles.emitting = current_speed >= 70.0
	black_particles.emitting = current_speed >= 150.0


func snap_x_to_grid(world_x: float) -> float:
	var local_pos: Vector2 = ores.to_local(
		Vector2(world_x, global_position.y)
	)

	var cell: Vector2i = ores.local_to_map(local_pos)
	var snapped_local: Vector2 = ores.map_to_local(cell)
	var snapped_world: Vector2 = ores.to_global(snapped_local)

	return snapped_world.x


func die(cause: String) -> void:
	if is_dead:
		return

	is_dead = true
	death_cause = cause

	print("DIED FROM: ", death_cause)

	hearts = 0
	health_changed.emit(hearts, max_hearts)

	velocity = Vector2.ZERO

	# SAVE THE RUN INFO BEFORE THE DRILL DISAPPEARS
	GameData.last_death_cause = death_cause
	GameData.last_stones_mined = stones_mined
	GameData.last_gold_collected = gold_collected_this_run
	GameData.last_depth = deepest_depth

	# TELL THE UI TO OPEN THE DEATH MENU
	GameData.player_died.emit()

	GameData.submit_depth(deepest_depth)

	await get_tree().process_frame
	queue_free()
