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
var health_level: int = 1
var fuel_level: int = 1

# SHOP COST
@export var health_base_cost: int = 100
@export var fuel_base_cost: int = 100
@export var speed_base_cost: int = 150
@export var shield_base_cost: int = 150

@export var max_upgrade_level: int = 5



# EQUIPPED POWERUPS
# These strings tell the Drill what each button should use.
var equipped_powerup_1: String = "speed"
var equipped_powerup_2: String = "shield"


# SAVE FILE
var save_path: String = "user://save.json"


# LEADER BOARD
signal leaderboard_changed(scores: Array[int])

var best_depth: int = 0
var leaderboard_scores: Array[int] = []
var lootlocker_player_id: String = ""


func _ready() -> void:
	load_game()
	start_lootlocker_guest_session()


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
		"health_level": health_level,
		"fuel_level": fuel_level,

		"equipped_powerup_1": equipped_powerup_1,
		"equipped_powerup_2": equipped_powerup_2,
	
		"best_depth": best_depth,
		"leaderboard_scores" :leaderboard_scores
	
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
	if not FileAccess.file_exists(save_path):
		print("No save file found.")
		return

	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)

	if file == null:
		print("Could not load game.")
		return

	var save_text: String = file.get_as_text()
	var save_data = JSON.parse_string(save_text)

	if save_data == null:
		print("Save file could not be read.")
		return

	# GOLD
	gold = save_data.get("gold", 0)

	# UPGRADE LEVELS
	health_level = save_data.get("health_level", 1)
	fuel_level = save_data.get("fuel_level", 1)
	speed_boost_level = save_data.get("speed_boost_level", 1)
	shield_level = save_data.get("shield_level", 1)

	# EQUIPPED POWERUPS
	equipped_powerup_1 = save_data.get("equipped_powerup_1", "speed")
	equipped_powerup_2 = save_data.get("equipped_powerup_2", "shield")

	# BEST DEPTH
	best_depth = save_data.get("best_depth", 0)

	# LOCAL LEADERBOARD SCORES
	leaderboard_scores.clear()

	var saved_scores: Array = save_data.get("leaderboard_scores", [])

	for score in saved_scores:
		leaderboard_scores.append(int(score))

	leaderboard_scores.sort()
	leaderboard_scores.reverse()

	if leaderboard_scores.size() > 10:
		leaderboard_scores.resize(10)

	# UPDATE UI
	gold_changed.emit(gold)
	leaderboard_changed.emit(leaderboard_scores)

	print("Loaded Gold: ", gold)
	print("Health Level: ", health_level)
	print("Fuel Level: ", fuel_level)
	print("Speed Level: ", speed_boost_level)
	print("Shield Level: ", shield_level)
	print("Power Up 1: ", equipped_powerup_1)
	print("Power Up 2: ", equipped_powerup_2)
	print("Best Depth: ", best_depth)
	print("Leaderboard: ", leaderboard_scores)




func start_lootlocker_guest_session() -> void:
	var guest_login_response = await LL_Authentication.GuestSession.new().send()

	if not guest_login_response.success:
		printerr(
			"Guest login failed: ",
			guest_login_response.error_data.to_string()
		)
		return

	lootlocker_player_id = str(
		guest_login_response.player_id
	)

	print(
		"LootLocker guest login successful! Player ID: ",
		lootlocker_player_id
	)
	
	



func submit_depth(depth: int) -> void:
	if depth > best_depth:
		best_depth = depth
		save_game()

	submit_online_score(depth)

	print("Run Depth: ", depth)
	print("Best Depth: ", best_depth)
	
	

func submit_online_score(depth: int) -> void:
	var leaderboard_key: String = "deepest_depth"

	var response = await LL_Leaderboards.SubmitScore.new(
		leaderboard_key,
		depth,
		lootlocker_player_id
	).send()

	if not response.success:
		printerr(
			"Could not submit online score: ",
			response.error_data.to_string()
		)
		return

	print("Online score submitted!")
	print("Depth: ", depth)



func get_upgrade_cost(upgrade_name: String) -> int:
	match upgrade_name:
		"health":
			return health_base_cost * health_level

		"fuel":
			return fuel_base_cost * fuel_level

		"speed":
			return speed_base_cost * speed_boost_level

		"shield":
			return shield_base_cost * shield_level

		_:
			return 0



func get_upgrade_level(upgrade_name: String) -> int:
	match upgrade_name:
		"health":
			return health_level

		"fuel":
			return fuel_level

		"speed":
			return speed_boost_level

		"shield":
			return shield_level

		_:
			return 0




func upgrade_powerup(upgrade_name: String) -> bool:
	var current_level: int = get_upgrade_level(upgrade_name)

	if current_level >= max_upgrade_level:
		return false

	var cost: int = get_upgrade_cost(upgrade_name)

	if not spend_gold(cost):
		return false

	match upgrade_name:
		"health":
			health_level += 1

		"fuel":
			fuel_level += 1

		"speed":
			speed_boost_level += 1

		"shield":
			shield_level += 1

		_:
			return false

	save_game()

	return true
