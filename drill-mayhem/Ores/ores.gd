class_name Ores
extends TileMapLayer


signal gold_collected
signal stardust_collected
signal bomb_triggered(depth: int)


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
@export var right_edge: int = 14
@export var generation_padding: int = 5

@export var drill: Drill


# DEPTH PROGRESSION
@export var tar_start_depth: int = 30
@export var gold_start_depth: int = 50
@export var bomb_start_depth: int = 74
@export var deep_start_depth: int = 120


# Stores HP for damaged tiles
var tile_health: Dictionary = {}

# Keeps track of which chunks already exist
var generated_chunks: Dictionary = {}


# ORE BEHAVIORS
@onready var bomb_behavior: BombBehavior = $Bomb
@onready var stardust_behavior: StardustBehavior = $Stardust
@onready var gold_behavior: GoldBehavior = $Gold


func _process(_delta: float) -> void:
	if drill == null:
		return

	# Convert the drill's world position into a TileMap cell
	var drill_local_position: Vector2 = to_local(drill.global_position)
	var drill_cell: Vector2i = local_to_map(drill_local_position)

	# Figure out which vertical chunk the drill is inside
	var current_chunk_y: int = floori(
		float(drill_cell.y) / float(chunk_height)
	)

	# Keep several chunks generated below the player
	for chunk_offset: int in range(chunks_ahead + 1):
		var chunk_y: int = current_chunk_y + chunk_offset

		if not generated_chunks.has(chunk_y):
			generate_chunk(chunk_y)


func generate_chunk(chunk_y: int) -> void:
	# Don't generate the same chunk twice
	generated_chunks[chunk_y] = true

	var start_y: int = chunk_y * chunk_height

	var generation_left: int = left_edge - generation_padding
	var generation_right: int = right_edge + generation_padding


	# Fill the chunk with normal ores
	for y: int in range(start_y, start_y + chunk_height):
		for x: int in range(generation_left, generation_right + 1):
			var cell: Vector2i = Vector2i(x, y)

			var tile: Vector2i = choose_random_tile(y)

			set_cell(
				cell,
				source_id,
				tile
			)


	# TAR CLUSTERS
	# Tar doesn't begin appearing until tar_start_depth
	if start_y >= tar_start_depth:
		var tar_cluster_amount: int = randi_range(0, 2)

		for i: int in range(tar_cluster_amount):
			var tar_x: int = randi_range(
				left_edge + 2,
				right_edge - 2
			)

			var tar_y: int = randi_range(
				start_y + 2,
				start_y + chunk_height - 3
			)

			generate_tar_cluster(
				Vector2i(tar_x, tar_y)
			)


func choose_random_tile(depth: int) -> Vector2i:
	var roll: float = randf() * 100.0


	# BEFORE TAR
	# Mostly Stone with a little Stardust
	if depth < tar_start_depth:
		if roll < 96.0:
			return stone_tile

		else:
			return stardust_tile


	# TAR LAYER
	# Tar itself is generated separately in clusters
	elif depth < gold_start_depth:
		if roll < 94.0:
			return stone_tile

		else:
			return stardust_tile


	# GOLD LAYER
	elif depth < bomb_start_depth:
		if roll < 89.0:
			return stone_tile

		elif roll < 95.0:
			return stardust_tile

		else:
			return gold_tile


	# BOMB LAYER
	# Bombs are still rare
	elif depth < deep_start_depth:
		if roll < 87.0:
			return stone_tile

		elif roll < 93.0:
			return stardust_tile

		elif roll < 98.5:
			return gold_tile

		else:
			return bomb_tile


	# DEEP LAYER
	else:
		if roll < 83.0:
			return stone_tile

		elif roll < 89.0:
			return stardust_tile

		elif roll < 98.0:
			return gold_tile

		else:
			return bomb_tile


func generate_tar_cluster(center: Vector2i) -> void:
	# Basic connected tar blob
	var offsets: Array[Vector2i] = [
		Vector2i.ZERO,
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.DOWN
	]

	# Random extras make each blob less uniform
	if randf() < 0.5:
		offsets.append(Vector2i(-1, -1))

	if randf() < 0.5:
		offsets.append(Vector2i(1, 1))

	if randf() < 0.35:
		offsets.append(Vector2i(-2, 0))

	if randf() < 0.35:
		offsets.append(Vector2i(2, 0))


	for offset: Vector2i in offsets:
		var cell: Vector2i = center + offset

		set_cell(
			cell,
			source_id,
			tar_tile
		)


func damage_cell(cell: Vector2i, damage: float) -> void:
	# Stop if there isn't a tile here
	if get_cell_source_id(cell) == -1:
		return

	var ore_type: String = get_ore_type(cell)

	# Tar doesn't use the normal HP system
	if ore_type == "tar":
		return

	# Give the tile starting health the first time it's hit
	if not tile_health.has(cell):
		tile_health[cell] = get_tile_max_health(cell)

	# Deal damage
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

	# Spawn the effect BEFORE deleting the bomb tile.
	if ore_type == "bomb":
		spawn_bomb_explosion(cell)

	erase_cell(cell)
	tile_health.erase(cell)

	match ore_type:
		"stone":
			pass

		"gold":
			gold_collected.emit()

		"stardust":
			stardust_collected.emit()

		"bomb":
			bomb_triggered.emit(cell.y)

		"tar":
			pass

func spawn_bomb_explosion(cell: Vector2i) -> void:
	if bomb_explosion_scene == null:
		print("ERROR: Bomb explosion scene is not assigned!")
		return

	var explosion: BombExplosion = bomb_explosion_scene.instantiate()

	get_tree().current_scene.add_child(explosion)

	# Put the explosion at the bomb first.
	var local_position: Vector2 = map_to_local(cell)

	explosion.global_position = to_global(local_position)

	# NOW fire the particles.
	explosion.explode()

	print("Bomb explosion spawned at: ", explosion.global_position)
