extends Button


@onready var settings_page: NinePatchRect = $"../../../../../../ControlsContainer/Credits"

func _ready():

	self.pressed.connect(_on_button_pressed)


func _on_button_pressed():
	$"../../../../../../../ButtonClick".play()
	owner.open_controls()
