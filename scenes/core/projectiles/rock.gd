class_name Rock
extends BaseProjectile

## Stein-Projektil abgeschossen von Goblin Archers
## Ist von der Schwerkraft beeinflusst und kann abprallen

# Rock-spezifische Eigenschaften
@export var max_bounces: int = 2  # Maximale Anzahl an Abprallvorgängen
@export var impact_sound: AudioStream  # Sound beim Aufprall
@export var size_variation: float = 0.2  # Zufällige Größenvariation
@export var dust_on_bounce: bool = true  # Staubeffekt beim Abprallen
@export var rotation_speed: float = 5.0  # Wie schnell der Stein rotiert

# Tracking-Variablen
var bounces_remaining: int = 0
var current_dust_particles = []

func _ready():
	# Setze Standardeigenschaften
	speed = 300.0  # Reduzierte Geschwindigkeit für bessere Kollisionserkennung
	damage = 0.25  # 0.25 Leben (weniger Schaden als Magie)
	lifetime = 4.0
	gravity_affected = true
	bounce = true
	bounce_factor = 0.6  # Verliert 40% Energie beim Abprallen
	
	# Setze Abprallzähler
	bounces_remaining = max_bounces
	
	# Animation abspielen
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("flying")
		
		# Zufällige Größenvariation für mehr Natürlichkeit
		var size_factor = 1.0 + randf_range(-size_variation, size_variation)
		$AnimatedSprite2D.scale = Vector2(size_factor, size_factor)
		
		# Zufällige Anfangsrotation
		$AnimatedSprite2D.rotation = randf() * TAU
	
	# Zufällige Variation in der Geschwindigkeit (reduziert auf ±5%)
	speed = speed * (1.0 + randf_range(-0.05, 0.05))
	
	super._ready()

func _physics_process(delta):
	# Drehe den Sprite basierend auf der Bewegungsrichtung
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.rotation += rotation_speed * delta
	
	# Standard-Physik
	super._physics_process(delta)

# Überschriebene Kollisionsmethode für verbesserte Abprall-Logik
func _on_collision(collision):
	var collider = collision.get_collider()
	if collider == null:
		return
	# Zusätzliche Prüfung auf gültige Gruppen
	var is_player = collider.is_in_group("player") if collider.has_method("is_in_group") else false
	var is_enemy = collider.is_in_group("enemy") if collider.has_method("is_in_group") else false
	
	# Prüfe auf Abprallen für Umgebungsobjekte
	if bounce and bounces_remaining > 0 and not (is_player or is_enemy):
		var reflection = collision.get_remainder().bounce(collision.get_normal())
		velocity = velocity.bounce(collision.get_normal()) * bounce_factor
		global_position += reflection
		
		# Reduziere verbleibende Abprallvorgänge
		bounces_remaining -= 1
		
		# Spiele Abprallsound ab
		_play_bounce_sound(collision.get_position())
		
		# Erzeuge Staubeffekt
		if dust_on_bounce:
			_spawn_dust_effect(collision.get_position(), collision.get_normal())
		
		# Sende Abprall-Signal
		emit_signal("projectile_bounce", self, collision.get_position(), collision.get_normal())
		
		# Wenn keine Abprallvorgänge mehr übrig, markiere als getroffen bei nächster Kollision
		if bounces_remaining <= 0:
			bounce = false
		
		return
	
	# Standard-Kollision für alles andere
	has_hit = true
	
	# Verarbeite verschiedene Kollisionstypen
	if is_player and source_node != collider:
		_on_hit_player(collider, collision.get_position())
	elif is_enemy and source_node != collider:
		_on_hit_enemy(collider, collision.get_position())
	else:
		_on_hit_environment(collider, collision.get_position())
	
	_recycle_or_free()

# Spiele Abprallsound ab
func _play_bounce_sound(position):
	if impact_sound:
		var audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = impact_sound
		audio_player.volume_db = -10
		audio_player.max_distance = 200
		audio_player.position = position
		get_tree().current_scene.add_child(audio_player)
		audio_player.play()
		
		# Entferne Audio nach dem Abspielen
		audio_player.finished.connect(func(): audio_player.queue_free())
	else:
		# Standardsound wenn keiner definiert ist
		var audio_player = AudioStreamPlayer2D.new()
		var sound_index = randi() % 3 + 1  # Zufällig zwischen 1-3
		var sound_path = "res://assets/audio/sfx/rock_impact" + str(sound_index) + ".wav"
		var sound = load(sound_path) if ResourceLoader.exists(sound_path) else null
		
		if sound:
			audio_player.stream = sound
			audio_player.volume_db = -15
			audio_player.position = position
			get_tree().current_scene.add_child(audio_player)
			audio_player.play()
			audio_player.finished.connect(func(): audio_player.queue_free())

# Erzeuge Staubeffekt beim Abprallen
func _spawn_dust_effect(position, normal):
	var dust = CPUParticles2D.new()
	dust.emitting = true
	dust.one_shot = true
	dust.explosiveness = 0.8
	dust.amount = 8
	dust.lifetime = 0.5
	dust.direction = Vector2(-normal.x, -normal.y)
	dust.spread = 45
	dust.gravity = Vector2(0, 20)
	dust.initial_velocity_min = 10
	dust.initial_velocity_max = 30
	dust.scale_amount = 1.5
	dust.color = Color(0.7, 0.7, 0.5, 0.7)  # Staubfarbe
	
	get_tree().current_scene.add_child(dust)
	dust.global_position = position
	
	# Tracking für Cleanup
	current_dust_particles.append(dust)
	
	# Auto-Entfernung nach Lebenszeit
	await get_tree().create_timer(dust.lifetime * 1.5).timeout
	if is_instance_valid(dust):
		current_dust_particles.erase(dust)
		dust.queue_free()

# Überschreibe die Treffereffektsmethode für Steineffekt
func _spawn_hit_effect(hit_position):
	# Steinimpakt-Effekt mit Steinsplittern
	var impact = CPUParticles2D.new()
	impact.emitting = true
	impact.one_shot = true
	impact.amount = 10
	impact.lifetime = 0.7
	impact.explosiveness = 1.0
	impact.spread = 180
	impact.gravity = Vector2(0, 98)
	impact.initial_velocity_min = 20
	impact.initial_velocity_max = 50
	impact.scale_amount_min = 2.0
	impact.scale_amount_max = 2.0
	impact.color = Color(0.6, 0.5, 0.4)  # Steinfarbe
	
	get_tree().current_scene.add_child(impact)
	impact.global_position = hit_position
	
	# Spiele Aufprallsound ab
	_play_bounce_sound(hit_position)
	
	# Entferne Impact nach der Lebenszeit
	await get_tree().create_timer(impact.lifetime * 1.5).timeout
	if is_instance_valid(impact):
		impact.queue_free()

# Setup-Methode überschreiben um Abprallzähler zurückzusetzen
func setup(dir: Vector2, spawn_pos: Vector2, spawn_rot: float = 0.0, source = null):
	# Normal-Setup durchführen
	super.setup(dir, spawn_pos, spawn_rot, source)
	
	# Abprallzähler zurücksetzen
	bounces_remaining = max_bounces
	bounce = true
	
	# Stelle sicher, dass Geschwindigkeit korrekt gesetzt wird
	velocity = direction.normalized() * speed
	
	return self

# Überschreibe die Recycling-Methode
func _on_recycle_to_pool():
	super._on_recycle_to_pool()
	
	# Abprallzähler zurücksetzen
	bounces_remaining = max_bounces
	bounce = true
	
	# Bereinige alle noch aktiven Partikel
	for particle in current_dust_particles:
		if is_instance_valid(particle):
			particle.queue_free()
	current_dust_particles.clear()
