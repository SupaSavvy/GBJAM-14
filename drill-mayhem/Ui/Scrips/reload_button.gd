extends Button

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	
	get_tree().reload_current_scene()
