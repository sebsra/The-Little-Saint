class_name GameResourcePreloader
extends Node

## A utility class for preloading and managing game resources
## Helps improve loading times by caching frequently used resources

# Resource cache organized by type and ID
var _cache = {
	"scenes": {},
	"textures": {},
	"audio": {},
	"fonts": {},
	"materials": {},
	"animations": {},
	"other": {}
}

# Signal emitted when a resource is loaded
signal resource_loaded(type, id, resource)
# Signal emitted when all queued resources are loaded
signal all_resources_loaded()
# Signal emitted on loading progress update
signal loading_progress(progress, total)

# Queue of resources to load
var _load_queue = []
# Count of loaded resources
var _loaded_count = 0
# Whether we're currently loading resources
var _is_loading = false
# Progress interval for emitting loading_progress signals
var _progress_interval = 0.1
var _last_progress_time = 0

## Initialize with default resources to preload
func _ready():
	# Nothing to preload by default
	pass

## Add a resource to the preload queue
func queue_resource(path: String, type: String = "other", id: String = ""):
	if id == "":
		id = path.get_file().get_basename()

	# Check if already in cache
	if has_resource(type, id):
		return true

	# Add to queue
	_load_queue.append({
		"path": path,
		"type": type,
		"id": id
	})
	
	return true

## Start loading all queued resources
func load_queued_resources(use_thread: bool = true):
	if _is_loading:
		return false
	
	if _load_queue.size() == 0:
		emit_signal("all_resources_loaded")
		return true
	
	_is_loading = true
	_loaded_count = 0
	_last_progress_time = Time.get_ticks_msec() / 1000.0
	
	if use_thread:
		_start_threaded_loading()
	else:
		_start_immediate_loading()
	
	return true

## Load a single resource immediately
func load_resource(path: String, type: String = "other", id: String = "") -> Resource:
	if id == "":
		id = path.get_file().get_basename()
	
	# Check if already in cache
	if has_resource(type, id):
		return get_resource(type, id)
	
	# Load and cache
	var resource = ResourceLoader.load(path)
	if resource:
		_cache_resource(resource, type, id)
		emit_signal("resource_loaded", type, id, resource)
		return resource
	
	push_error("Failed to load resource: " + path)
	return null

## Check if a resource is in the cache
func has_resource(type: String, id: String) -> bool:
	if not _cache.has(type):
		return false
	return _cache[type].has(id)

## Get a resource from the cache
func get_resource(type: String, id: String) -> Resource:
	if not has_resource(type, id):
		push_error("Resource not found in cache: " + type + "/" + id)
		return null
	
	return _cache[type][id]

## Clear the cache for a specific type
func clear_cache(type: String = ""):
	if type == "":
		# Clear all caches
		for t in _cache:
			_cache[t].clear()
	elif _cache.has(type):
		_cache[type].clear()

## Clear the load queue
func clear_queue():
	_load_queue.clear()
	_loaded_count = 0
	_is_loading = false

## Get cache statistics
func get_cache_stats() -> Dictionary:
	var stats = {}
	
	for type in _cache:
		stats[type] = _cache[type].size()
	
	stats["total"] = 0
	for type in stats:
		stats["total"] += stats[type]
	
	return stats

## Process loading queue in the main thread (immediate)
func _start_immediate_loading():
	for resource_info in _load_queue:
		var resource = ResourceLoader.load(resource_info.path)
		if resource:
			_cache_resource(resource, resource_info.type, resource_info.id)
			_loaded_count += 1
			
			# Emit progress signal at intervals
			var current_time = Time.get_ticks_msec() / 1000.0
			if current_time - _last_progress_time >= _progress_interval:
				_last_progress_time = current_time
				emit_signal("loading_progress", _loaded_count, _load_queue.size())
			
			emit_signal("resource_loaded", resource_info.type, resource_info.id, resource)
		else:
			push_error("Failed to load resource: " + resource_info.path)
	
	_load_queue.clear()
	_is_loading = false
	emit_signal("loading_progress", _loaded_count, _loaded_count)
	emit_signal("all_resources_loaded")

## Process loading queue in a background thread
func _start_threaded_loading():
	# Create a new thread for loading
	var thread = Thread.new()
	thread.start(Callable(self, "_threaded_loading"))
	
	# Thread cleanup will happen in _threaded_loading

## Thread function for background loading
func _threaded_loading():
	var total = _load_queue.size()
	
	for resource_info in _load_queue:
		var path = resource_info.path
		var type = resource_info.type
		var id = resource_info.id
		
		# Use ResourceLoader.load_threaded_request to start loading
		ResourceLoader.load_threaded_request(path)
		
		# Poll until loading completes
		var status = ResourceLoader.load_threaded_get_status(path)
		while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			OS.delay_msec(10) # Small delay to prevent high CPU usage
			status = ResourceLoader.load_threaded_get_status(path)
		
		# Process the result
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var resource = ResourceLoader.load_threaded_get(path)
			if resource:
				# Use call_deferred to update the cache on the main thread
				call_deferred("_cache_resource", resource, type, id)
				_loaded_count += 1
				
				# Emit signals on the main thread
				var progress_data = {"count": _loaded_count, "total": total}
				call_deferred("_emit_loading_progress", progress_data)
				call_deferred("_emit_resource_loaded", type, id, resource)
			else:
				push_error("Failed to load threaded resource: " + path)
		else:
			push_error("Failed to load threaded resource: " + path + ", status: " + str(status))
	
	# Clear queue and emit completion on the main thread
	call_deferred("_finish_loading")
	
	# Thread cleanup happens automatically in Godot 4.x

## Safely emit loading progress signal from thread
func _emit_loading_progress(data: Dictionary):
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - _last_progress_time >= _progress_interval:
		_last_progress_time = current_time
		emit_signal("loading_progress", data.count, data.total)

## Safely emit resource loaded signal from thread
func _emit_resource_loaded(type: String, id: String, resource: Resource):
	emit_signal("resource_loaded", type, id, resource)

## Finish loading process
func _finish_loading():
	_load_queue.clear()
	_is_loading = false
	emit_signal("loading_progress", _loaded_count, _loaded_count)
	emit_signal("all_resources_loaded")

## Add a resource to the cache
func _cache_resource(resource: Resource, type: String, id: String):
	# Create the type category if it doesn't exist
	if not _cache.has(type):
		_cache[type] = {}
	
	# Cache the resource
	_cache[type][id] = resource

## Preload common resources for a specific level or scene
func preload_level_resources(level_name: String) -> bool:
	# This method should be customized per game to preload
	# appropriate resources for each level
	match level_name:
		"main_menu":
			queue_resource("res://scenes/ui/main_menu/main_menu.tscn", "scenes", "main_menu")
			# Add UI elements, backgrounds, etc.
			return true
			
		"adventure_level":
			queue_resource("res://scenes/levels/adventure_mode/adventure_level.tscn", "scenes", "adventure_level")
			# Add player, enemies, items, etc.
			return true
			
		_:
			push_warning("No preload configuration for level: " + level_name)
			return false
	
	return false

## Unload resources that are not needed for the current scene
func unload_unused_resources(keep_types: Array = []):
	var stats_before = get_cache_stats()
	
	# Keep all resources of specified types
	for type in _cache:
		if type in keep_types:
			continue
		
		# Clear this type of resources
		_cache[type].clear()
	
	var stats_after = get_cache_stats()
	print("Unloaded resources - Before: ", stats_before.total, ", After: ", stats_after.total)
	
	# Force garbage collection
	ResourceLoader.load_threaded_request("res://")
	ResourceLoader.load_threaded_get_status("res://")
