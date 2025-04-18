class_name PositioningState
extends ArcherState

## Spezieller State für Bogenschützen, der sie in optimaler Schussdistanz positioniert
## Ersetzt den generischen ChaseState für bessere Fernkampftaktiken

# Diese Werte werden nun vom GoblinArcher überschrieben
var optimal_distance: float = 150.0
var positioning_timeout: float = 3.0  # Maximale Zeit für Positionierung
var movement_pause_duration: float = 0.5  # Kurze Pausen während der Positionierung

var position_timer: float = 0.0
var movement_pause_timer: float = 0.0

func _init():
	name = "Positioning"

func enter():
	super.enter()
	play_animation("walk")
	position_timer = 0.0
	movement_pause_timer = 0.0
	
	# Werte vom Archer einlesen, falls nicht bereits gesetzt
	var archer = enemy as GoblinArcher
	if archer:
		if archer.optimal_distance > 0:
			optimal_distance = archer.optimal_distance
		if archer.positioning_timeout > 0:
			positioning_timeout = archer.positioning_timeout
		if archer.movement_pause_duration > 0:
			movement_pause_duration = archer.movement_pause_duration
	
	print(enemy.name + " entered positioning state with optimal_distance=" + str(optimal_distance) + 
		  ", timeout=" + str(positioning_timeout) + ", pause_duration=" + str(movement_pause_duration))

func physics_process(delta: float):
	position_timer += delta
	
	# Ziel aktualisieren
	update_target()
	
	if not target:
		enemy.velocity.x = 0
		return
	
	# Abstand zum Ziel berechnen
	var distance = get_distance_to_target()
	
	# Optimale Positionierung: Gelegentliche Pausen für realistischeres Verhalten
	movement_pause_timer -= delta
	if movement_pause_timer <= 0:
		var direction = target.global_position.x - enemy.global_position.x
		var normalized_dir = sign(direction)
		
		# Positionierungslogik
		if distance < optimal_distance * 0.8:  # Zu nah
			enemy.velocity.x = -normalized_dir * enemy.speed  # Wegbewegen
		elif distance > optimal_distance * 1.2:  # Zu weit
			enemy.velocity.x = normalized_dir * enemy.speed  # Annähern
		else:
			# Im optimalen Bereich - anhalten und ausrichten
			enemy.velocity.x = 0
			movement_pause_timer = movement_pause_duration  # Kurze Pause
		
		# Zum Ziel drehen, egal in welche Richtung wir uns bewegen
		if enemy.animated_sprite:
			enemy.animated_sprite.flip_h = direction > 0
	else:
		# Während der Pause nicht bewegen, aber zum Ziel ausrichten
		enemy.velocity.x = 0
		if enemy.animated_sprite and target:
			var direction = target.global_position.x - enemy.global_position.x
			enemy.animated_sprite.flip_h = direction > 0

func get_next_state() -> String:
	var next = super.get_next_state()
	if next:
		return next
		
	# Kein Ziel - zurück zur Patrouille
	if not target:
		return "Patrol"
	
	var archer = enemy as GoblinArcher
	if not archer:
		return "Patrol"
	
	# Schießen, wenn gute Position erreicht und Pfeile vorhanden
	var distance = get_distance_to_target()
	if distance >= optimal_distance * 0.8 and distance <= optimal_distance * 1.2:
		if archer.arrows_remaining > 0:
			return "Shoot"
	
	# Wenn zu nah am Spieler, zurückziehen
	if distance < optimal_distance * 0.5:
		return "Retreat"
	
	# Timeout für die Positionierung
	if position_timer > positioning_timeout:
		# Nach Timeout versuchen zu schießen, auch wenn nicht perfekt positioniert
		if archer.arrows_remaining > 0:
			return "Shoot"
	
	return ""
