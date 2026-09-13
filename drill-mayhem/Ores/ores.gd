class_name Ores
extends TileMapLayer


# Default health if we don't recognize the tile
@export var default_tile_health: float = 3.0

#different signals to connect to UI
signal gold_collected(amount: int)
signal stardust_collected(amount: int)
signal bomb_triggered
var tile_health: Dictionary = {}


func damage_cell(cell: Vector2i, damage: float) -> void:
	# Stop if there is no tile here
	if get_cell_source_id(cell) == -1:
		return

	var ore_type: String = get_ore_type(cell)

	# Tar is not a normal breakable tile
	if ore_type == "tar":
		return

	# Give the tile its starting HP the first time it gets hit
	if not tile_health.has(cell):
		tile_health[cell] = get_tile_max_health(cell)

	# Deal damage
	tile_health[cell] -= damage

	print("Ore type: ", ore_type)
	print("Cell ", cell, " HP: ", tile_health[cell])

	# Break the tile when its HP reaches 0
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




func break_cell(cell: Vector2i) -> void:
	# Save the ore type before removing the tile
	var ore_type: String = get_ore_type(cell)

	# Remove the tile from the TileMapLayer
	erase_cell(cell)

	# Remove its stored health
	tile_health.erase(cell)

	# Do something based on what type of ore broke
	match ore_type:
		"stone":
			print("Stone broken")

		"gold":
			gold_collected.emit(1)

		"stardust":
			stardust_collected.emit(1)

		"bomb":
			bomb_triggered.emit()

		"tar":
			print("Tar should not normally break")

		_:
			print("Unknown ore type: ", ore_type)
			





func get_ore_type(cell: Vector2i) -> String:
	var tile_data: TileData = get_cell_tile_data(cell)

	# No tile exists in this cell
	if tile_data == null:
		return ""

	# Read the custom data value named "ore_type"
	var ore_type: String = tile_data.get_custom_data("ore_type")

	return ore_type
