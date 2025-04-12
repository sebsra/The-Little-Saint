class_name DeathState
extends EnemyState

var death_timer: float = 0.0
var death_duration: float = 1.0

func _init():
	name = "Death"
	
func enter():
	super.enter()
	play_animation("death")
	
	# Stop movement
	enemy.velocity = Vector2.ZERO
	
	# Disable collision
	if enemy.collision_shape:
		enemy.collision_shape.set_deferred("disabled", true)
	
	death_timer = 0.0
	print(enemy.name + " entered death state")

func physics_process(delta: float):
	death_timer += delta
	
	# Remove entity after animation completes
	if death_timer >= death_duration and is_instance_valid(enemy):
		enemy.queue_free()

func get_next_state() -> String:
	# Never leave death state
	return ""
