extends Control

@onready var rocks_back = $NinePatchRect/RocksBG
@onready var drill_front = $NinePatchRect/DrillMC

var time_passed: float = 0.0

var back_start_pos: Vector2
var front_start_pos: Vector2

var float_speed: float = 2.0
var float_amplitude_y: float = 5.0 # How many pixels they bob up and down
var float_amplitude_x: float = 3.0  # How many pixels they drift left and right

func _ready():
	# Save the initial positions right when the game starts
	back_start_pos = rocks_back.position
	front_start_pos = drill_front.position

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
