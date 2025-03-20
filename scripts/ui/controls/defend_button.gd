class_name DefendButton
extends Button


@onready var defend = $"."

func _ready():
	defend.modulate = Color(2, 2, 2, 0.5) 


func _on_button_up():
	defend.modulate = Color(2, 2, 2, 0.5) 
	Input.action_release("defend")

func _on_button_down():
	defend.modulate = Color(1.0, 1.0, 1.0, 0.5) 
	Input.action_press("defend")
	
