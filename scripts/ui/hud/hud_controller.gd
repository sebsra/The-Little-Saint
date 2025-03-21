extends CanvasLayer

var coins := 0
var max_lifes := 3
var lifes := max_lifes

# Elixir fill (0.0 = empty, 1.0 = full)
var elixir_fill_level := 0.0

func _ready():
	# Example: align hearts and coins (already in your code)
	$HeartsFull.flip_h = true
	$LabelCoinSum.text = str(coins)
	load_hearts()
	
	# Initialize the elixir with empty fill
	set_elixir_fill(elixir_fill_level)

func update_elixir_fill(fill_amount: float):
	var new_fill_level = min(1.0, max(elixir_fill_level + fill_amount, 0))
	set_elixir_fill(new_fill_level)

func set_elixir_fill(fill_level: float):
	elixir_fill_level = clamp(fill_level, 0.0, 1.0)
	var elixir = $elixir
	var bottle = $bottle
	
	# Because we are using a scaled Sprite, region clipping is in unscaled texture coordinates.
	elixir.region_enabled = true
	
	# Unscaled texture size
	var tex_size = elixir.texture.get_size()
	
	# Fill height in unscaled pixels
	var visible_height = tex_size.y * elixir_fill_level
	
	# Clip from the top: region_rect starts at (0, tex_size.y - visible_height)
	elixir.region_rect = Rect2(
		Vector2(0, tex_size.y - visible_height),
		Vector2(tex_size.x, visible_height)
	)
	
	var bottle_texture_size = bottle.texture.get_size()
	var elixir_texture_size = elixir.texture.get_size()
	
	var bottle_scale = bottle.scale
	var elixir_scale = elixir.scale
	
	var bottle_size = bottle_texture_size.y * bottle_scale.y
	var elixir_size = visible_height * elixir_scale.y
	
	
	elixir.position.x = bottle.position.x
	elixir.position.y = bottle.position.y + ( (bottle_size - elixir_size) / 2) 
	


# Everything else is just your standard code for coins/life/etc.
func coin_collected():
	coins += 1
	$LabelCoinSum.text = str(coins)
	Global.collect_coin()
	update_coin_display()

func update_coin_display():
	$LabelCoinSum.text = str(coins)

func load_hearts():
	$HeartsFull.size.x = lifes * $HeartsFull.size.x / max_lifes

func change_life(amount):
	lifes = clamp(lifes + amount, 0, max_lifes)
	if lifes <= 0:
		Global.player_death()
	load_hearts()

func collect_softpower():
	update_elixir_fill(0.25)

func use_softpower():
	update_elixir_fill(-0.25)
