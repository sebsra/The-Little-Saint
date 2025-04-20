class_name SackOfGold
extends Area2D

# Animationsparameter
var bounce_height: float = 6.0
var bounce_speed: float = 2.0

# Variablen für Animation
var animation_time: float = 0.0
var spawn_position: Vector2
var is_position_initialized: bool = false
var is_collected: bool = false

# StaticBody2D für den aufgesammelten Zustand
var static_body: StaticBody2D

# Signale
signal sack_of_gold_collected(sack_of_gold, player)
signal sack_of_gold_dropped(sack_of_gold, position)

func _ready():
	# Kollisionssignal verbinden
	body_entered.connect(_on_sack_of_gold_body_entered)
	# Warten auf nächsten Frame für korrekte Positionsinitialisierung
	call_deferred("_init_position")
	
	# StaticBody2D erstellen (wird verwendet, wenn der Sack aufgesammelt wird)
	static_body = StaticBody2D.new()
	static_body.name = "StaticBody"
	
	# Kollisionsform vom Area2D kopieren
	var collision_shape = CollisionShape2D.new()
	if has_node("CollisionShape2D"):
		var original_shape = get_node("CollisionShape2D")
		collision_shape.shape = original_shape.shape.duplicate()
		collision_shape.position = original_shape.position
		static_body.add_child(collision_shape)
	
	# StaticBody zunächst deaktivieren
	static_body.visible = false
	static_body.process_mode = PROCESS_MODE_DISABLED

func _init_position():
	# Auf einen Frame warten, um sicherzustellen, dass die Position korrekt ist
	await get_tree().process_frame
	spawn_position = global_position
	is_position_initialized = true
	
	# StaticBody zu sich selbst hinzufügen, aber noch nicht aktivieren
	add_child(static_body)

func _process(delta):
	# Nur animieren, wenn Position initialisiert wurde und der Sack nicht eingesammelt wurde
	if is_position_initialized and not is_collected:
		animate(delta)

# Funktion zum Wechseln zu StaticBody2D
func change_to_static_body():
	# Area2D-Komponenten deaktivieren
	monitoring = false
	monitorable = false
	
	# CollisionShape2D unsichtbar machen, falls vorhanden
	if has_node("CollisionShape2D"):
		get_node("CollisionShape2D").disabled = true
	
	# StaticBody aktivieren
	if has_node("StaticBody"):
		var static_body = get_node("StaticBody")
		static_body.visible = true
		static_body.process_mode = PROCESS_MODE_INHERIT
		
		# Kollisionslayer für StaticBody setzen
		static_body.collision_layer = 4  # Anpassen an deine Kollisionslayer
		static_body.collision_mask = 0   # Keine Kollisionen erkennen

# Funktion zum Wechseln zu Area2D
func change_to_area2d():
	# StaticBody deaktivieren
	if has_node("StaticBody"):
		var static_body = get_node("StaticBody")
		static_body.visible = false
		static_body.process_mode = PROCESS_MODE_DISABLED
		
	# Area2D-Komponenten aktivieren
	monitoring = true
	monitorable = true
	
	# CollisionShape2D sichtbar machen, falls vorhanden
	if has_node("CollisionShape2D"):
		get_node("CollisionShape2D").disabled = false

func animate(delta):
	animation_time += delta
	# Bounce-Animation
	var bounce_offset = sin(animation_time * bounce_speed) * bounce_height
	global_position.y = spawn_position.y + bounce_offset
	
func _on_sack_of_gold_body_entered(body):
	if (body.is_in_group("player") or body.name == "Player") and not is_collected:
		collect_sack_of_gold(body)

func collect_sack_of_gold(player):
	# Markieren als eingesammelt, um mehrfaches Einsammeln zu verhindern
	is_collected = true
	GlobalHUD.set_coins(GlobalHUD.coins + 100)
	# Kollision deaktivieren
	set_collision_mask_value(1, false)
	
	# Den Sack vom aktuellen Parent entfernen
	var current_parent = get_parent()
	if current_parent:
		current_parent.remove_child(self)
	
	# Den Sack zum Player hinzufügen
	player.add_child(self)
	
	# Die Position innerhalb des Players anpassen
	# Direkt hinter dem Spieler platzieren
	position = Vector2(0, 0)  # Gleiche Position wie Spieler
	
	# Z-Index niedriger setzen, damit der Sack hinter dem Spieler erscheint
	z_index = -1
	
	# Area2D deaktivieren und StaticBody aktivieren
	change_to_static_body()
	
	# Signal senden
	emit_signal("sack_of_gold_collected", self, player)
	
	
# Funktion zum Ablegen des Goldsacks
func drop_sack(drop_position: Vector2 = Vector2.ZERO, target_parent: Node = null):
	# Überprüfen ob der Sack eingesammelt wurde
	if not is_collected:
		return
	GlobalHUD.set_coins(GlobalHUD.coins -100)
	# Den Spieler (aktuellen Elternknoten) referenzieren
	var player = get_parent()
	if not player:
		return
	
	# StaticBody deaktivieren und Area2D aktivieren
	change_to_area2d()
	
	# Den Sack vom Player entfernen
	player.remove_child(self)
	
	# Den Sack zum angegebenen Ziel-Parent hinzufügen oder versuchen, die Szene zu finden
	if target_parent:
		# Den angegebenen Parent verwenden
		target_parent.add_child(self)
	else:
		# Versuche, das Level zu finden (entweder über den Spieler oder SceneTree)
		var parent_to_use = null
		
		# Option 1: Versuche, den Spieler-Parent zu verwenden (das Level)
		if player and player.get_parent():
			parent_to_use = player.get_parent()
		# Option 2: Versuche, über Szenenbaum zu gehen
		elif get_tree() and get_tree().current_scene:
			parent_to_use = get_tree().current_scene
		# Option 3: Fallback zur Wurzel
		elif get_tree():
			parent_to_use = get_tree().root
		
		# Wenn wir einen gültigen Parent gefunden haben, füge den Sack hinzu
		if parent_to_use:
			parent_to_use.add_child(self)
		else:
			# Wenn wir keinen Parent finden können, gib eine Fehlermeldung aus
			print("Konnte keinen gültigen Parent für den Goldsack finden!")
			return
	
	# Position festlegen
	if drop_position != Vector2.ZERO:
		# Wenn eine spezifische Position angegeben wurde
		global_position = drop_position
	else:
		# Ansonsten vor dem Spieler ablegen
		global_position = player.global_position + Vector2(0, 50)
	
	# Kollision wieder aktivieren
	set_collision_mask_value(1, true)
	
	# Als nicht eingesammelt markieren
	is_collected = false
	
	# Animations-Startposition aktualisieren
	spawn_position = global_position
	
	# Signal senden
	emit_signal("sack_of_gold_dropped", self, global_position)
