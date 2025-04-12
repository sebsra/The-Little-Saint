class_name ReloadState
extends ArcherState

var reload_timer: float = 0.0
var reload_time: float = 2.0

func _init():
	name = "Reload"

func enter():
	super.enter()
	play_animation("idle")
	
	# Stop while reloading
	enemy.velocity.x = 0
		
	reload_timer = 0.0
	
	# Start reloading
	var archer = enemy as GoblinArcher
	if archer:
		archer.start_reloading()
		reload_time = archer.reload_time
		
	print(enemy.name + " entered reload state")

func physics_process(delta: float):
	reload_timer += delta
	
	# Update target
	update_target()

func get_next_state() -> String:
	var next = super.get_next_state()
	if next:
		return next
	
	# After reload completes
	if reload_timer >= reload_time:
		var archer = enemy as GoblinArcher
		if not archer:
			return "Patrol"
		
		# Retreat if player is close
		if target and get_distance_to_target() < 100:
			return "Retreat"
		
		# Otherwise chase or patrol
		if target:
			return "Chase"
		else:
			return "Patrol"
	
	return ""
