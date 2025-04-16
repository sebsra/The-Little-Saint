class_name PlayerSwimState
extends PlayerState

func enter():
	player.current_animation = "idle"  # Idle-Animation wie angefordert
	
	# Spieler horizontal ausrichten, indem der character_sprites-Knoten rotiert wird
	player.get_node("character_sprites").rotation_degrees = 90
	
	if player.debug_mode:
		print("Entered Swim State")

func physics_process(delta: float):
	# Reduzierte Schwerkraft (Auftrieb im Wasser)
	var velocity = get_velocity()
	velocity.y += (player.GRAVITY * 0.3) * delta  # Reduzierte Schwerkraft im Wasser
	
	# Eingaben lesen
	var x_input = Input.get_axis("left", "right")
	var y_input = Input.get_axis("down", "up")
	
	# Horizontale Bewegung (links/rechts)
	if x_input != 0:
		velocity.x = x_input * (player.SPEED * 0.7)  # Reduzierte Geschwindigkeit wegen Wasserwiderstand
	else:
		velocity.x = move_toward(velocity.x, 0, 15)  # Langsamere Abbremsung
	
	# Vertikale Bewegung (hoch/runter) - Schwimmen erlaubt vertikale Kontrolle
	if y_input != 0:
		velocity.y = -y_input * (player.SPEED * 0.7)  # Vorzeichen umgekehrt, damit nach oben = aufwärts
	else:
		velocity.y = move_toward(velocity.y, 0, 15)  # Langsamere vertikale Abbremsung
		
	set_velocity(velocity)
	
	# Bewegung für character body verarbeiten
	player.move_and_slide()
	
	# Outfit aktualisieren
	update_outfit()

func get_next_state() -> String:
	# Prüfe Lebensstatus
	var life_state = check_life()
	if life_state != "":
		return life_state
	
	# Hinweis: Der Schwimmzustand kann nur von außen beendet werden
	# Dies geschieht normalerweise durch eine Kollisionserkennung oder
	# eine spezielle Wasserzone, die in der Player-Klasse oder einer 
	# übergeordneten Klasse implementiert werden muss.
	# 
	# Beispiel für eine mögliche Implementierung in der Player-Klasse:
	# func _physics_process(delta):
	#     if current_state is PlayerSwimState and not in_water_area:
	#         change_state("PlayerFallState")
	
	# Im Schwimmzustand bleiben
	return ""
	
func handle_input(event: InputEvent):
	check_menu_input(event)

func exit():
	# Rotation zurücksetzen, wenn der Zustand verlassen wird
	player.get_node("character_sprites").rotation_degrees = 0
