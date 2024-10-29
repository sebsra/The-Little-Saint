extends Area2D


func _on_body_entered(body):
	body.mode = "fly"
	print("Fly")
	queue_free()
