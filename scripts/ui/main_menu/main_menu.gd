class_name MainMenu
extends Node2D


func _on_exit_button_pressed():
	get_tree().quit()


func _on_settings_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/settings/settings_menu.tscn")


func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/levels/adventure_mode/base_level.tscn")
