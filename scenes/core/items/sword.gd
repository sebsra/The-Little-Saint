extends Node2D

# Variablen für den Leuchteffekt
@export var glow_color: Color = Color(1.0, 0.9, 0.0, 0.8)  # Gelbes Leuchten
@export var glow_intensity_min: float = 0.1  # Niedriger für stärkeren Kontrast
@export var glow_intensity_max: float = 0.8  # Höher für stärkeres Leuchten
@export var glow_speed: float = 1.2  # Schnelleres Pulsieren

# Referenz auf das Schwert-Sprite und den Tween
var sword_sprite: Sprite2D
var current_tween: Tween

func _ready():
	# Referenz zum Schwert-Sprite holen
	sword_sprite = $Sword
	
	# Shader erstellen
	var shader_code = """
	shader_type canvas_item;
	
	uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.0, 0.8);
	uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0;
	
	void fragment() {
		vec4 current_color = texture(TEXTURE, UV);
		float alpha = current_color.a;
		vec3 final_color = mix(current_color.rgb, glow_color.rgb, glow_intensity * 0.6);
		final_color += glow_color.rgb * glow_intensity * 0.4;
		COLOR = vec4(final_color, alpha);
	}
	"""
	
	# Shader anwenden
	var shader = Shader.new()
	shader.code = shader_code
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("glow_color", glow_color)
	material.set_shader_parameter("glow_intensity", glow_intensity_min)
	sword_sprite.material = material
	
	# Pulsieren sofort starten (automatisch)
	create_pulsing_tween()

# Funktion zum Erstellen des pulsierenden Effekts
func create_pulsing_tween():
	if current_tween:
		current_tween.kill()
	
	current_tween = create_tween()
	current_tween.set_loops()  # Endlos wiederholen
	
	# Von min zu max
	current_tween.tween_method(
		func(intensity): 
			sword_sprite.material.set_shader_parameter("glow_intensity", intensity),
		glow_intensity_min, 
		glow_intensity_max, 
		1.0 / glow_speed
	)
	
	# Von max zurück zu min
	current_tween.tween_method(
		func(intensity): 
			sword_sprite.material.set_shader_parameter("glow_intensity", intensity),
		glow_intensity_max, 
		glow_intensity_min, 
		1.0 / glow_speed
	)
	
	return current_tween


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Take a screenshot before the sword disappears
		var screenshot_id = "sword_collected_" + str(Time.get_unix_time_from_system())
		ScreenshotManager.take_screenshot(screenshot_id, 0.1)
		
		# Add to memorable screenshots
		if not "sword_collections" in Global.memorable_screenshots:
			Global.memorable_screenshots["sword_collections"] = []
		Global.memorable_screenshots["sword_collections"].append(screenshot_id)
		
		# Schwert verschwindet
		queue_free()  # oder sword_sprite.hide(), je nach Wunsch
		Global.collect_sword()
