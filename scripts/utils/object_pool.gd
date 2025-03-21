class_name ObjectPool
extends Node

## A generic object pooling system for reusing objects instead of creating and destroying them

# The scene to create objects from
var scene: PackedScene
# Maximum number of objects to keep in the pool (0 = unlimited)
var max_size: int = 0
# Container for inactive objects
var inactive_objects: Array = []
# Container to track all spawned objects (both active and inactive)
var all_objects: Array = []
# Whether to automatically resize the pool as needed
var auto_resize: bool = true
# Parent node for spawned objects
var parent_node: Node = null

# Signal emitted when an object is taken from the pool
signal object_spawned(object)
# Signal emitted when an object is returned to the pool
signal object_recycled(object)

## Create a new object pool with the specified scene
func _init(object_scene: PackedScene, pool_size: int = 10, auto_resize_pool: bool = true):
	scene = object_scene
	max_size = pool_size
	auto_resize = auto_resize_pool
	
	# Pre-populate the pool with objects
	for i in range(pool_size):
		var obj = _create_object()
		inactive_objects.append(obj)
		all_objects.append(obj)

## Set the parent node for all pooled objects
func set_parent(parent: Node):
	parent_node = parent
	
	# Reparent existing objects
	for obj in all_objects:
		if obj.get_parent():
			obj.get_parent().remove_child(obj)
		parent_node.add_child(obj)

## Get an object from the pool, or create a new one if the pool is empty
func get_object() -> Node:
	var obj = null
	
	if inactive_objects.size() > 0:
		# Take an object from the inactive pool
		obj = inactive_objects.pop_back()
	elif auto_resize:
		# Create a new object if we're allowed to resize the pool
		obj = _create_object()
		all_objects.append(obj)
	else:
		push_error("Object pool is empty and auto-resize is disabled!")
		return null
	
	if obj.has_method("_on_spawn_from_pool"):
		obj._on_spawn_from_pool()
	
	# Ensure the object is visible and active
	obj.visible = true
	obj.process_mode = Node.PROCESS_MODE_INHERIT
	
	emit_signal("object_spawned", obj)
	return obj

## Return an object to the pool for reuse
func recycle(obj: Node) -> void:
	if not all_objects.has(obj):
		push_error("Attempted to recycle an object that wasn't created by this pool!")
		return
	
	# Make sure it's not already in the inactive pool
	if inactive_objects.has(obj):
		return
	
	# Prepare the object for recycling
	if obj.has_method("_on_recycle_to_pool"):
		obj._on_recycle_to_pool()
	
	# Hide and disable the object
	obj.visible = false
	obj.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Add to inactive pool, respecting max size
	if max_size <= 0 or inactive_objects.size() < max_size:
		inactive_objects.append(obj)
	else:
		# If the pool is full, destroy the object
		all_objects.erase(obj)
		obj.queue_free()
	
	emit_signal("object_recycled", obj)

## Clear the entire pool, freeing all objects
func clear_pool() -> void:
	for obj in all_objects:
		obj.queue_free()
	
	inactive_objects.clear()
	all_objects.clear()

## Resize the pool to the specified size
func resize(new_size: int) -> void:
	if new_size < 0:
		push_error("Cannot resize pool to negative size!")
		return
	
	if new_size < inactive_objects.size():
		# Need to shrink the pool
		while inactive_objects.size() > new_size:
			var obj = inactive_objects.pop_back()
			all_objects.erase(obj)
			obj.queue_free()
	else:
		# Need to grow the pool
		for i in range(new_size - inactive_objects.size()):
			var obj = _create_object()
			inactive_objects.append(obj)
			all_objects.append(obj)
	
	max_size = new_size

## Get the current number of active objects
func active_count() -> int:
	return all_objects.size() - inactive_objects.size()

## Get the current number of inactive objects
func inactive_count() -> int:
	return inactive_objects.size()

## Get the total number of objects managed by this pool
func total_count() -> int:
	return all_objects.size()

## Create a new object and set it up for the pool
func _create_object() -> Node:
	var obj = scene.instantiate()
	
	# Set up parent if specified
	if parent_node:
		parent_node.add_child(obj)
	
	# Hide and disable by default
	obj.visible = false
	obj.process_mode = Node.PROCESS_MODE_DISABLED
	
	return obj
