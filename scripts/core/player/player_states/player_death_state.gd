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
	
	# Stay in death state
	return ""
