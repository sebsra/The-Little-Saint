class_name DeathState
extends EnemyState

var timer: float = 0.0
var fall_duration: float = 2.0
var remove_duration: float = 5.0

func _init():
	name = "Death"
func enter():
	super.enter()
	if enemy.has_method("drop_item"):
		enemy.drop_item()
	if enemy.collision_shape:
		enemy.collision_shape.set_deferred("disabled", true)
	play_animation("death")
	

	
	# Stop movement
	enemy.velocity = Vector2.ZERO

	timer = 0.0
	enemy.show_random_defeat_message()
	print(enemy.name + " entered death state")

func physics_process(delta: float):
	timer += delta		# Disable collision
	#if timer >= fall_duration and is_instance_valid(enemy):
		#if enemy.collision_shape:
			#enemy.collision_shape.set_deferred("disabled", true)
	# Remove entity after animation completes
	if timer >= remove_duration and is_instance_valid(enemy):
		enemy.queue_free()

func get_next_state() -> String:
	# Never leave death state
	return ""
