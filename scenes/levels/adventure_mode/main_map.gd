extends Node2D
# Assuming this script is on your MainMap scene

@onready var room1 = preload("res://scenes/levels/adventure_mode/enemy_room_1.tscn")
@onready var room2 = preload("res://scenes/levels/adventure_mode/enemy_room_2.tscn")
@onready var room3 = preload("res://scenes/levels/adventure_mode/enemy_room_3.tscn")
@onready var room4 = preload("res://scenes/levels/adventure_mode/loot_room_4.tscn")
@onready var room5 = preload("res://scenes/levels/adventure_mode/enemy_room_5.tscn")
@onready var room6 = preload("res://scenes/levels/adventure_mode/enemy_room_6.tscn")
@onready var start_room = preload("res://scenes/levels/adventure_mode/Starting_Room.tscn")
@onready var end_room = preload("res://scenes/levels/adventure_mode/End_Room.tscn")
@onready var ExitBlock = preload("res://scenes/levels/adventure_mode/exit_block.tscn")

# Constants for room dimensions and number of rooms
const ROOM_WIDTH = 960  # Room width
const ROOM_HEIGHT = 480  # Room height
const NUM_ROOMS = 6  # Number of rooms
const HIGH_EXIT_OFFSET = 320  # Vertical offset for high exit (move up)
const LOW_EXIT_OFFSET = -320  # Vertical offset for low exit (move down)

func _ready():
	var previous_position = Vector2(960, 0)  # Starting position for the first room
	var start_room_instance = start_room.instantiate()
	add_child(start_room_instance)
	var end = (NUM_ROOMS-1)
	for i in range(NUM_ROOMS):
		# Randomly choose room1 or room2
		var room_instance
		var room_instance2
		var room_instance3 = ExitBlock.instantiate()
		var room_instance4 = ExitBlock.instantiate()
		var room_instance6 = ExitBlock.instantiate()
		var room_instance5 = ExitBlock.instantiate()
		var randRoom = randi() % 6  # Random int from 0 to 8
		var rand1 = randi() % 2  # Random 0 or 1
		print("  Random 0 or 1: ", rand1)
		print("  Random 0 to 8: ", randRoom)
		if i == end:
				room_instance = end_room.instantiate()
				room_instance.position = previous_position
				add_child(room_instance)
				break
		else:
			if randRoom == 0:
				room_instance = room1.instantiate()
			elif randRoom == 1:
				room_instance = room2.instantiate()
			elif randRoom == 2:
				room_instance = room3.instantiate()
			elif randRoom == 3:
				room_instance = room4.instantiate()
			elif randRoom == 4:
				room_instance = room5.instantiate()
			elif randRoom == 5:
				room_instance = room6.instantiate()
		# Set the position of the current room
			room_instance.position = previous_position
			add_child(room_instance)
			print("Room ", i + 1, " placed at position: ", previous_position)
			
			previous_position.x += ROOM_WIDTH
			# 50% chance to place vertically (upward or downward)
			if randi() % 2 == 0:  # 50% chance to go upwards (high exit)
				previous_position.y += HIGH_EXIT_OFFSET
				var previous_position5 = previous_position + Vector2(0,-32)
				room_instance5.position = previous_position5
				add_child(room_instance5)
				var rand_0_or_1 = randi() % 2  # Random 0 or 1
				if 1 == 1:
						var previous_position2 = previous_position + Vector2(0, -640)
						
						var previous_position3 = previous_position2 + Vector2(0,-353)
						var previous_position4 = previous_position2 + Vector2(928,-353)
						var previous_position6 = previous_position2 + Vector2(928,-32)
						
						room_instance3.position = previous_position3
						room_instance4.position = previous_position4
						room_instance6.position = previous_position6
						if randi() % 2 == 0:
							room_instance2 = room1.instantiate()
						else:
							room_instance2 = room2.instantiate()
						room_instance2.position = previous_position2
						add_child(room_instance4)
						add_child(room_instance3)
						add_child(room_instance6)
						
						add_child(room_instance2)
				else:
						var previous_position3 = previous_position + Vector2(-32, -672)
						room_instance3.position = previous_position3
						add_child(room_instance3)
			else:  # 50% chance to go downwards (low exit)
				previous_position.y += LOW_EXIT_OFFSET
				var previous_position5 = previous_position + Vector2(0,-352)
				room_instance5.position = previous_position5
				add_child(room_instance5)
				var rand_0_or_1 = randi() % 2  # Random 0 or 1
				if rand_0_or_1 == 1:
						var previous_position2 = previous_position + Vector2(0, 640)
						
						var previous_position3 = previous_position2 + Vector2(0, -32)
						var previous_position4 = previous_position2 + Vector2(928, -32)
						var previous_position6 = previous_position2 + Vector2(928, -352)
						
						room_instance3.position = previous_position3
						room_instance4.position = previous_position4
						room_instance6.position = previous_position6
						if randi() % 2 == 0:
							room_instance2 = room1.instantiate()
						else:
							room_instance2 = room2.instantiate()
						room_instance2.position = previous_position2
						add_child(room_instance4)
						add_child(room_instance3)
						add_child(room_instance6)
						
						add_child(room_instance2)

				else:
						var previous_position3 = previous_position + Vector2(-32,288 )
						room_instance3.position = previous_position3
						add_child(room_instance3)
