extends CanvasLayer

@onready var defend = $defend
@onready  var attack = $attack

func _on_attack_button_down() -> void:
	attack.modulate = Color(1.0, 1.0, 1.0, 0.5) 
	Input.action_press("attack")


func _on_attack_button_up() -> void:
	attack.modulate = Color(2, 2, 2, 0.5) 
	Input.action_release("attack")

func _on_defend_button_down() -> void:
	defend.modulate = Color(1.0, 1.0, 1.0, 0.5) 
	Input.action_press("defend")
	
func _on_defend_button_up() -> void:
	defend.modulate = Color(2, 2, 2, 0.5) 
	Input.action_release("defend")
