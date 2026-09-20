extends Button


@onready var settings_page: NinePatchRect = $".."

func _ready():
	focus_mode = Control.FOCUS_NONE
	self.pressed.connect(_on_button_pressed)


func _on_button_pressed():
	$"../../../../ButtonClick".play()
	if settings_page != null:
		settings_page.visible = !settings_page.visible
	else:
		print("Settings page is not assigned in the inspector!")
