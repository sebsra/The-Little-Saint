class_name SettingsMenu
extends Node2D

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/menus/main_menu/main_menu.tscn")


func _on_audio_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/menus/audio_settings.tscn")


func _on_customizer_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/menus/character_customizer/customizer.tscn")


func _on_settings_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/menus/difficulty_settings.tscn")
