class_name AttackButton
extends Button


@onready var attack = $"."

func _ready():
	attack.modulate = Color(2, 2, 2, 0.5) 


func _on_button_up():
	attack.modulate = Color(2, 2, 2, 0.5) 
	Input.action_release("attack")


func _on_button_down():
	attack.modulate = Color(1.0, 1.0, 1.0, 0.5) 
	Input.action_press("attack")
