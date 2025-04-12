class_name EnemyState
extends State

## Base class for all enemy states
## Provides common functionality and utility methods

# Get properly typed references
var enemy: BaseEnemy = null
var target = null

# Get the current state machine properly typed
var enemy_machine: EnemyStateMachine:
	get: return state_machine as EnemyStateMachine

func _init():
	# This is called when the object is first created
	name = "EnemyState"

func enter():
	# Ensure enemy reference is valid
	enemy = owner_node as BaseEnemy
	
	if not enemy:
		push_error("Enemy state attached to non-BaseEnemy object!")
		return
	
	# Get current target from state machine
	if enemy_machine:
		target = enemy_machine.target

func exit():
	pass

func get_next_state() -> String:
	# Check for death - highest priority transition
	if enemy and (enemy.is_dead or enemy.current_health <= 0):
		return "Death"
	
	# No transition by default
	return ""

# Common utility functions
func play_animation(anim_name: String):
	if enemy:
		enemy.play_animation(anim_name)

func flip_to_target():
	if not target or not enemy:
		return
		
	if enemy.animated_sprite:
		var direction = target.global_position.x - enemy.global_position.x
		enemy.animated_sprite.flip_h = direction > 0

# Distance to current target
func get_distance_to_target() -> float:
	if not target or not enemy:
		return 9999.0
	
	return enemy.global_position.distance_to(target.global_position)

# Is target in attack range?
func is_target_in_attack_range() -> bool:
	if enemy and "attack_radius" in enemy:
		return get_distance_to_target() <= enemy.attack_radius
	else:
		return get_distance_to_target() <= 50.0  # Default

# Is target in detection range?
func is_target_in_detection_range() -> bool:
	if enemy and "detection_radius" in enemy:
		return get_distance_to_target() <= enemy.detection_radius
	else:
		return get_distance_to_target() <= 200.0  # Default

# Update target reference
func update_target():
	if enemy_machine:
		target = enemy_machine.target
