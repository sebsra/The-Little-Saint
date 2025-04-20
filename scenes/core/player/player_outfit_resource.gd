class_name PlayerOutfitResource
extends Resource

## Resource-based outfit system for The Little Saint
## Provides structured way to store and manage player appearance

# Outfit components
@export var beard: String = "none"
@export var lipstick: String = "none"
@export var eyes: String = "1"
@export var shoes: String = "1"
@export var earrings: String = "none"
@export var hat: String = "none"
@export var glasses: String = "none"
@export var clothes_down: String = "1"
@export var clothes_up: String = "1"
@export var clothes_complete: String = "none"
@export var body: String = "1"
@export var hair: String = "1"

# Outfit metadata
@export var outfit_name: String = "Default Outfit"
@export var is_favorite: bool = false
@export var creation_date: String = ""

# Initialize with default values
func _init():
	creation_date = Time.get_datetime_string_from_system(false, true)

# Convert to dictionary format (for backwards compatibility)
func to_dictionary() -> Dictionary:
	return {
		"beard": beard,
		"lipstick": lipstick,
		"eyes": eyes,
		"shoes": shoes,
		"earrings": earrings,
		"hats": hat,
		"glasses": glasses,
		"clothes_down": clothes_down,
		"clothes_up": clothes_up,
		"clothes_complete": clothes_complete,
		"bodies": body,
		"hair": hair
	}

# Create from dictionary (for backwards compatibility)
func from_dictionary(dict: Dictionary) -> PlayerOutfitResource:
	beard = str(dict.get("beard", "none"))
	lipstick = str(dict.get("lipstick", "none"))
	eyes = str(dict.get("eyes", "1"))
	shoes = str(dict.get("shoes", "1"))
	earrings = str(dict.get("earrings", "none"))
	hat = str(dict.get("hats", "none"))
	glasses = str(dict.get("glasses", "none"))
	clothes_down = str(dict.get("clothes_down", "1"))
	clothes_up = str(dict.get("clothes_up", "1"))
	clothes_complete = str(dict.get("clothes_complete", "none"))
	body = str(dict.get("bodies", "1"))
	hair = str(dict.get("hair", "1"))
	return self

# Check if a component is visible
func is_visible(component: String) -> bool:
	match component:
		"beard", "lipstick", "earrings", "hat", "glasses", "clothes_complete":
			return get(component) != "none"
		_:
			return true

# Check if this is a complete outfit (has all required elements)
func is_complete() -> bool:
	return body != "none" and eyes != "none"

# Reset to default values
func reset() -> void:
	beard = "none"
	lipstick = "none"
	eyes = "1"
	shoes = "1"
	earrings = "none"
	hat = "none"
	glasses = "none"
	clothes_down = "1"
	clothes_up = "1"
	clothes_complete = "none"
	body = "1"
	hair = "1"
	outfit_name = "Default Outfit"
	is_favorite = false
	creation_date = Time.get_datetime_string_from_system(false, true)

# Create a randomized outfit
func randomize_outfit() -> PlayerOutfitResource:
	# Use true randomization
	randomize()
	
	# Always set essential parts
	body = str(randi_range(1, 10))  # Assuming there are 10 body options
	eyes = str(randi_range(1, 14))  # Assuming there are 14 eye options
	
	# Randomly decide for all other parts
	beard = _random_part(["none", "1", "2", "3"], 0.7)  # 70% chance for none
	lipstick = _random_part(["none", "1", "2", "3"], 0.8)  # 80% chance for none
	shoes = str(randi_range(1, 10))  # Assuming there are 10 shoe options
	earrings = _random_part(["none", "1", "2", "3"], 0.8)  # 80% chance for none
	hat = _random_part(["none", "1", "2", "3", "4"], 0.6)  # 60% chance for none
	glasses = _random_part(["none", "1", "2"], 0.9)  # 90% chance for none
	
	# Either use separate top/bottom or complete outfit
	if randf() > 0.3:  # 70% chance for separate clothes
		clothes_down = str(randi_range(1, 10))
		clothes_up = str(randi_range(1, 10))
		clothes_complete = "none"
	else:  # 30% chance for complete outfit
		clothes_down = "none"
		clothes_up = "none"
		clothes_complete = str(randi_range(1, 5))  # Assuming there are 5 complete outfit options
	
	# Hair is important for character look
	hair = str(randi_range(1, 14))  # Assuming there are 14 hair options
	
	outfit_name = "Random Outfit"
	creation_date = Time.get_datetime_string_from_system(false, true)
	
	return self

# Helper for randomizing parts with "none" option
func _random_part(options: Array, none_chance: float) -> String:
	if randf() < none_chance:
		return "none"
	
	var valid_options = options.duplicate()
	valid_options.erase("none")
	return valid_options[randi() % valid_options.size()]

# Create a duplicate of this outfit
func duplicate_outfit() -> PlayerOutfitResource:
	var new_outfit = PlayerOutfitResource.new()
	new_outfit.beard = beard
	new_outfit.lipstick = lipstick
	new_outfit.eyes = eyes
	new_outfit.shoes = shoes
	new_outfit.earrings = earrings
	new_outfit.hat = hat
	new_outfit.glasses = glasses
	new_outfit.clothes_down = clothes_down
	new_outfit.clothes_up = clothes_up
	new_outfit.clothes_complete = clothes_complete
	new_outfit.body = body
	new_outfit.hair = hair
	new_outfit.outfit_name = outfit_name + " (Copy)"
	new_outfit.is_favorite = is_favorite
	new_outfit.creation_date = Time.get_datetime_string_from_system(false, true)
	return new_outfit

# Create a new default outfit resource
static func create_default() -> PlayerOutfitResource:
	return PlayerOutfitResource.new()

# Check for equality with another outfit
func equals(other: PlayerOutfitResource) -> bool:
	return (
		beard == other.beard and
		lipstick == other.lipstick and
		eyes == other.eyes and
		shoes == other.shoes and
		earrings == other.earrings and
		hat == other.hat and
		glasses == other.glasses and
		clothes_down == other.clothes_down and
		clothes_up == other.clothes_up and
		clothes_complete == other.clothes_complete and
		body == other.body and
		hair == other.hair
	)

# Apply this outfit to character sprites
func apply_to_sprites(character_sprites: Node2D) -> void:
	var outfit_dict = to_dictionary()
	
	for category in outfit_dict:
		if character_sprites.has_node(category):
			var sprite = character_sprites.get_node(category)
			var value = outfit_dict[category]
			
			if value == "none":
				sprite.visible = false
			else:
				sprite.visible = true
				sprite.animation = value
				sprite.frame = 1
