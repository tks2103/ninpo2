extends Node2D

func _ready() -> void:
	print("hi")
	set_player_location()
	#generate_map()

func set_player_location() -> void:
	var player: CharacterBody2D = get_node("Player")
	player.position = Vector2(0*16, 302*16)
