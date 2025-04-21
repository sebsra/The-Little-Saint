extends Node2D


func _on_line_edit_text_submitted(new_text):
	Global.player_name = new_text
	print("Global player name:", Global.player_name)
	$Label.visible = false  # Hides it
	$Label2.visible = false  # Hides it
	$LineEdit.visible = false  # Hides it
	$Label3.text ="Herzlich Wilkommen zu The Little Saint !!!"
	$Label4.text = "Hallo " + Global.player_name
	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file("res://scenes/ui/menus/main_menu/main_menu.tscn")
