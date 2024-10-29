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

func coin_collected():
	coins = coins + 1
	$LabelCoinSum.text = str(coins)
	

func load_hearts():
	$HeartsFull.size.x = lifes * inital_heart_size.x
	$HeartsFull.position.x= initial_heart_position.x - ((lifes-1) * inital_heart_size.x)

func change_life(amount):
	if  lifes + amount < 0:
		lifes = 0
		
	elif  lifes + amount > 3:
		lifes = 3
	else:
		lifes = lifes + amount
	load_hearts()
