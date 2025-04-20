extends CanvasLayer

func _ready():
	visible = false
	var slider = $DifficultySlider  # adjust path to your actual slider
	slider.value = Global.get_difficulty()
	slider.connect("value_changed", Callable(self, "_on_difficulty_slider_changed"))
	_update_difficulty_label(slider.value)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func toggle_pause():
	if visible:
		get_tree().paused = false
		visible = false
		GlobalHUD.show_hud()
		print("Game resumed, hiding pause menu")
	else:
		get_tree().paused = true
		GlobalHUD.hide_hud()
		visible = true
		print("Game paused, showing pause menu")
		


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()
		
		
func _on_close_button_pressed():
	toggle_pause()


func _on_menu_button_pressed():
	toggle_pause()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu/main_menu.tscn")


func _on_difficulty_slider_value_changed(value):
		Global.set_difficulty(int(value))
		_update_difficulty_label(value)


func _update_difficulty_label(value):
	var difficulty_names = ["EASY", "NORMAL", "HARD", "NIGHTMARE"]
	var index = clamp(int(value), 0, difficulty_names.size() - 1)
	$Difficulty_Label.text = "Difficulty: " + difficulty_names[int(value)]


func _on_ha_slider_value_changed(value):
	var master_bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, value)
	
	if value == -30:
		AudioServer.set_bus_mute(master_bus, true)
	else:
		AudioServer.set_bus_mute(master_bus, false)
