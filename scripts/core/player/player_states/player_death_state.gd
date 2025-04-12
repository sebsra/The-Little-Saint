class_name PlayerDeathState
extends PlayerState

var death_timer: float = 0.0
var death_duration: float = 3.0  # Duration before scene transition

func enter():
	player.current_animation = "dead"
	player.get_node("CollisionShape2D").disabled = true
	death_timer = 0.0

func physics_process(delta: float):
	# Update death animation timer
	death_timer += delta
	
	# Update outfit
	update_outfit()

func get_next_state() -> String:
	# Scene transition after death animation
	if death_timer >= death_duration:
		player.queue_free()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu/main_menu.tscn")
	
	# Stay in death state
	return ""
