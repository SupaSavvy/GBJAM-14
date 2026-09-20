extends Button

func _ready() -> void:
	
	pressed.connect(_on_pressed)

func _on_pressed() -> void: 
	$"../../../../../../../../../ButtonClick".play()
	get_tree().change_scene_to_file("res://Scenes/Drilling_Test.tscn")
