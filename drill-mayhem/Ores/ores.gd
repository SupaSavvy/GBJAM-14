class_name Ores
extends TileMapLayer


signal gold_collected
signal stardust_collected
signal bomb_triggered


# TILE HEALTH
@export var default_tile_health: float = 3.0


# GENERATION
@export var source_id: int = 0

@export var stone_tile: Vector2i
@export var gold_tile: Vector2i
@export var tar_tile: Vector2i
@export var stardust_tile: Vector2i
@export var bomb_tile: Vector2i

@export var chunk_height: int = 12
@export var chunks_ahead: int = 3

# Playable horizontal limits in TileMap cells
@export var left_edge: int = -14
@export var right_edge: int = 14

# Extra tiles generated beyond the playable area
@export var generation_padding: int = 5

# Direct reference to the Drill
@export var drill: Drill


# Stores HP for damaged tiles
var tile_health: Dictionary = {}

# Remembers which vertical chunks have already been generated
var generated_chunks: Dictionary = {}


# ORE BEHAVIORS
@onready var bomb_behavior: BombBehavior = $Bomb
@onready var stardust_behavior: StardustBehavior = $Stardust
@onready var gold_behavior: GoldBehavior = $Gold


func _process(_delta: float) -> void:
	if drill == null:
		return

	# Convert the Drill's world position into a TileMap cell
	var drill_local_position: Vector2 = to_local(drill.global_position)
	var drill_cell: Vector2i = local_to_map(drill_local_position)

	# Figure out which vertical chunk the Drill is currently in
	var current_chunk_y: int = floori(
		float(drill_cell.y) / float(chunk_height)
	)

	# Keep several chunks generated below the Drill
	for chunk_offset: int in range(chunks_ahead + 1):
		var chunk_y: int = current_chunk_y + chunk_offset

		if not generated_chunks.has(chunk_y):
			generate_chunk(chunk_y)


func generate_chunk(chunk_y: int) -> void:
	# Prevent this chunk from being generated twice
	generated_chunks[chunk_y] = true

	var start_y: int = chunk_y * chunk_height

	# Generate extra terrain past both edges
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
	# You can later make these only appear after a certain depth
	var tar_cluster_amount: int = randi_range(1, 3)

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


	# VERY SHALLOW
	# Mostly stone with a little Stardust
	if depth < 40:
		if roll < 94.0:
			return stone_tile

		else:
			return stardust_tile


	# SHALLOW
	# Still mostly stone
	elif depth < 80:
		if roll < 92.0:
			return stone_tile

		else:
			return stardust_tile


	# MID
	# Gold begins appearing
	elif depth < 140:
		if roll < 82.0:
			return stone_tile

		elif roll < 90.0:
			return stardust_tile

		else:
			return gold_tile


	# DEEP
	# Bombs finally appear and stay rarer than Gold
	else:
		if roll < 74.0:
			return stone_tile

		elif roll < 82.0:
			return stardust_tile

		elif roll < 97.0:
			return gold_tile

		else:
			return bomb_tile


func generate_tar_cluster(center: Vector2i) -> void:
	# Base tar blob
	var offsets: Array[Vector2i] = [
		Vector2i.ZERO,
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.DOWN
	]

	# Random extra pieces make each tar cluster less uniform
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
	# Stop if there is no tile here
	if get_cell_source_id(cell) == -1:
		return

	var ore_type: String = get_ore_type(cell)

	# Tar doesn't use the normal HP system
	if ore_type == "tar":
		return

	# Give the tile starting HP the first time it gets hit
	if not tile_health.has(cell):
		tile_health[cell] = get_tile_max_health(cell)

	# Deal damage
	tile_health[cell] -= damage

	# Break the tile at 0 HP
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
	# Save the ore type before deleting the tile
	var ore_type: String = get_ore_type(cell)

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
			bomb_triggered.emit()

		"tar":
			pass
