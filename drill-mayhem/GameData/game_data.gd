extends Node

signal gold_changed(amount: int)
signal powerup_equipped(slot_number: int, powerup_name: String)
signal leaderboard_changed(scores: Array[int])

# GOLD
var gold: int = 0

# UPGRADE LEVELS
var health_level: int = 3
var fuel_level: int = 1
var speed_boost_level: int = 1
var shield_level: int = 1
var gold_multiplier_level: int = 1

# SHOP COSTS
@export var health_base_cost: int = 100
@export var fuel_base_cost: int = 100
@export var speed_base_cost: int = 150
@export var shield_base_cost: int = 150
@export var gold_multiplier_base_cost: int = 200
@export var max_upgrade_level: int = 5

# EQUIPPED POWERUPS
var equipped_powerup_1: String = "speed"
var equipped_powerup_2: String = "shield"

# SAVE
var save_path: String = "user://save.json"

# LEADERBOARD
var best_depth: int = 0
var leaderboard_scores: Array[int] = []
var lootlocker_player_id: String = ""

# SETTINGS
var master_volume: float = 0.5


func _ready() -> void:
	load_game()
	start_lootlocker_guest_session()


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)
	save_game()


func spend_gold(amount: int) -> bool:
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

	powerup_equipped.emit(slot_number, powerup_name)
	save_game()


func save_game() -> void:
	var save_data: Dictionary = {
		"gold": gold,
		"health_level": health_level,
		"fuel_level": fuel_level,
		"speed_boost_level": speed_boost_level,
		"gold_multiplier_level": gold_multiplier_level,
		"shield_level": shield_level,
		"equipped_powerup_1": equipped_powerup_1,
		"equipped_powerup_2": equipped_powerup_2,
		"best_depth": best_depth,
		"leaderboard_scores": leaderboard_scores,
		"master_volume": master_volume
	}

	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)

	if file == null:
		print("Could not save game.")
		return

	file.store_string(JSON.stringify(save_data))


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
	gold = int(save_data.get("gold", 0))

	# UPGRADES
	# Health can never be lower than 3 anymore.
	health_level = clamp(
		max(int(save_data.get("health_level", 3)), 3),
		3,
		5
	)

	fuel_level = int(save_data.get("fuel_level", 1))
	speed_boost_level = int(save_data.get("speed_boost_level", 1))
	shield_level = int(save_data.get("shield_level", 1))
	gold_multiplier_level = int(save_data.get("gold_multiplier_level", 1))

	# POWERUPS
	equipped_powerup_1 = save_data.get("equipped_powerup_1", "speed")
	equipped_powerup_2 = save_data.get("equipped_powerup_2", "shield")

	# DEPTH
	best_depth = int(save_data.get("best_depth", 0))

	# LOCAL LEADERBOARD
	leaderboard_scores.clear()

	var saved_scores: Array = save_data.get("leaderboard_scores", [])

	for score in saved_scores:
		leaderboard_scores.append(int(score))

	leaderboard_scores.sort()
	leaderboard_scores.reverse()

	if leaderboard_scores.size() > 10:
		leaderboard_scores.resize(10)

	# SETTINGS
	master_volume = float(save_data.get("master_volume", 0.5))

	# UI
	gold_changed.emit(gold)
	leaderboard_changed.emit(leaderboard_scores)

	print("Loaded Gold: ", gold)
	print("Health Level: ", health_level)
	print("Fuel Level: ", fuel_level)
	print("Speed Level: ", speed_boost_level)
	print("Shield Level: ", shield_level)
	print("Best Depth: ", best_depth)


func start_lootlocker_guest_session() -> void:
	var response = await LL_Authentication.GuestSession.new().send()

	if not response.success:
		printerr(
			"Guest login failed: ",
			response.error_data.to_string()
		)
		return

	lootlocker_player_id = str(response.player_id)

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
	if lootlocker_player_id == "":
		print("Cannot submit score: LootLocker player not logged in.")
		return

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

func get_gold_multiplier() -> float:
	return 1.5 + (float(gold_multiplier_level - 1) * 0.5)
	
	


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
		"gold_multiplier":
			return gold_multiplier_base_cost * gold_multiplier_level
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
		"gold_multiplier":
			return gold_multiplier_level
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

		"gold_multiplier":
			gold_multiplier_level += 1

		_:
			return false

	save_game()
	return true
