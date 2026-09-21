extends Button

func _ready() -> void:
	grab_focus()
	pressed.connect(_on_pressed)

func _on_pressed() -> void: 
	$"../../../../../ButtonClick".play()
	get_tree().change_scene_to_file("res://Ui/Scenes/market.tscn")
