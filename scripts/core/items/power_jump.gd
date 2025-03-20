class_name PowerJump
extends Area2D


func _on_body_entered(body):
	body.allowed_jumps += 1
	body.mode = "normal"
	print("double_jump")
	queue_free()
