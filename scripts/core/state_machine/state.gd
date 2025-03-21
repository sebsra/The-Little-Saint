class_name State
extends Node

## Base class for all states in a state machine

# Reference to the state machine
var state_machine: StateMachine = null

# Reference to the owner node
var owner_node: Node = null

# State parameters (can be extended by child classes)
var parameters: Dictionary = {}


# Called when entering this state
func enter():
	pass

# Called when exiting this state
func exit():
	pass

# Called during _process
func process(delta: float):
	pass

# Called during _physics_process
func physics_process(delta: float):
	pass

# Called during _input
func handle_input(event: InputEvent):
	pass

# Override this to determine the next state to transition to
func get_next_state() -> String:
	return ""

# Utility functions that can be used by derived states

# Check if a condition is true
func condition_met(condition_name: String) -> bool:
	if owner_node.has_method("check_condition"):
		return owner_node.check_condition(condition_name)
	return false

# Get a value from the owner
func get_owner_property(property_name: String):
	if owner_node and property_name in owner_node:
		return owner_node.get(property_name)
	return null

# Set a value on the owner
func set_owner_property(property_name: String, value):
	if owner_node and property_name in owner_node:
		owner_node.set(property_name, value)

# Helper to check if owner is on floor (for platformers)
func is_on_floor() -> bool:
	if owner_node.has_method("is_on_floor"):
		return owner_node.is_on_floor()
	return false

# Helper to get owner velocity (for physics bodies)
func get_velocity() -> Vector2:
	if "velocity" in owner_node:
		return owner_node.velocity
	return Vector2.ZERO

# Helper to set owner velocity (for physics bodies)
func set_velocity(value: Vector2):
	if "velocity" in owner_node:
		owner_node.velocity = value

# Helper to play animations
func play_animation(anim_name: String):
	if owner_node.has_method("play_animation"):
		owner_node.play_animation(anim_name)
	elif owner_node.has_node("AnimatedSprite2D"):
		var sprite = owner_node.get_node("AnimatedSprite2D")
		if sprite.sprite_frames.has_animation(anim_name):
			sprite.play(anim_name)
