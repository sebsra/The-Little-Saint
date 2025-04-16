class_name Heaven_Coins
extends Area2D

signal heaven_coin_collected


func _on_animation_player_animation_finished(anim_name):
	queue_free()


func _on_heaven_coins_body_entered(body):
	GlobalHUD.heaven_coin_collected()
	$AnimationPlayer.play("bounce")
	set_collision_mask_value(1,false)
