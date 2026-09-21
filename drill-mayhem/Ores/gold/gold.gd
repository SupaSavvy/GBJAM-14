class_name GoldBehavior
extends Node

@export var gold_amount: int = 10


func collect(_drill: Drill) -> void:
	var multiplied_gold: int = roundi(
		float(gold_amount) * GameData.get_gold_multiplier()
	)

	GameData.add_gold(multiplied_gold)

	print("Gold Multiplier: ", GameData.get_gold_multiplier())
	print("Gold Earned: ", multiplied_gold)
