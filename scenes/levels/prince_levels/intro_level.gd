extends Node2D

func _ready() -> void:
	# Verbinde mit dem player_died Signal aus dem Global Autoload in Godot 4.4 Syntax
	Global.player_died.connect(_on_player_died)

# Diese Funktion wird aufgerufen, wenn die set_back_zone betreten wird
func _on_set_back_zone_body_entered(body: Node2D) -> void:
	$Player.position = Vector2(100, -100)  # Replace with your desired coordinates
	GlobalHUD.change_life(-1)


# Diese Funktion wird aufgerufen, wenn das player_died Signal emittiert wird
func _on_player_died() -> void:
	$Player.state_machine.change_state("PlayerDeathState")
	await get_tree().create_timer(3.0).timeout
	$Player.position = Vector2(100, -100)
	$Player.state_machine.change_state("PlayerIdleState")
	GlobalHUD.reset_to_defaults()
	

func _on_water_body_entered(body):
	if body.name == "Player" or body.is_in_group("Player"):
		body.state_machine.change_state("PlayerSwimState")
	if body.is_in_group("enemy"):
		body.take_damage(1000.0)
		GlobalHUD.add_message("Ein Feind wurde im Wasser begraben")


func _on_water_body_exited(body):
	if body.name == "Player" or body.is_in_group("Player"):
		body.state_machine.change_state("PlayerIdleState")
