class_name GoldBehavior
extends Node


@export var gold_amount: int = 1


func collect(drill: Drill) -> void:
	# Add gold to the player's total
	drill.gold += gold_amount
