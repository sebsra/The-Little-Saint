class_name MainMenu
extends Node2D


func _on_exit_button_pressed():
	get_tree().quit()


func _on_settings_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/menus/settings_menu.tscn")


func _on_start_button_pressed():
	if SaveManager.FirstRun == 0:
		get_tree().change_scene_to_file("res://scenes/levels/intro_level/intro_level.tscn")
	elif SaveManager.FirstRun == 1:
		get_tree().change_scene_to_file("res://scenes/levels/adventure_mode/base_level.tscn")
	else :
		print("Error can't load Level")
	


func _on_line_edit_text_submitted(new_text):
	pass # Replace with function body.
