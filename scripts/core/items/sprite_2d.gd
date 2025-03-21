extends Sprite2D

@export var empty_texture: Texture
@export var full_texture: Texture

@export var hud: Node  # Referenz auf den HUD-Controller

var is_full = false
var elixir_fill = 0.0  # Aktueller Füllstand (0.0 = leer, 1.0 = voll)

func _ready():
	# Stellt sicher, dass das Elixir-UI korrekt geladen ist
	if not hud:
		hud = get_node_or_null("/root/MainScene/HUD")  # Pfad anpassen, falls nötig

func _on_body_entered(body):
	# Wenn der Spieler das Elixir einsammelt
	if body.is_in_group("player"):
		increase_elixir(0.25)  # 25% auffüllen
		queue_free()  # Entferne das Elixir aus der Welt

func increase_elixir(amount: float):
	# Füllstand um "amount" erhöhen (maximal 1.0)
	elixir_fill = clamp(elixir_fill + amount, 0.0, 1.0)
	
	# Aktualisiere das UI-Elixir
	if hud and hud.has_method("update_elixir_fill"):
		hud.update_elixir_fill(elixir_fill)

	# Falls das Elixir-UI voll ist, setze das Icon auf "full_texture"
	if elixir_fill >= 1.0:
		is_full = true
		texture = full_texture

func decrease_elixir(amount: float):
	# Füllstand um "amount" verringern (minimal 0.0)
	elixir_fill = clamp(elixir_fill - amount, 0.0, 1.0)
	
	# Aktualisiere das UI-Elixir
	if hud and hud.has_method("update_elixir_fill"):
		hud.update_elixir_fill(elixir_fill)

	# Falls das Elixir-UI leer ist, setze das Icon auf "empty_texture"
	if elixir_fill <= 0.0:
		is_full = false
		texture = empty_texture
