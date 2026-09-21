extends Control

@onready var rocks_back = $NinePatchRect/RocksBG
@onready var drill_front = $NinePatchRect/DrillMC

# --- SCENE NODE PATHS FROM YOUR TREES ---
@onready var start_button: Button = $NinePatchRect/MarginContainer2/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/VBoxContainer/StartGame/StartButton

# Simple array of your 4 main menu buttons (NO Godot groups required!)
@onready var menu_buttons: Array[Button] = [
	$NinePatchRect/MarginContainer2/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/VBoxContainer/StartGame/StartButton,
	$NinePatchRect/MarginContainer2/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/VBoxContainer/Market/MarketBurron,
	$NinePatchRect/MarginContainer2/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/VBoxContainer/LeaderboardButton/LeaderboardButton,
	$NinePatchRect/MarginContainer2/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/VBoxContainer/Settings/SettingsButton
]

# Settings Popup Nodes
@onready var settings_container: NinePatchRect = $NinePatchRect/SettingsContainer/Settings
@onready var settings_first_control: Control = $NinePatchRect/SettingsContainer/Settings/SettingsContainer/SettingsStuff/VolumeDisplay_Slider/HSlider

# Controls Popup Nodes
@onready var controls_container: NinePatchRect = $NinePatchRect/ControlsContainer/Controls

# New Display Popup Node (Update path to match your node tree)
@onready var new_thing_container: NinePatchRect = $NinePatchRect/GuideContainer/Guide


var time_passed: float = 0.0

var back_start_pos: Vector2
var front_start_pos: Vector2

var float_speed: float = 2.0
var float_amplitude_y: float = 5.0 # How many pixels they bob up and down
var float_amplitude_x: float = 3.0  # How many pixels they drift left and right

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Save the initial positions right when the game starts
	back_start_pos = rocks_back.position
	front_start_pos = drill_front.position
	
	# Hide popups when scene opens
	settings_container.hide()
	controls_container.hide()
	new_thing_container.hide()
	
	# Focus start button immediately for keyboard/gamepad navigation
	start_button.grab_focus()

func _process(delta):
	# Add the frame time to our total time tracker
	time_passed += delta
	
	#back astronot
	var back_offset_y = sin(time_passed * float_speed * 0.8) * float_amplitude_y
	var back_offset_x = cos(time_passed * float_speed * 0.5) * float_amplitude_x
	rocks_back.position = back_start_pos + Vector2(back_offset_x, back_offset_y)
	
	#front astronot
	var front_offset_y = sin(time_passed * float_speed) * (float_amplitude_y * 1.2)
	var front_offset_x = cos(time_passed * float_speed * 0.7) * float_amplitude_x
	drill_front.position = front_start_pos + Vector2(front_offset_x, front_offset_y)

# --- INPUT HANDLING FOR GOING BACK ---

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("power_up_2"):
		if controls_container.visible:
			$ButtonClick.play()
			close_controls()
			get_viewport().set_input_as_handled()
		elif settings_container.visible:
			$ButtonClick.play()
			close_settings()
			get_viewport().set_input_as_handled()
		elif new_thing_container.visible:
			$ButtonClick.play()
			close_new_thing()
			get_viewport().set_input_as_handled()

# --- POPUP & FOCUS MANAGEMENT ---

func open_settings() -> void:
	settings_container.show()
	# Disable main menu buttons so keyboard/gamepad can't select them
	for btn in menu_buttons:
		btn.focus_mode = Control.FOCUS_NONE
	settings_first_control.grab_focus()

func close_settings() -> void:
	settings_container.hide()
	# Re-enable main menu buttons
	for btn in menu_buttons:
		btn.focus_mode = Control.FOCUS_ALL
	start_button.grab_focus()

func open_controls() -> void:
	controls_container.show()

func close_controls() -> void:
	controls_container.hide()
	settings_first_control.grab_focus()

func open_new_thing() -> void:
	new_thing_container.show()

func close_new_thing() -> void:
	new_thing_container.hide()
