class_name ObjectiveTracker
extends Control

## A UI component for tracking and displaying game objectives
## Supports multiple objectives with progress tracking

# UI components
@onready var objectives_container = $ObjectivesContainer
@onready var objective_template = $ObjectiveTemplate

# Data structure for tracking objectives
var objectives = {}

# Optional theme reference
var ui_theme = null

# Signals
signal objective_added(objective_id, description, total)
signal objective_updated(objective_id, progress, total)
signal objective_completed(objective_id)
signal all_objectives_completed()

func _ready():
	# Hide the template
	if objective_template:
		objective_template.visible = false
	
	# Try to get UI theme
	ui_theme = get_node_or_null("/root/UITheme")
	if ui_theme:
		ui_theme.theme_changed.connect(_on_theme_changed)
		_apply_theme()

# Add a new objective to track
func add_objective(objective_id: String, description: String, total: int = 1) -> bool:
	if objectives.has(objective_id):
		push_warning("Objective already exists: " + objective_id)
		return false
	
	# Create new objective data
	objectives[objective_id] = {
		"description": description,
		"progress": 0,
		"total": total,
		"completed": false,
		"ui_element": null
	}
	
	# Create UI element
	_create_objective_ui(objective_id)
	
	emit_signal("objective_added", objective_id, description, total)
	return true

# Update an objective's progress
func update_objective(objective_id: String, progress: int, total: int = -1, description: String = "") -> bool:
	if not objectives.has(objective_id):
		push_warning("Cannot update non-existent objective: " + objective_id)
		return false
	
	var objective = objectives[objective_id]
	
	# Update the progress
	objective.progress = progress
	
	# Update total if specified
	if total > 0:
		objective.total = total
		
	# Update description if provided
	if description != "":
		objective.description = description
	
	# Check if newly completed
	var newly_completed = false
	if progress >= objective.total and not objective.completed:
		objective.completed = true
		newly_completed = true
	
	# Update UI
	_update_objective_ui(objective_id)
	
	# Handle completion
	if newly_completed:
		emit_signal("objective_completed", objective_id)
		_check_all_objectives_completed()
	else:
		emit_signal("objective_updated", objective_id, progress, objective.total)
	
	return true

# Mark an objective as complete
func complete_objective(objective_id: String) -> bool:
	if not objectives.has(objective_id):
		push_warning("Cannot complete non-existent objective: " + objective_id)
		return false
	
	var objective = objectives[objective_id]
	
	# Check if already completed
	if objective.completed:
		return true
	
	# Set as completed
	objective.progress = objective.total
	objective.completed = true
	
	# Update UI
	_update_objective_ui(objective_id)
	
	emit_signal("objective_completed", objective_id)
	_check_all_objectives_completed()
	
	return true

# Remove an objective
func remove_objective(objective_id: String) -> bool:
	if not objectives.has(objective_id):
		push_warning("Cannot remove non-existent objective: " + objective_id)
		return false
	
	var objective = objectives[objective_id]
	
	# Remove UI element if it exists
	if objective.ui_element and is_instance_valid(objective.ui_element):
		objective.ui_element.queue_free()
	
	# Remove from tracking
	objectives.erase(objective_id)
	
	return true

# Clear all objectives
func clear_all_objectives() -> void:
	# Remove all UI elements
	for objective_id in objectives:
		var objective = objectives[objective_id]
		if objective.ui_element and is_instance_valid(objective.ui_element):
			objective.ui_element.queue_free()
	
	# Clear the tracking dictionary
	objectives.clear()

# Check if all objectives are completed
func are_all_objectives_completed() -> bool:
	if objectives.size() == 0:
		return false
	
	for objective_id in objectives:
		if not objectives[objective_id].completed:
			return false
	
	return true

# Check if a specific objective exists
func has_objective(objective_id: String) -> bool:
	return objectives.has(objective_id)

# Check if a specific objective is completed
func is_objective_completed(objective_id: String) -> bool:
	if not objectives.has(objective_id):
		return false
	return objectives[objective_id].completed

# Get objective progress
func get_objective_progress(objective_id: String) -> Dictionary:
	if not objectives.has(objective_id):
		return {}
	
	var objective = objectives[objective_id]
	return {
		"progress": objective.progress,
		"total": objective.total,
		"completed": objective.completed
	}

# Create UI for a new objective
func _create_objective_ui(objective_id: String) -> void:
	if not objective_template or not objectives_container:
		push_error("Objective tracker UI components not found")
		return
	
	var objective = objectives[objective_id]
	
	# Create from template
	var new_objective_ui = objective_template.duplicate()
	new_objective_ui.name = "Objective_" + objective_id
	new_objective_ui.visible = true
	objectives_container.add_child(new_objective_ui)
	
	# Set initial content
	var description_label = new_objective_ui.get_node_or_null("Description")
	var progress_label = new_objective_ui.get_node_or_null("Progress")
	var progress_bar = new_objective_ui.get_node_or_null("ProgressBar")
	
	if description_label:
		description_label.text = objective.description
	
	if progress_label:
		if objective.total > 1:
			progress_label.text = str(objective.progress) + " / " + str(objective.total)
		else:
			progress_label.visible = false
	
	if progress_bar:
		if objective.total > 1:
			progress_bar.max_value = objective.total
			progress_bar.value = objective.progress
		else:
			progress_bar.visible = false
	
	# Store the UI reference
	objective.ui_element = new_objective_ui
	
	# Apply theme
	if ui_theme:
		_apply_theme_to_objective(new_objective_ui, objective.completed)

# Update UI for an existing objective
func _update_objective_ui(objective_id: String) -> void:
	if not objectives.has(objective_id):
		return
	
	var objective = objectives[objective_id]
	var ui_element = objective.ui_element
	
	if not ui_element or not is_instance_valid(ui_element):
		return
	
	# Update content
	var description_label = ui_element.get_node_or_null("Description")
	var progress_label = ui_element.get_node_or_null("Progress")
	var progress_bar = ui_element.get_node_or_null("ProgressBar")
	var completed_icon = ui_element.get_node_or_null("CompletedIcon")
	
	if description_label:
		description_label.text = objective.description
	
	if progress_label:
		if objective.total > 1:
			progress_label.text = str(objective.progress) + " / " + str(objective.total)
			progress_label.visible = true
		else:
			progress_label.visible = false
	
	if progress_bar:
		if objective.total > 1:
			progress_bar.max_value = objective.total
			progress_bar.value = objective.progress
			progress_bar.visible = true
		else:
			progress_bar.visible = false
	
	if completed_icon:
		completed_icon.visible = objective.completed
	
	# Apply theme with completion state
	if ui_theme:
		_apply_theme_to_objective(ui_element, objective.completed)
	
	# Apply completed styling
	if objective.completed:
		# Visual indication of completion
		if description_label:
			description_label.modulate = Color(0.7, 1.0, 0.7)  # Slight green tint
		
		# Add completion animation if needed
		if not ui_element.has_meta("completion_animated"):
			var tween = create_tween()
			tween.tween_property(ui_element, "modulate", Color(1.5, 1.5, 1.5), 0.2)
			tween.tween_property(ui_element, "modulate", Color(1, 1, 1), 0.3)
			ui_element.set_meta("completion_animated", true)

# Check if all objectives are completed and emit signal if so
func _check_all_objectives_completed() -> void:
	if are_all_objectives_completed():
		emit_signal("all_objectives_completed")

# Apply theme to the entire tracker
func _apply_theme() -> void:
	if not ui_theme:
		return
	
	# Apply to container background if needed
	var panel = get_node_or_null("Background")
	if panel and panel is Panel:
		var style = ui_theme.create_panel_style("background", "", "small", 0)
		panel.add_theme_stylebox_override("panel", style)
	
	# Apply to all objective UI elements
	for objective_id in objectives:
		var objective = objectives[objective_id]
		if objective.ui_element and is_instance_valid(objective.ui_element):
			_apply_theme_to_objective(objective.ui_element, objective.completed)

# Apply theme to a specific objective UI element
func _apply_theme_to_objective(ui_element: Control, is_completed: bool) -> void:
	if not ui_theme:
		return
	
	var description_label = ui_element.get_node_or_null("Description")
	var progress_label = ui_element.get_node_or_null("Progress")
	var progress_bar = ui_element.get_node_or_null("ProgressBar")
	
	if description_label:
		var color = ui_theme.get_color("success") if is_completed else ui_theme.get_color("foreground")
		description_label.add_theme_color_override("font_color", color)
	
	if progress_label:
		progress_label.add_theme_color_override("font_color", ui_theme.get_color("secondary"))
	
	if progress_bar:
		# Style the progress bar
		var fg_stylebox = StyleBoxFlat.new()
		fg_stylebox.bg_color = ui_theme.get_color("primary")
		fg_stylebox.corner_radius_top_left = ui_theme.get_corner_radius("small")
		fg_stylebox.corner_radius_top_right = ui_theme.get_corner_radius("small")
		fg_stylebox.corner_radius_bottom_left = ui_theme.get_corner_radius("small")
		fg_stylebox.corner_radius_bottom_right = ui_theme.get_corner_radius("small")
		
		var bg_stylebox = fg_stylebox.duplicate()
		bg_stylebox.bg_color = ui_theme.get_color("background").lightened(0.1)
		
		progress_bar.add_theme_stylebox_override("fill", fg_stylebox)
		progress_bar.add_theme_stylebox_override("background", bg_stylebox)

# Handle theme changes
func _on_theme_changed(_theme_name) -> void:
	_apply_theme()
