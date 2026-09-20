extends Label


var player: Player = null


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Player

	if player:
		text = "HEALTH - " + str(int(player.health))
	else:
		text = "HEALTH -"
