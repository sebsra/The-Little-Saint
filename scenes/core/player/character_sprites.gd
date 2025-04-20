class_name CharacterSprites
extends Node2D

# Reference to the player
var player

var animation_frames = {
  "idle": [0, 1, 2, 3, 4, 5, 6, 7],
  "idle_back": [8, 9, 10, 11, 12, 13, 14, 15],
  "idle_look_around": [16, 17, 18, 19, 20, 21, 22, 23],
  "walking": [24, 25, 26, 27, 28, 29, 30, 31],
  "look_up": [32, 33, 34, 35, 36],
  "look_left": [40, 41, 42, 43, 44],
  "look_right": [48, 49, 50, 51, 52],
  "look_down": [56, 57, 58, 59, 60],
  "frontal_hands_up": [64, 65, 66, 67, 68],
  "turn_left": [72, 73, 74, 75, 76],
  "turn_up": [80, 81, 82, 83, 84], #10
  "turn_down": [88, 89, 90, 91, 92],
  "attack_right": [96, 97, 98, 99, 100, 101, 102, 103],
  "attack_left": [104, 105, 106, 107, 108, 109, 110, 111],
  "attack_up": [112, 113, 114, 115, 116, 117, 118, 119],
  "attack_down": [120, 121, 122, 123, 124, 125, 126, 127], #15
  "pickup_right": [128, 129, 130, 131],
  "pickup_left": [136, 137, 138, 139],
  "attack_knife": [144, 145, 146, 147], #18 
  "attack_knife_right": [152, 153, 154, 155],
  "position1": [160], #20
  "position2": [168],
  "position3": [176],
  "position4": [184],
  "position5": [192],
  "position6": [200],
  "position7": [208],
  "position8": [216],
  "dead": [224, 225],
  "respawn": [232, 233, 234, 235, 236],
  "walking0": [240, 241, 242, 243, 244],
  "walking1": [248, 249, 250, 251, 252],
  "walking2": [256, 257, 258, 259, 260],
  "walking3": [264, 265, 266, 267, 268],
  "walking4": [272, 273, 274, 275, 276],
  "walking5": [280, 281, 282, 283, 284], #attack axe right
  "walking6": [288, 289, 290, 291, 292], #attack axe left
  "attack_down_alt": [296, 297],
  "attack_up_alt": [304, 305],
  "attack_right_alt": [312, 313],
  "attack_left_alt": [320, 321],
  "Hammer_down": [328, 329, 330, 331, 332],
  "Hammer_up": [336, 337, 338, 339, 340],
  "Hammer_left": [344, 345, 346, 347, 348],
  "Hammer_right": [352, 353, 354, 355, 356],
  "hurt_down": [360, 361, 362, 363, 364],
  "hurt_up": [368, 369, 370, 371, 372],
  "hurt_left": [376, 377, 378, 379, 380],
  "hurt_right": [384, 385, 386, 387, 388], 
  "hurt": [25*8, 27*8]
}

var default_outfit = {
	"beard": 1,
	"lipstick": 1,
	"eyes": 1,
	"shoes": 1,
	"earrings": 1,
	"hats": 1,
	"glasses": 1,
	"clothes_down": 1,
	"clothes_up": 1,
	"clothes_complete": 1,
	"bodies": 1,
	"hair": 1
}

func _ready():
	# Get reference to the player node (parent)
	player = get_parent()

# Function to update outfit based on current animation
# This will be called by PlayerState's update_outfit() method via a delegate in Player class
func update_outfit(player_outfit, current_animation):
	for outfit in player_outfit:
		var animated_sprite = get_node(outfit)
		var selected_outfit = player_outfit[outfit]

		if str(selected_outfit) == "none":
			animated_sprite.visible = false
		else:
			animated_sprite.visible = true
			animated_sprite.play(str(selected_outfit))
			animated_sprite.speed_scale = 2.0
			# Frame management
			if current_animation in animation_frames:
				if animated_sprite.frame < animation_frames[current_animation][0] or animated_sprite.frame >= animation_frames[current_animation][-1]:
					animated_sprite.frame = animation_frames[current_animation][0]

# Update outfit sprite visibility based on player outfit dictionary
func update_outfit_visuals(outfit_dict):
	for category in outfit_dict:
		if has_node(category):
			var sprite = get_node(category)
			var value = str(outfit_dict[category])
			
			if value == "none":
				sprite.visible = false
			else:
				sprite.visible = true
				sprite.animation = value
				sprite.frame = 1
