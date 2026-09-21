extends Control

@export var drill: Drill

@onready var hp_label: Label = $NinePatchRect/Hp
@onready var gold_label: Label = $NinePatchRect/Gold
@onready var fuel_label: Label = $NinePatchRect/Fuel
@onready var distance_label: Label = $NinePatchRect/Distance
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _process(_delta: float) -> void:
	if drill == null:
		return

	hp_label.text = "HEALTH:\n " + str(drill.hearts)
	fuel_label.text = "FUEL:\n " + str(roundi(drill.fuel))
	gold_label.text = "GOLD:\n " + str(GameData.gold)
	distance_label.text = "DISTANCE:\n" + str(drill.current_depth)
