class_name CharacterSprites
extends Node2D

var animation_frames = {
	"idle": [0, 1, 2, 3, 4, 5, 6, 7],
	"animation1": [8, 9, 10, 11, 12, 13, 14, 15],
	"animation2": [16, 17, 18, 19, 20, 21, 22, 23],
	"walking": [24, 25, 26, 27, 28, 29, 30, 31],
	"animation4": [32, 33, 34, 35, 36],
	"animation5": [40, 41, 42, 43, 44],
	"animation6": [48, 49, 50, 51, 52],
	"animation7": [56, 57, 58, 59, 60],
	"animation8": [64, 65, 66, 67, 68],
	"animation9": [72, 73, 74, 75, 76],
	"animation10": [80, 81, 82, 83, 84],
	"animation11": [88, 89, 90, 91, 92],
	"animation12": [96, 97, 98, 99, 100, 101, 102, 103],
	"animation13": [104, 105, 106, 107, 108, 109, 110, 111],
	"animation14": [112, 113, 114, 115, 116, 117, 118, 119],
	"animation15": [120, 121, 122, 123, 124, 125, 126, 127],
	"animation16": [128, 129, 130, 131],
	"animation17": [136, 137, 138, 139],
	"animation18": [144, 145, 146, 147], #attack knife
	"animation19": [152, 153, 154, 155],
	"animation20": [160],
	"animation21": [168],
	"animation22": [176],
	"animation23": [184],
	"animation24": [192],
	"animation25": [200],
	"animation26": [208],
	"animation27": [216],
	"dead": [224, 225],
	"animation29": [232, 233, 234, 235, 236],
	"walking0": [240, 241, 242, 243, 244],
	"walking1": [248, 249, 250, 251, 252],
	"walking2": [256, 257, 258, 259, 260],
	"walking3": [264, 265, 266, 267, 268],
	"walking4": [272, 273, 274, 275, 276],
	"walking5": [280, 281, 282, 283, 284], #attack axe right
	"walking6": [288, 289, 290, 291, 292], #attack axe left
	"walking7": [296, 297],
	"walking8": [304, 305],
	"walking9": [312, 313],
	"animation40": [320, 321],
	"animation41": [328, 329, 330, 331, 332],
	"animation42": [336, 337, 338, 339, 340],
	"animation43": [344, 345, 346, 347, 348],
	"animation44": [352, 353, 354, 355, 356],
	"animation45": [360, 361, 362, 363, 364],
	"animation46": [368, 369, 370, 371, 372],
	"animation47": [376, 377, 378, 379, 380],
	"animation48": [384, 385, 386, 387, 388],
	"hurt":        [25*8, 27*8],
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
