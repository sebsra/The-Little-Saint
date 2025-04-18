class_name MagePositioningState
extends MageState

## Spezieller State für Magier, der sie in optimaler Zauber-Distanz positioniert
## Ersetzt den generischen ChaseState für bessere Fernkampftaktiken

# Diese Werte werden nun vom GoblinMage überschrieben
var optimal_distance: float = 180.0  # Magier bevorzugen größere Distanz als Bogenschützen
var positioning_timeout: float = 3.0  # Maximale Zeit für Positionierung
var movement_pause_duration: float = 0.7  # Längere Pausen für Magier (bedächtiger)

var position_timer: float = 0.0
var movement_pause_timer: float = 0.0
var low_mana_threshold: float = 0.3  # Schwellwert für niedrigen Manavorrat (30%)

func _init():
	name = "MagePositioning"

func enter():
	super.enter()
	play_animation("walk")
	position_timer = 0.0
	movement_pause_timer = 0.0
	
	# Werte vom Magier einlesen, falls nicht bereits gesetzt
	var mage = enemy as GoblinMage
	if mage:
		if mage.optimal_distance > 0:
			optimal_distance = mage.optimal_distance
		if mage.positioning_timeout > 0:
			positioning_timeout = mage.positioning_timeout
		if mage.movement_pause_duration > 0:
			movement_pause_duration = mage.movement_pause_duration
	
	print(enemy.name + " entered mage positioning state with optimal_distance=" + 
		  str(optimal_distance) + ", timeout=" + str(positioning_timeout))

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
		
		# Mage hat andere Positionierungslogik als Archer
		var mage = enemy as GoblinMage
		var mana_ratio = 1.0  # Standardwert
		if mage:
			mana_ratio = mage.current_mana / mage.max_mana
		
		# Positionierungslogik basierend auf Mana und Distanz
		if mana_ratio < low_mana_threshold:
			# Bei niedrigem Mana größeren Abstand halten
			if distance < optimal_distance * 1.2:
				enemy.velocity.x = -normalized_dir * enemy.speed  # Mehr Abstand gewinnen
			else:
				enemy.velocity.x = 0
				movement_pause_timer = movement_pause_duration
		else:
			# Normale Positionierung
			if distance < optimal_distance * 0.7:  # Zu nah
				enemy.velocity.x = -normalized_dir * enemy.speed  # Wegbewegen
			elif distance > optimal_distance * 1.3:  # Zu weit
				enemy.velocity.x = normalized_dir * enemy.speed  # Annähern
			else:
				# Im optimalen Bereich - anhalten und ausrichten
				enemy.velocity.x = 0
				movement_pause_timer = movement_pause_duration
		
		# Zum Ziel drehen, unabhängig von der Bewegungsrichtung
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
	
	var mage = enemy as GoblinMage
	if not mage:
		return "Patrol"
	
	# Notfall-Teleport wenn zu nah und Mana verfügbar
	var distance = get_distance_to_target()
	if distance < 70 and mage.current_mana >= mage.teleport_mana_cost and mage.last_teleport_time <= 0:
		return "Teleport"
	
	# Schild aktivieren wenn zu nah und kein Teleport möglich
	if distance < 80 and mage.current_mana >= mage.shield_mana_cost and not mage.is_shielding:
		if mage.current_mana < mage.teleport_mana_cost or mage.last_teleport_time > 0:
			return "Shield"
	
	# Zauber, wenn gute Position erreicht und genug Mana
	if distance >= optimal_distance * 0.7 and distance <= optimal_distance * 1.5:
		if mage.current_mana >= mage.spell_mana_cost:
			return "Cast"
	
	# Timeout für die Positionierung
	if position_timer > positioning_timeout:
		# Nach Timeout versuchen zu zaubern, auch wenn nicht perfekt positioniert
		if mage.current_mana >= mage.spell_mana_cost:
			return "Cast"
	
	return ""
