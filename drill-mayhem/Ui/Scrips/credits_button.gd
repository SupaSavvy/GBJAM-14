extends Button


@onready var content_page: NinePatchRect = $"../../../../../../../../CreditsContainer/Credits"

func _ready():
	self.pressed.connect(_on_button_pressed)


func _on_button_pressed():
	$"../../../../../../../../../ButtonClick".play()
	if content_page != null:
		content_page.visible = !content_page.visible
	else:
		print("Content page is not assigned in the inspector!")
