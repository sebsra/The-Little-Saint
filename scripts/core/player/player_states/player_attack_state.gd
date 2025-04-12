class_name PlayerAttackState
extends PlayerState

var attack_timer: float = 0.0
var attack_duration: float = 0.5  # Dauer der Angriffsanimation
var has_checked_for_enemies: bool = false

func enter():
	player.current_animation = player.attack_animation
	player.play_attack_animation = true
	attack_timer = 0.0
	has_checked_for_enemies = false
	
	# Attacke-Sound abspielen, falls vorhanden
	if player.has_node("AttackSound"):
		player.get_node("AttackSound").play()

func physics_process(delta: float):
	# Nur einmal pro Angriff nach Feinden suchen
	if not has_checked_for_enemies:
		_check_for_enemies()
		has_checked_for_enemies = true
	
	# Schwerkraft anwenden
	var velocity = get_velocity()
	velocity.y += player.GRAVITY * delta
	
	# Bewegung während des Angriffs reduzieren
	velocity.x = move_toward(velocity.x, 0, 20)
	
	set_velocity(velocity)
	player.move_and_slide()
	
	# Timer aktualisieren
	attack_timer += delta
	
	# Outfit aktualisieren
	update_outfit()

func _check_for_enemies():
	# Direkt um den Spieler herum nach Feinden suchen
	var player_pos = player.global_position
	
	# Blickrichtung des Spielers ermitteln
	var player_facing_right = player.get_node("character_sprites/bodies").flip_h
	
	# Alle Gegner in der Szene durchgehen
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		# Abstand zum Feind prüfen (einfache Entfernungsprüfung)
		var distance = player_pos.distance_to(enemy.global_position)
		if distance <= 60.0:  # 60 Pixel Reichweite
			# Prüfen, ob Spieler zum Feind schaut
			var enemy_is_right = enemy.global_position.x > player_pos.x
			
			# Wenn Spieler in die richtige Richtung schaut und nah genug ist
			if (player_facing_right and enemy_is_right) or (not player_facing_right and not enemy_is_right):
				# Feind töten
				if enemy.has_method("take_damage"):
					enemy.take_damage(enemy.current_health) # Sofortiger Tod
					print("Enemy killed: ", enemy.name)

func get_next_state() -> String:
	# State-Übergänge prüfen
	var life_state = check_life()
	if life_state:
		return life_state
	
	# Nach Ende der Animation zum passenden State zurückkehren
	if attack_timer >= attack_duration:
		player.play_attack_animation = false
		
		if player.is_on_floor():
			var x_input = Input.get_axis("left", "right")
			if x_input != 0:
				return "PlayerWalkState"
			else:
				return "PlayerIdleState"
		else:
			return "PlayerFallState"
	
	# Im Angriffszustand bleiben
	return ""
	
func handle_input(event: InputEvent):
	check_menu_input(event)
