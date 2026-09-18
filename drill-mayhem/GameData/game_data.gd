extends Node


signal gold_changed(amount: int)

signal powerup_equipped(
	slot_number: int,
	powerup_name: String
)


# GOLD
var gold: int = 0


# POWERUP LEVELS
var speed_boost_level: int = 1
var shield_level: int = 1
var magnet_level: int = 1


# EQUIPPED POWERUPS
# These strings tell the Drill what each button should use.
var equipped_powerup_1: String = "speed"
var equipped_powerup_2: String = "shield"


# SAVE FILE
var save_path: String = "user://save.json"


# LEADER BOARD
var best_depth: int = 0

func _ready() -> void:
	load_game()


func add_gold(amount: int) -> void:
	gold += amount

	gold_changed.emit(gold)

	save_game()


func spend_gold(amount: int) -> bool:
	# If the player cannot afford it, do nothing.
	if gold < amount:
		return false

	gold -= amount

	gold_changed.emit(gold)

	save_game()

	return true


func equip_powerup(slot_number: int, powerup_name: String) -> void:
	match slot_number:
		1:
			equipped_powerup_1 = powerup_name

		2:
			equipped_powerup_2 = powerup_name

		_:
			return

	powerup_equipped.emit(
		slot_number,
		powerup_name
	)

	save_game()


func save_game() -> void:
	var save_data: Dictionary = {
		"gold": gold,

		"speed_boost_level": speed_boost_level,
		"shield_level": shield_level,
		"magnet_level": magnet_level,

		"equipped_powerup_1": equipped_powerup_1,
		"equipped_powerup_2": equipped_powerup_2,
	
		"best_depth": best_depth
	
	
	}

	var file: FileAccess = FileAccess.open(
		save_path,
		FileAccess.WRITE
	)

	# If Godot could not open the file, stop here.
	if file == null:
		print("Could not save game.")
		return

	file.store_string(
		JSON.stringify(save_data)
	)

	#print("Game Saved")


func load_game() -> void:
	# If this is the player's first time playing,
	# there won't be a save file yet.
	if not FileAccess.file_exists(save_path):
		print("No save file found.")
		return

	var file: FileAccess = FileAccess.open(
		save_path,
		FileAccess.READ
	)

	if file == null:
		print("Could not load game.")
		return

	var save_text: String = file.get_as_text()

	var save_data = JSON.parse_string(save_text)

	# Stop if the save file couldn't be read correctly.
	if save_data == null:
		print("Save file could not be read.")
		return


	# LOAD GOLD
	gold = save_data.get(
		"gold",
		0
		
	)


	# LOAD POWERUP LEVELS
	speed_boost_level = save_data.get(
		"speed_boost_level",
		1
	)

	shield_level = save_data.get(
		"shield_level",
		1
	)

	magnet_level = save_data.get(
		"magnet_level",
		1
	)


	# LOAD EQUIPPED POWERUPS
	equipped_powerup_1 = save_data.get(
		"equipped_powerup_1",
		"speed"
	)

	equipped_powerup_2 = save_data.get(
		"equipped_powerup_2",
		"shield"
	)
	
	best_depth = save_data.get(
	"best_depth",
	0
	)

	# Tell the UI what the loaded gold amount is.
	gold_changed.emit(gold)

	print("Loaded Gold: ", gold)
	print("Power Up 1: ", equipped_powerup_1)
	print("Power Up 2: ", equipped_powerup_2)
	
func submit_depth(depth: int) -> void:
	if depth > best_depth:
		best_depth = depth
		save_game()

	print("Run Depth: ", depth)
	print("Best Depth: ", best_depth)
