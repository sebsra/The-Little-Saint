extends Node2D

func _ready():
	var slider = $DifficultySlider  # adjust path to your actual slider
	slider.value = Global.get_difficulty()
	slider.connect("value_changed", Callable(self, "_on_difficulty_slider_changed"))
	_update_difficulty_label(slider.value)



func _on_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/menus/settings_menu.tscn")

func _update_difficulty_label(value):
	var difficulty_names = ["EASY", "NORMAL", "HARD", "NIGHTMARE"]
	var index = clamp(int(value), 0, difficulty_names.size() - 1)
	$Difficulty_Label.text = "Difficulty: " + difficulty_names[int(value)]
	


func _on_difficulty_slider_value_changed(value):
	Global.set_difficulty(int(value))
	_update_difficulty_label(value)
