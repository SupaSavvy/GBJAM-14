class_name GoldBehavior
extends Node


@export var gold_amount: int = 1


func collect(_drill: Drill) -> void:
	GameData.add_gold(gold_amount)

	print("Gold: ", GameData.gold)
