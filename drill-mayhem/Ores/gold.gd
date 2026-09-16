class_name GoldBehavior
extends Node


@export var gold_amount: int = 1


func collect(_drill: Drill) -> void:
	GameData.gold += gold_amount
	GameData.save_game()

	
