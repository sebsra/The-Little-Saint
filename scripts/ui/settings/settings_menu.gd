class_name SettingsMenu
extends Node2D

"res://scripts/ui/settings/settings_menu.gd"
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu/main_menu.tscn")


func _on_audio_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/settings/audio_settings.tscn")


func _on_customizer_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/character_customizer/customizer.tscn")
