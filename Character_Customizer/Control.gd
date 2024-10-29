# UI.gd
extends Control
var body
var player_outfit
var selected_outfit_category = ""
var player_animations
var options_per_category = {}

func _ready():
	get_node("character_sprites/masks").visible = false
	player_outfit = get_node("character_sprites").default_outfit
	player_animations = get_node("character_sprites").animation_frames
	for category in player_outfit:
		var category_button = Button.new()
		var items_container = ScrollContainer.new()
		var item_container_grid = GridContainer.new()

		category_button.set_text(category)
		category_button.pressed.connect(_on_category_button_pressed.bind(category))
		$Outfit_Category_Picker/GridContainer.add_child(category_button)

		items_container.set_size(Vector2(620, 400))
		items_container.position = Vector2(600, 200)
		items_container.add_child(item_container_grid)
		items_container.name = category
		add_child(items_container)
		items_container.hide()
		
		item_container_grid.set_columns(6)
		var current_item = 0
		var empty_button = Button.new()
		
		var button_size = Vector2(100, 100)
		if category != "bodies":
			empty_button.set_custom_minimum_size(button_size)
			empty_button.pressed.connect(_on_item_button_pressed.bind("none"))
			item_container_grid.add_child(empty_button)
			var animated_sprite = get_node("character_sprites/" + category)
			animated_sprite.visible = false
			player_outfit[category] = "none"
		while true:
			current_item += 1
			var texture = get_node("character_sprites/"+category).sprite_frames.get_frame_texture(str(current_item), 1)
			if texture == null:
				break
			var item_texture = TextureRect.new()
			item_texture.set_texture(texture)
			item_texture.set_custom_minimum_size(button_size)
			item_texture.stretch_mode = 0
			var item_button = Button.new()
			item_button.set_custom_minimum_size(button_size)
			item_button.add_child(item_texture)
			item_button.pressed.connect(_on_item_button_pressed.bind(str(current_item)))
			item_container_grid.add_child(item_button)
		options_per_category[category] = current_item -1

func _process(delta):
	for outfit in player_outfit:
		var animated_sprite = get_node("character_sprites/" + outfit)
		animated_sprite.animation = str(player_outfit[outfit])
		animated_sprite.frame = 1


func _on_item_button_pressed(item):
	var animated_sprite = get_node("character_sprites/" + selected_outfit_category)
	if item == "none":
		animated_sprite.visible = false
	else:
		animated_sprite.visible = true
	player_outfit[selected_outfit_category] = item

func _on_category_button_pressed(category):
	if selected_outfit_category:
		get_node(selected_outfit_category).hide()
	get_node(category).show()
	selected_outfit_category = category
	
func _random_button_pressed():
	pass # TO DO: CREATE function to set random numbers to var player_outfit in range of var options_per_category = {}


func _save_button_pressed():
		var config = ConfigFile.new()
		var err = config.load("user://settings.cfg")
		if err == OK:
			config.set_value("settings", "outfit", player_outfit)
			config.save("user://settings.cfg")
		else:
			print("An error occurred while loading the settings.")

func _reset_button_pressed():
	for category in player_outfit:
		if category != "bodies":
			var animated_sprite = get_node("character_sprites/" + category)
			animated_sprite.visible = false
			
	


func _on_back_pressed():
	get_tree().change_scene_to_file("res://Start_Screen/start_screen.tscn")
