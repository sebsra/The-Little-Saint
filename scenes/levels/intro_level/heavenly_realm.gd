extends Node2D

func _ready():
	Global.current_coin_type = Global.CoinType.NORMAL
	$HUD.transition_to_heavenly_coins()
	#GlobalHUD.add_message("Test MessageMessageMessageMessageMessageMessageMessageMessage", 10)
