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
var boss_music = load("res://assets/audio/music/Tracks/the-epic-2-by-rafael-krux(chosic.com).mp3")
# Constants for room dimensions and number of rooms
const ROOM_WIDTH = 960  # Room width
const ROOM_HEIGHT = 480  # Room height
const NUM_ROOMS = 8  # Number of rooms
const HIGH_EXIT_OFFSET = 320  # Vertical offset for high exit (move up)
const LOW_EXIT_OFFSET = -320  # Vertical offset for low exit (move down)

func _ready():
	
	Global.player_died.connect(_on_player_died)
	var previous_position = Vector2(960, 0)  # Starting position for the first room
	var start_Initial_Room = start_room.instantiate()
	add_child(start_Initial_Room)
	var end = (NUM_ROOMS-1)
	for i in range(NUM_ROOMS):
		
		
		var Initial_Room
		var Parralel_Room
		var Exit_Barricade1 = ExitBlock.instantiate()
		var Exit_Barricade2 = ExitBlock.instantiate()
		var Exit_Barricade3 = ExitBlock.instantiate()
		var Exit_Barricade4 = ExitBlock.instantiate()
		var randRoom = randi() % 6  # Random int from 0 to 8
		
		if i == end:
				Initial_Room = end_room.instantiate()
				Initial_Room.position = previous_position
				add_child(Initial_Room)
				break
		else:
			if randRoom == 0:
				Initial_Room = room1.instantiate()
			elif randRoom == 1:
				Initial_Room = room2.instantiate()
			elif randRoom == 2:
				Initial_Room = room3.instantiate()
			elif randRoom == 3:
				Initial_Room = room4.instantiate()
			elif randRoom == 4:
				Initial_Room = room5.instantiate()
			elif randRoom == 5:
				Initial_Room = room6.instantiate()
		# Set the position of the current room
			Initial_Room.position = previous_position
			add_child(Initial_Room)
			print("Room ", i + 1, " placed at position: ", previous_position)
			
			previous_position.x += ROOM_WIDTH
			# 50% chance to place vertically (upward or downward)
			if randi() % 2 == 0:  # 50% chance to go upwards (high exit)
				previous_position.y += HIGH_EXIT_OFFSET
				var Exit_Pos1 = previous_position + Vector2(0,-32)
				Exit_Barricade1.position = Exit_Pos1
				add_child(Exit_Barricade1)
				var rand_0_or_1 = randi() % 2  # Random 0 or 1
				if rand_0_or_1 == 1:
						var previous_position2 = previous_position + Vector2(0, -640)
						
						var Exit_Pos3 = previous_position2 + Vector2(0,-353)
						var Exit_Pos2 = previous_position2 + Vector2(928,-353)
						var Exit_Pos4 = previous_position2 + Vector2(928,-32)
						
						Exit_Barricade3.position = Exit_Pos3
						Exit_Barricade2.position = Exit_Pos2
						Exit_Barricade4.position = Exit_Pos4
						if randi() % 2 == 0:
							Parralel_Room = room1.instantiate()
						else:
							Parralel_Room = room2.instantiate()
						Parralel_Room.position = previous_position2
						
						add_child(Exit_Barricade2)
						add_child(Exit_Barricade3)
						add_child(Exit_Barricade4)
						
						add_child(Parralel_Room)
				else:
						var Exit_Pos3 = previous_position + Vector2(-32, -672)
						Exit_Barricade3.position = Exit_Pos3
						add_child(Exit_Barricade3)
			else:  # 50% chance to go downwards (low exit)
				previous_position.y += LOW_EXIT_OFFSET
				var Exit_Pos1 = previous_position + Vector2(0,-352)
				Exit_Barricade1.position = Exit_Pos1
				add_child(Exit_Barricade1)
				var rand_0_or_1 = randi() % 2  # Random 0 or 1
				if rand_0_or_1 == 1:
						var previous_position2 = previous_position + Vector2(0, 640)
						
						var Exit_Pos3 = previous_position2 + Vector2(0, -32)
						var Exit_Pos2 = previous_position2 + Vector2(928, -32)
						var Exit_Pos4 = previous_position2 + Vector2(928, -352)
						
						Exit_Barricade2.position = Exit_Pos2
						Exit_Barricade3.position = Exit_Pos3
						Exit_Barricade4.position = Exit_Pos4
						if randi() % 2 == 0:
							Parralel_Room = room1.instantiate()
						else:
							Parralel_Room = room2.instantiate()
						Parralel_Room.position = previous_position2
						
						add_child(Exit_Barricade2)
						add_child(Exit_Barricade3)
						add_child(Exit_Barricade4)
						
						add_child(Parralel_Room)

				else:
						var Exit_Pos3 = previous_position + Vector2(-32,288 )
						Exit_Barricade3.position = Exit_Pos3
						add_child(Exit_Barricade3)
						
func _on_player_died() -> void:
	await get_tree().create_timer(3.0).timeout
	GlobalHUD.change_life(3.0)
	get_tree().change_scene_to_file("res://scenes/levels/adventure_mode/base_level.tscn")
