class_name PowerAttack
extends Area2D


func _on_body_attack_entered(body):
	body.attack_animation = "animation36"
	print("axe_attack")
	queue_free()
