class_name MageBall
extends BaseProjectile

## Magisches Projektil verwendet von Goblin Mages
## Enthält Partikeleffekte und hat spezielle Treffereffekte

# Zusätzliche Mage Ball-spezifische Eigenschaften
@export var magic_color: Color = Color(0.5, 0.2, 0.9, 0.7)  # Lila Magie-Farbe
@export var homing_strength: float = 0.0  # Optional: Stärke des Zielsuchens (0 = aus)
@export var emit_particles: bool = true   # Partikel während des Flugs
@export var magic_sound: AudioStream     # Soundeffekt für Magie

# Tracking für Partikelsysteme
var current_particles = []

func _ready():
	# Setze Standardeigenschaften
	speed = 90.0
	damage = 0.5  # 0.25 Leben (der Spieler hat 3 Leben)
	lifetime = 6.0
	gravity_affected = false
	bounce = false
	trail_effect = true
	
	# Magischen Trail-Effekt erstellen
	if trail_effect:
		_setup_magical_trail()
	
	# Animation abspielen
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("flying")
		# Magische Farbe anwenden
		$AnimatedSprite2D.modulate = magic_color
	
	# Lichteffekt hinzufügen, wenn nicht schon vorhanden
	if not has_node("PointLight2D"):
		var light = PointLight2D.new()
		light.color = magic_color
		light.energy = 0.7
		light.texture = load("res://icon.png")  # Ersetze mit besserem Licht-Texture
		light.texture_scale = 0.5
		add_child(light)
	
	# Aura-Sprite hinzufügen
	if not has_node("AuraSprite"):
		var aura = Sprite2D.new()
		aura.name = "AuraSprite"
		aura.texture = load("res://icon.png")  # Ersetze mit Aura-Texture
		aura.modulate = magic_color.lightened(0.3)
		aura.modulate.a = 0.4
		aura.scale = Vector2(1.5, 1.5)
		add_child(aura)
		
		# Aura-Animation
		var tween = create_tween().set_loops()
		tween.tween_property(aura, "scale", Vector2(1.7, 1.7), 0.6)
		tween.tween_property(aura, "scale", Vector2(1.5, 1.5), 0.6)
	
	super._ready()

func _physics_process(delta):
	# Magische Heimsuche, wenn aktiviert
	if homing_strength > 0 and is_instance_valid(source_node) and source_node.state_machine and source_node.state_machine.target:
		var target = source_node.state_machine.target
		if is_instance_valid(target):
			var direction_to_target = (target.global_position - global_position).normalized()
			velocity = velocity.lerp(direction_to_target * speed, homing_strength * delta)
	
	# Partikel emittieren während des Flugs
	if emit_particles and randf() < 0.2:  # 20% Chance pro Frame
		_emit_magic_particle()
	
	# Standard-Physik
	super._physics_process(delta)

# Erstelle einen magischen Trail
func _setup_magical_trail():
	if trail:
		trail.default_color = magic_color
		trail.width = 4.0
		
		# Farbverlauf hinzufügen
		trail.gradient = Gradient.new()
		trail.gradient.add_point(0.0, magic_color.darkened(0.2))
		trail.gradient.add_point(1.0, magic_color.lightened(0.3))

# Emittiere einen einzelnen magischen Partikel
func _emit_magic_particle():
	var particle = CPUParticles2D.new()
	particle.emitting = true
	particle.amount = 3
	particle.lifetime = 0.4
	particle.explosiveness = 0.7
	particle.direction = Vector2(0, 0)
	particle.spread = 180
	particle.gravity = Vector2.ZERO
	particle.initial_velocity_min = 10
	particle.initial_velocity_max = 20
	particle.scale_amount_min = 2.0
	particle.scale_amount_max = 2.0
	particle.color = magic_color
	
	# Füge zum Hauptbaum hinzu (damit sie beim Recycling nicht verschwinden)
	get_tree().current_scene.add_child(particle)
	particle.global_position = global_position
	
	# Tracking für Cleanup
	current_particles.append(particle)
	
	# Auto-Entfernung nach Lebenszeit
	await get_tree().create_timer(particle.lifetime * 1.5).timeout
	if is_instance_valid(particle):
		current_particles.erase(particle)
		particle.queue_free()

# Überschreibe die Treffereffektsmethode für magischen Effekt
func _spawn_hit_effect(hit_position):
	# Magic-Explosion-Effekt
	var explosion = CPUParticles2D.new()
	explosion.emitting = true
	explosion.one_shot = true
	explosion.amount = 20
	explosion.lifetime = 0.5
	explosion.explosiveness = 1.0
	explosion.direction = Vector2(0, -1)
	explosion.spread = 180
	explosion.gravity = Vector2(0, 0)
	explosion.initial_velocity_min = 30
	explosion.initial_velocity_max = 70
	explosion.scale_amount_min = 2.0
	explosion.scale_amount_max = 2.0
	explosion.color = magic_color
	
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = hit_position
	
	# Spiele magischen Sound ab, wenn verfügbar
	if magic_sound:
		var audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = magic_sound
		audio_player.volume_db = -5
		audio_player.max_distance = 300
		audio_player.position = hit_position
		get_tree().current_scene.add_child(audio_player)
		audio_player.play()
		
		# Entferne Audio nach dem Abspielen
		audio_player.finished.connect(func(): audio_player.queue_free())
	
	# Magisches Leuchten (wird mit Zeit schwächer)
	var light = PointLight2D.new()
	light.color = magic_color
	light.energy = 1.0
	light.texture = load("res://icon.png")  # Ersetze mit besserem Licht-Texture
	light.texture_scale = 2.0
	light.position = hit_position
	get_tree().current_scene.add_child(light)
	
	# Ausblenden mit Tween
	var tween = create_tween()
	tween.tween_property(light, "energy", 0.0, 0.5)
	tween.tween_callback(func(): light.queue_free())
	
	# Entferne Explosion nach der Lebenszeit
	await get_tree().create_timer(explosion.lifetime * 1.5).timeout
	if is_instance_valid(explosion):
		explosion.queue_free()

# Überschreibe die Recycling-Methode
func _on_recycle_to_pool():
	super._on_recycle_to_pool()
	
	# Bereinige alle noch aktiven Partikel
	for particle in current_particles:
		if is_instance_valid(particle):
			particle.queue_free()
	current_particles.clear()
