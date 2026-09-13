class_name Ores
extends TileMapLayer


signal gold_collected()
signal stardust_collected()
signal bomb_triggered


@export var default_tile_health: float = 3.0


var tile_health: Dictionary = {}

@onready var bomb_behavior: BombBehavior = $Bomb
@onready var stardust_behavior: StardustBehavior = $Stardust
@onready var gold_behavior: GoldBehavior = $Gold


func damage_cell(cell: Vector2i, damage: float) -> void:
	# Stop if there is no tile here
	if get_cell_source_id(cell) == -1:
		return

	var ore_type: String = get_ore_type(cell)

	# Tar does not use the normal breaking system
	if ore_type == "tar":
		return

	# Give the tile health the first time it is damaged
	if not tile_health.has(cell):
		tile_health[cell] = get_tile_max_health(cell)

	tile_health[cell] -= damage

	# Break the tile once its health reaches 0
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
	# Save the type before deleting the tile
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
