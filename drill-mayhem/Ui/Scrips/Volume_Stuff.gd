extends MarginContainer

@onready var h_slider: HSlider = $Settings/SettingsContainer/SettingsStuff/VolumeDisplay_Slider/HSlider


func _ready() -> void:
	h_slider.min_value = 0.0
	h_slider.max_value = 1.0
	h_slider.step = 0.05
	h_slider.value = GameData.master_volume

	h_slider.value_changed.connect(_on_volume_changed)

	_on_volume_changed(h_slider.value)


func _on_volume_changed(value: float) -> void:
	var master_bus: int = AudioServer.get_bus_index("Master")

	GameData.master_volume = value
	GameData.save_game()

	if value <= 0.0:
		AudioServer.set_bus_mute(master_bus, true)
	else:
		AudioServer.set_bus_mute(master_bus, false)
		AudioServer.set_bus_volume_db(
			master_bus,
			linear_to_db(value)
		)
