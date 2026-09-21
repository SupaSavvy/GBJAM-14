extends Control

@export var drill: Drill

# DEATH MENU
@export var death_menu: Control
@export var death_info_label: Label
@export var market_button: Button
@export var market_scene: PackedScene

# NORMAL HUD
@onready var hp_label: Label = $NinePatchRect/Hp
@onready var gold_label: Label = $NinePatchRect/Gold
@onready var fuel_label: Label = $NinePatchRect/Fuel
@onready var distance_label: Label = $NinePatchRect/Distance


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	death_menu.visible = false

	GameData.player_died.connect(show_death_screen)

	if market_button != null:
		market_button.focus_mode = Control.FOCUS_ALL
		market_button.pressed.connect(_on_market_pressed)


func _process(_delta: float) -> void:
	if drill == null:
		return

	hp_label.text = "HEALTH:\n" + str(drill.hearts)
	fuel_label.text = "FUEL:\n" + str(roundi(drill.fuel))
	gold_label.text = "GOLD:\n" + str(GameData.gold)
	distance_label.text = "DISTANCE:\n" + str(drill.current_depth)


func show_death_screen() -> void:
	death_menu.visible = true

	var cause_text: String = ""

	match GameData.last_death_cause:
		"void":
			cause_text = "THE VOID"

		"bomb":
			cause_text = "A BOMB"

		"fuel":
			cause_text = "FUEL LOSS"

		_:
			cause_text = "UNKNOWN"

	death_info_label.text = (
	"YOU DIED TO: " + cause_text
	+ "\nSTONES MINED: " + str(GameData.last_stones_mined)
	+ "\nGOLD COLLECTED: " + str(GameData.last_gold_collected)
	+ "\nDEPTH: " + str(GameData.last_depth)
	+ "\nHIGH SCORE: " + str(GameData.best_depth)
)

	if market_button != null:
		market_button.grab_focus()


func _on_market_pressed() -> void:
	if market_scene == null:
		print("Market scene has not been assigned!")
		return

	get_tree().change_scene_to_packed(market_scene)

func _unhandled_input(event: InputEvent) -> void:
	if death_menu.visible:
		if event.is_action_pressed("power_up_1"):
			_on_market_pressed()
