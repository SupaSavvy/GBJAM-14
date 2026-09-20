extends Button


@onready var settings_page: NinePatchRect = $"../../../../../../../../SettingsContainer/Settings"

func _ready():
	self.pressed.connect(_on_button_pressed)


func _on_button_pressed():
	$"../../../../../../../../../ButtonClick".play()
	if settings_page != null:
		settings_page.visible = !settings_page.visible
	else:
		print("Content page is not assigned in the inspector!")
