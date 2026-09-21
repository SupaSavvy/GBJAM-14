class_name Ores
extends TileMapLayer

signal gold_collected
signal stardust_collected
signal bomb_triggered(depth: int)
signal stone_mined

# SOUND
@onready var block_break: AudioStreamPlayer = $BlockBreak
@onready var gold_break: AudioStreamPlayer = $GoldBreak

@export var block_break_sound_interval: float = 0.08
var block_break_sound_timer: float = 0.0

# TILE HEALTH
@export var default_tile_health: float = 3.0

# GENERATION
@export var source_id: int = 0
@export var stone_tile: Vector2i
@export var gold_tile: Vector2i
@export var tar_tile: Vector2i
@export var stardust_tile: Vector2i
@export var bomb_tile: Vector2i
@export var bomb_explosion_scene: PackedScene

@export var chunk_height: int = 12
@export var chunks_ahead: int = 3
@export var left_edge: int = -14
@export var generation_padding: int = 5


@export var drill: Drill
@export var generation_cutoff: Marker2D

# DEPTH PROGRESSION
@export var tar_start_depth: int = 30
@export var gold_start_depth: int = 100
@export var bomb_start_depth: int = 150
@export var bomb_full_rate_depth: int = 8000
@export var deep_start_depth: int = 400
@export var stardust_fade_start_depth: int = 80
@export var stardust_gone_depth: int = 300

# TILE DATA
var tile_health: Dictionary = {}
var generated_chunks: Dictionary = {}

# ORE BEHAVIORS
@onready var bomb_behavior: BombBehavior = $Bomb
@onready var stardust_behavior: StardustBehavior = $Stardust
@onready var gold_behavior: GoldBehavior = $Gold


func _process(delta: float) -> void:
	if block_break_sound_timer > 0.0:
		block_break_sound_timer -= delta

	if drill == null:
		return

	var drill_local_position: Vector2 = to_local(drill.global_position)
	var drill_cell: Vector2i = local_to_map(drill_local_position)

	var current_chunk_y: int = floori(
		float(drill_cell.y) / float(chunk_height)
	)

	for chunk_offset: int in range(chunks_ahead + 1):
		var chunk_y: int = current_chunk_y + chunk_offset

		if not generated_chunks.has(chunk_y):
			generate_chunk(chunk_y)


func generate_chunk(chunk_y: int) -> void:
	if generation_cutoff == null:
		return

	generated_chunks[chunk_y] = true

	var start_y: int = chunk_y * chunk_height

	var cutoff_local: Vector2 = to_local(
		generation_cutoff.global_position
	)

	var cutoff_x: int = local_to_map(
		cutoff_local
	).x

	var generation_left: int = left_edge - generation_padding 

	for y: int in range(start_y, start_y + chunk_height):
		for x: int in range(generation_left, cutoff_x):
			var cell: Vector2i = Vector2i(x, y)
			var tile: Vector2i = choose_random_tile(y)

			set_cell(
				cell,
				source_id,
				tile
			)

	# TAR CLUSTERS
	if start_y >= tar_start_depth:
		var tar_cluster_amount: int = randi_range(1, 3)

		for i: int in range(tar_cluster_amount):
			var tar_x: int = randi_range(
				generation_left + 2,
				cutoff_x - 3
			)

			var tar_y: int = randi_range(
				start_y + 2,
				start_y + chunk_height - 3
			)

			generate_tar_cluster(
				Vector2i(tar_x, tar_y)
			)


func choose_random_tile(depth: int) -> Vector2i:
	# Bomb chance ramps from 0.2% to 2%.
	var bomb_depth_percent: float = clamp(
		float(depth - bomb_start_depth)
		/ float(bomb_full_rate_depth - bomb_start_depth),
		0.0,
		1.0
	)

	var bomb_chance: float = lerp(
		0.2,
		2.0,
		bomb_depth_percent
	)

	if depth >= bomb_start_depth:
		var bomb_roll: float = randf() * 100.0

		if bomb_roll < bomb_chance:
			return bomb_tile

	# Stardust fades out with depth.
	var stardust_multiplier: float = 1.0

	if depth >= stardust_fade_start_depth:
		stardust_multiplier = 1.0 - clamp(
			float(depth - stardust_fade_start_depth)
			/ float(stardust_gone_depth - stardust_fade_start_depth),
			0.0,
			1.0
		)

	var gold_chance: float = 0.0
	var stardust_chance: float = 0.0

	if depth < tar_start_depth:
		stardust_chance = 4.0

	elif depth < gold_start_depth:
		stardust_chance = 4.0

	elif depth < bomb_start_depth:
		gold_chance = 1.0
		stardust_chance = 5.0

	elif depth < deep_start_depth:
		gold_chance = 1.5
		stardust_chance = 5.0

	else:
		gold_chance = 2.0
		stardust_chance = 5.0

	stardust_chance *= stardust_multiplier

	var ore_roll: float = randf() * 100.0

	if ore_roll < gold_chance:
		return gold_tile

	if ore_roll < gold_chance + stardust_chance:
		return stardust_tile

	return stone_tile


func generate_tar_cluster(center: Vector2i) -> void:
	if generation_cutoff == null:
		return

	var offsets: Array[Vector2i] = [
		Vector2i.ZERO,
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.DOWN
	]

	if randf() < 0.7:
		offsets.append(Vector2i(-1, -1))

	if randf() < 0.7:
		offsets.append(Vector2i(1, 1))

	if randf() < 0.5:
		offsets.append(Vector2i(-2, 0))

	if randf() < 0.5:
		offsets.append(Vector2i(2, 0))

	var cutoff_local: Vector2 = to_local(
		generation_cutoff.global_position
	)

	var cutoff_x: int = local_to_map(
		cutoff_local
	).x

	for offset: Vector2i in offsets:
		var cell: Vector2i = center + offset

		# Don't let tar cross the cutoff.
		if cell.x >= cutoff_x:
			continue

		# Only replace stone.
		if get_ore_type(cell) != "stone":
			continue

		set_cell(
			cell,
			source_id,
			tar_tile
		)


func damage_cell(cell: Vector2i, damage: float) -> void:
	if get_cell_source_id(cell) == -1:
		return

	var ore_type: String = get_ore_type(cell)

	if ore_type == "tar":
		return

	if not tile_health.has(cell):
		tile_health[cell] = get_tile_max_health(cell)

	tile_health[cell] -= damage

	if tile_health[cell] <= 0.0:
		break_cell(cell)


func get_tile_max_health(cell: Vector2i) -> float:
	var ore_type: String = get_ore_type(cell)

	match ore_type:
		"stone":
			return 4.0

		"gold":
			return 3.0

		"stardust":
			return 1.0

		"bomb":
			return 1.0

		"tar":
			return 0.0

		_:
			return default_tile_health


func get_ore_type(cell: Vector2i) -> String:
	var tile_data: TileData = get_cell_tile_data(cell)

	if tile_data == null:
		return ""

	return tile_data.get_custom_data("ore_type")


func break_cell(cell: Vector2i) -> void:
	var ore_type: String = get_ore_type(cell)

	if ore_type == "bomb":
		spawn_bomb_explosion(cell)

	erase_cell(cell)
	tile_health.erase(cell)

	match ore_type:
		"stone":
			stone_mined.emit()
			block_break.play()
			block_break_sound_timer = block_break_sound_interval

		"gold":
			gold_collected.emit()
			gold_break.play()

		"stardust":
			stardust_collected.emit()

		"bomb":
			bomb_triggered.emit(cell.y)

		"tar":
			pass


func spawn_bomb_explosion(cell: Vector2i) -> void:
	if bomb_explosion_scene == null:
		return

	var explosion: BombExplosion = bomb_explosion_scene.instantiate()

	get_tree().current_scene.add_child(explosion)

	var local_position: Vector2 = map_to_local(cell)

	explosion.global_position = to_global(
		local_position
	)

	explosion.explode()
