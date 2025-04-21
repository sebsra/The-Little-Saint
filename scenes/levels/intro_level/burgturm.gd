extends Node2D

# Signal emitted when gate is opened
signal gate_opened

# Reference to components
@onready var gate = $Falltür
@onready var tower_guard = $TowerGuard
@onready var detection_area = $DetectionArea

# Gate animation parameters
var gate_animation_duration = 1.5
var gate_animation_distance = -100  # Negative value to move up
var is_gate_open = false

# Scene transition parameters
var scene_transition_delay = 3.0
var next_scene_path = "res://scenes/levels/heavenly_realm/heavenly_realm/heavenly_realm.tscn"

func _ready():
	# Initialize components if they exist
	if not gate or not tower_guard:
		push_error("Gate or TowerGuard not found in scene!")
		
	# Connect to BeggarChild's helped signal if it exists
	var beggar_child = get_node_or_null("../BeggarChild")
	if beggar_child:
		if not beggar_child.is_connected("helped", Callable(self, "_on_beggar_child_helped")):
			beggar_child.connect("helped", Callable(self, "_on_beggar_child_helped"))
			print("Connected to BeggarChild's helped signal")
	
	# Make sure TowerGuard has the right path names
	if tower_guard:
		print("Found TowerGuard in Burgturm scene")
		
		# Tell the tower guard to get reference to the correct gate
		if gate:
			tower_guard.gate_node = gate
			print("Updated TowerGuard's gate reference")
			
		# Force recalculation of patrol boundaries
		tower_guard.calculate_patrol_boundaries()
	
	# Connect the DetectionArea to the tower guard
	connect_detection_area_to_guard()
	
	# Force one frame delay before connecting signals to ensure nodes are ready
	get_tree().create_timer(0.1).connect("timeout", Callable(self, "delayed_connections"))

# Delayed connections to ensure nodes are fully ready
func delayed_connections():
	if detection_area and tower_guard:
		# Verify the connection worked by testing it
		print("Testing detection area connection...")
		
		# Force signal connection again
		if not detection_area.is_connected("body_entered", Callable(tower_guard, "_on_area_body_entered")):
			detection_area.connect("body_entered", Callable(tower_guard, "_on_area_body_entered"))
			print("Reconnected Burgturm's DetectionArea to tower guard")
		else:
			print("DetectionArea already connected to tower guard")

# Connect the scene's DetectionArea to the tower guard for interaction
func connect_detection_area_to_guard():
	if detection_area and tower_guard:
		# First disconnect any existing connections to prevent duplicates
		if detection_area.is_connected("body_entered", Callable(tower_guard, "_on_area_body_entered")):
			detection_area.disconnect("body_entered", Callable(tower_guard, "_on_area_body_entered"))
		
		# Connect area signal to tower guard
		detection_area.connect("body_entered", Callable(tower_guard, "_on_area_body_entered"))
		print("Connected Burgturm's DetectionArea to tower guard")
		
		# Also connect the body_exited signal
		if detection_area.is_connected("body_exited", Callable(tower_guard, "_on_detection_area_body_exited")):
			detection_area.disconnect("body_exited", Callable(tower_guard, "_on_detection_area_body_exited"))
		
		detection_area.connect("body_exited", Callable(tower_guard, "_on_detection_area_body_exited"))
		print("Connected Burgturm's DetectionArea body_exited to tower guard")

# Function to be connected to beggar child's help signal
func _on_beggar_child_helped():
	if tower_guard:
		tower_guard.set_thomas_helped(true)
		print("Notified tower guard that Thomas was helped")
		
		# Take a screenshot when the beggar child is helped
		var screenshot_id = "child_helped_" + str(Time.get_unix_time_from_system())
		ScreenshotManager.take_screenshot(screenshot_id, 0.1)
		
		# Add to memorable screenshots
		if not "child_helped" in Global.memorable_screenshots:
			Global.memorable_screenshots["child_helped"] = []
		Global.memorable_screenshots["child_helped"].append(screenshot_id)

# Open the gate
func open_gate():
	if gate and not is_gate_open:
		is_gate_open = true
		
		# Create a tween to animate the gate movement
		var tween = get_tree().create_tween()
		tween.tween_property(gate, "position:y", 
			gate.position.y + gate_animation_distance, 
			gate_animation_duration).set_ease(Tween.EASE_OUT)
		
		# Emit gate opened signal
		gate_opened.emit()
		
		# Schedule scene transition after gate opens
		get_tree().create_timer(gate_animation_duration + scene_transition_delay).connect("timeout", 
			Callable(self, "transition_to_next_scene"))
		
		print("Gate opening sequence initiated")

# Transition to the next scene
func transition_to_next_scene():
	print("Transitioning to next scene: " + next_scene_path)
	get_tree().change_scene_to_file(next_scene_path)
