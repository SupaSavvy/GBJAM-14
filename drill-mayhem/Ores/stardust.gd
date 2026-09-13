class_name StardustBehavior
extends Node


@export var fuel_amount: float = 15.0


func collect(drill: Drill) -> void:
	# Add fuel
	drill.fuel += fuel_amount

	# Don't let fuel go above the max
	drill.fuel = min(
		drill.fuel,
		drill.max_fuel
	)
