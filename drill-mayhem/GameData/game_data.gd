extends Node


var gold: int = 0

var speed_boost_level: int = 1
var shield_level: int = 1

var save_path: String = "user://save.json"


func _ready() -> void:
	load_game()


func save_game() -> void:
	var save_data: Dictionary = {
		"gold": gold,
		"speed_boost_level": speed_boost_level,
		"shield_level": shield_level
	}

	var file: FileAccess = FileAccess.open(
		save_path,
		FileAccess.WRITE
	)

	file.store_string(
		JSON.stringify(save_data)
	)


func load_game() -> void:
	# If there is no save file yet, there is nothing to load.
	if not FileAccess.file_exists(save_path):
		return

	var file: FileAccess = FileAccess.open(
		save_path,
		FileAccess.READ
	)

	var save_text: String = file.get_as_text()
	var save_data: Dictionary = JSON.parse_string(save_text)

	# Restore the saved values.
	gold = save_data.get("gold", 0)
	speed_boost_level = save_data.get("speed_boost_level", 1)
	shield_level = save_data.get("shield_level", 1)

	print("Loaded Gold: ", gold)
