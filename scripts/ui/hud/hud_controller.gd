class_name HudController
extends CanvasLayer
var coins = 0
var max_lifes = 3
var lifes = max_lifes
var hud
var initial_heart_position
var inital_heart_size

func _ready():
	$HeartsFull.flip_h = true
	$LabelCoinSum.text = str(coins)
	initial_heart_position = $HeartsFull.position
	inital_heart_size = $HeartsFull.size
	$HeartsEmpty.position = initial_heart_position - Vector2(2*inital_heart_size.x, 0)
	$HeartsEmpty.size = inital_heart_size + Vector2(2*inital_heart_size.x, 0)

	load_hearts()
	
	# Notify GameManager when coins are collected
	get_tree().create_timer(0.1).timeout.connect(func():
		Global.collected_coins = coins
	)

func coin_collected():
	coins = coins + 1
	$LabelCoinSum.text = str(coins)
	
	# Notify GameManager
	Global.collect_coin()
	_update_coin_display()

# Function to update coin display
func _update_coin_display():
	$LabelCoinSum.text = str(coins)

func load_hearts():
	$HeartsFull.size.x = lifes * inital_heart_size.x
	$HeartsFull.position.x= initial_heart_position.x - ((lifes-1) * inital_heart_size.x)

func change_life(amount):
	if lifes + amount < 0:
		lifes = 0
		
		# Notify GameManager of player death if health reaches 0
		if lifes <= 0:
			Global.player_death()
	elif lifes + amount > max_lifes:
		lifes = max_lifes
	else:
		lifes = lifes + amount
	
	load_hearts()
	
	# Update SaveManager with new health value
	if SaveManager.current_save_data:
		SaveManager.current_save_data.health = lifes
