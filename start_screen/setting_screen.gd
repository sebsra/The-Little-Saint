extends Node2D

"res://start_screen/setting_screen.gd"
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://start_screen/start_screen.tscn")


func _on_audio_button_pressed():
	get_tree().change_scene_to_file("res://start_screen/Audio_Settings.tscn")


func _on_customizer_button_pressed():
	get_tree().change_scene_to_file("res://Character_Customizer/customizer.tscn")
