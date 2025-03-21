class_name UITheme
extends Node

## A central manager for UI themes and styling across the game
## Handles theme properties, color palettes, and consistent UI elements

# Current theme name
var current_theme: String = "default"

# Available themes
var available_themes: Array = ["default", "dark", "light", "custom"]

# Color palettes for each theme
var theme_colors = {
	"default": {
		"background": Color("#1f1f1f"),
		"foreground": Color("#ffffff"),
		"primary": Color("#e7896a"),      # Clay/terracotta color from your game
		"secondary": Color("#4aa8d8"),    # Blue accent
		"accent": Color("#a8d84a"),       # Green accent
		"error": Color("#d84a4a"),        # Red for errors/warnings
		"success": Color("#4ad84a"),      # Green for success
		"warning": Color("#d8d84a"),      # Yellow for warnings
		"disabled": Color("#7f7f7f"),     # Gray for disabled elements
		"transparent": Color(0, 0, 0, 0)  # Fully transparent
	},
	"dark": {
		"background": Color("#121212"),
		"foreground": Color("#f0f0f0"),
		"primary": Color("#d87a5f"),      # Darker clay color
		"secondary": Color("#3a8ab8"),    # Darker blue
		"accent": Color("#8ab83a"),       # Darker green
		"error": Color("#b83a3a"),        # Darker red
		"success": Color("#3ab83a"),      # Darker green
		"warning": Color("#b8b83a"),      # Darker yellow
		"disabled": Color("#5f5f5f"),     # Darker gray
		"transparent": Color(0, 0, 0, 0)
	},
	"light": {
		"background": Color("#f5f5f5"),
		"foreground": Color("#202020"),
		"primary": Color("#ff9478"),      # Lighter clay color
		"secondary": Color("#78c4ff"),    # Lighter blue
		"accent": Color("#c4ff78"),       # Lighter green
		"error": Color("#ff7878"),        # Lighter red
		"success": Color("#78ff78"),      # Lighter green
		"warning": Color("#ffff78"),      # Lighter yellow
		"disabled": Color("#a0a0a0"),     # Lighter gray
		"transparent": Color(0, 0, 0, 0)
	},
	"custom": {
		# Will be populated from user settings
	}
}

# Font sizes for different UI elements
var font_sizes = {
	"small": 12,
	"regular": 16,
	"large": 20,
	"title": 24,
	"heading": 32
}

# Margin and padding sizes
var spacing = {
	"tiny": 2,
	"small": 4,
	"regular": 8,
	"large": 16,
	"xlarge": 24
}

# Corner radius for UI elements
var corner_radius = {
	"none": 0,
	"small": 4,
	"regular": 8,
	"large": 16,
	"pill": 9999  # Very large value for pill shape
}

# Animation durations
var animation_durations = {
	"fast": 0.1,
	"regular": 0.3,
	"slow": 0.5
}

# Default fonts
var fonts = {
	"regular": null,
	"bold": null,
	"title": null,
	"monospace": null
}

# Signal emitted when theme changes
signal theme_changed(theme_name)

# Initialize the theme system
func _ready():
	# Load fonts
	_load_fonts()
	
	# Try to load user theme preferences
	_load_theme_preferences()
	
	print("UI Theme Manager initialized with theme: ", current_theme)

# Set the active theme
func set_theme(theme_name: String) -> bool:
	if theme_name in available_themes:
		current_theme = theme_name
		emit_signal("theme_changed", theme_name)
		return true
	return false

# Get a color from the current theme
func get_color(color_name: String) -> Color:
	if theme_colors.has(current_theme) and theme_colors[current_theme].has(color_name):
		return theme_colors[current_theme][color_name]
	
	# Fallback to default theme
	if theme_colors["default"].has(color_name):
		return theme_colors["default"][color_name]
	
	# Ultimate fallback
	push_warning("Color not found: " + color_name)
	return Color.WHITE

# Get a font size
func get_font_size(size_name: String) -> int:
	if font_sizes.has(size_name):
		return font_sizes[size_name]
	
	push_warning("Font size not found: " + size_name)
	return font_sizes["regular"]

# Get spacing value
func get_spacing(spacing_name: String) -> int:
	if spacing.has(spacing_name):
		return spacing[spacing_name]
	
	push_warning("Spacing not found: " + spacing_name)
	return spacing["regular"]

# Get corner radius
func get_corner_radius(radius_name: String) -> int:
	if corner_radius.has(radius_name):
		return corner_radius[radius_name]
	
	push_warning("Corner radius not found: " + radius_name)
	return corner_radius["regular"]

# Get animation duration
func get_animation_duration(duration_name: String) -> float:
	if animation_durations.has(duration_name):
		return animation_durations[duration_name]
	
	push_warning("Animation duration not found: " + duration_name)
	return animation_durations["regular"]

# Get a font
func get_font(font_name: String) -> Font:
	if fonts.has(font_name) and fonts[font_name] != null:
		return fonts[font_name]
	
	push_warning("Font not found: " + font_name)
	return fonts["regular"] if fonts["regular"] != null else null

# Create a panel style with theme colors
func create_panel_style(
	bg_color_name: String = "background",
	border_color_name: String = "",
	radius_name: String = "regular",
	border_width: int = 0
) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	
	# Set background color
	style.bg_color = get_color(bg_color_name)
	
	# Set corner radius
	var radius = get_corner_radius(radius_name)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	
	# Set border if requested
	if border_color_name != "" and border_width > 0:
		style.border_width_left = border_width
		style.border_width_top = border_width
		style.border_width_right = border_width
		style.border_width_bottom = border_width
		style.border_color = get_color(border_color_name)
	
	return style

# Create a button style with normal, hover, pressed states
func create_button_style(
	normal_color_name: String = "primary",
	hover_color_name: String = "",
	pressed_color_name: String = "",
	disabled_color_name: String = "disabled",
	radius_name: String = "regular",
	border_width: int = 0
) -> Dictionary:
	# Get the normal color
	var normal_color = get_color(normal_color_name)
	
	# Calculate derived colors or get specified colors
	var hover_color: Color
	var pressed_color: Color
	
	if hover_color_name == "":
		hover_color = normal_color.lightened(0.1)
	else:
		hover_color = get_color(hover_color_name)
	
	if pressed_color_name == "":
		pressed_color = normal_color.darkened(0.1)
	else:
		pressed_color = get_color(pressed_color_name)
	
	# Create styles for each state
	var normal_style = create_panel_style(normal_color_name, "", radius_name, border_width)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = hover_color
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = pressed_color
	
	var disabled_style = normal_style.duplicate()
	disabled_style.bg_color = get_color(disabled_color_name)
	
	return {
		"normal": normal_style,
		"hover": hover_style,
		"pressed": pressed_style,
		"disabled": disabled_style
	}

# Apply theme to a control
func apply_theme_to_control(control: Control, theme_preset: String = "default") -> void:
	match theme_preset:
		"default":
			_apply_default_theme(control)
		"button":
			_apply_button_theme(control)
		"panel":
			_apply_panel_theme(control)
		"label":
			_apply_label_theme(control)
		_:
			push_warning("Unknown theme preset: " + theme_preset)
			_apply_default_theme(control)

# Set custom theme colors
func set_custom_colors(colors: Dictionary) -> void:
	for color_name in colors:
		if color_name in theme_colors["custom"]:
			theme_colors["custom"][color_name] = colors[color_name]
	
	# Ensure all colors are defined
	for color_name in theme_colors["default"]:
		if not theme_colors["custom"].has(color_name):
			theme_colors["custom"][color_name] = theme_colors["default"][color_name]
	
	# If custom theme is current, notify of change
	if current_theme == "custom":
		emit_signal("theme_changed", current_theme)

# Save theme preferences
func save_theme_preferences() -> bool:
	var config = ConfigFile.new()
	
	# Store current theme
	config.set_value("theme", "current_theme", current_theme)
	
	# Store custom theme colors
	config.set_value("theme", "custom_colors", theme_colors["custom"])
	
	# Store font sizes
	config.set_value("theme", "font_sizes", font_sizes)
	
	# Save the config
	var err = config.save("user://theme_settings.cfg")
	return err == OK

# Load the fonts
func _load_fonts() -> void:
	var default_font = load("res://assets/fonts/general/default_font.tres") if ResourceLoader.exists("res://assets/fonts/general/default_font.tres") else null
	
	fonts["regular"] = default_font
	fonts["bold"] = load("res://assets/fonts/general/default_font_bold.tres") if ResourceLoader.exists("res://assets/fonts/general/default_font_bold.tres") else default_font
	fonts["title"] = load("res://assets/fonts/special/copyduck/Copyduck.ttf") if ResourceLoader.exists("res://assets/fonts/special/copyduck/Copyduck.ttf") else default_font
	fonts["monospace"] = load("res://assets/fonts/general/default_mono.tres") if ResourceLoader.exists("res://assets/fonts/general/default_mono.tres") else default_font

# Load theme preferences from config
func _load_theme_preferences() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://theme_settings.cfg")
	
	if err == OK:
		# Load current theme
		var saved_theme = config.get_value("theme", "current_theme", "default")
		if saved_theme in available_themes:
			current_theme = saved_theme
		
		# Load custom colors
		var saved_colors = config.get_value("theme", "custom_colors", {})
		for color_name in saved_colors:
			theme_colors["custom"][color_name] = saved_colors[color_name]
		
		# Load font sizes
		var saved_font_sizes = config.get_value("theme", "font_sizes", {})
		for size_name in saved_font_sizes:
			font_sizes[size_name] = saved_font_sizes[size_name]
	else:
		# If no config exists, initialize custom theme with default colors
		theme_colors["custom"] = theme_colors["default"].duplicate()

# Apply default theme to a control
func _apply_default_theme(control: Control) -> void:
	var theme_override = Theme.new()
	
	# Set default font
	if fonts["regular"]:
		theme_override.default_font = fonts["regular"]
		theme_override.default_font_size = get_font_size("regular")
	
	# Set default colors
	theme_override.set_color("font_color", "Label", get_color("foreground"))
	theme_override.set_color("font_focus_color", "Label", get_color("primary"))
	
	control.theme = theme_override

# Apply button theme
func _apply_button_theme(button: Control) -> void:
	if not button is Button:
		push_warning("Cannot apply button theme to non-Button control")
		return
	
	# Apply default theme first
	_apply_default_theme(button)
	
	# Create button styles
	var styles = create_button_style()
	
	# Apply button styles
	button.add_theme_stylebox_override("normal", styles["normal"])
	button.add_theme_stylebox_override("hover", styles["hover"])
	button.add_theme_stylebox_override("pressed", styles["pressed"])
	button.add_theme_stylebox_override("disabled", styles["disabled"])
	
	# Set colors
	button.add_theme_color_override("font_color", get_color("foreground"))
	button.add_theme_color_override("font_focus_color", get_color("foreground"))
	button.add_theme_color_override("font_disabled_color", get_color("disabled"))
	
	# Set font
	if fonts["bold"]:
		button.add_theme_font_override("font", fonts["bold"])

# Apply panel theme
func _apply_panel_theme(panel: Control) -> void:
	if not panel is Panel:
		push_warning("Cannot apply panel theme to non-Panel control")
		return
	
	# Apply default theme first
	_apply_default_theme(panel)
	
	# Create panel style
	var style = create_panel_style("background", "foreground", "regular", 1)
	
	# Apply panel style
	panel.add_theme_stylebox_override("panel", style)

# Apply label theme
func _apply_label_theme(label: Control) -> void:
	if not label is Label:
		push_warning("Cannot apply label theme to non-Label control")
		return
	
	# Apply default theme first
	_apply_default_theme(label)
	
	# Set colors
	label.add_theme_color_override("font_color", get_color("foreground"))
	label.add_theme_color_override("font_shadow_color", get_color("background"))
	
	# Set font
	label.add_theme_font_override("font", fonts["regular"])
	label.add_theme_font_size_override("font_size", get_font_size("regular"))
