class_name Coins
extends Area2D

signal coin_collected



func _on_coins_body_entered(body):
	get_parent().get_node("HUD").coin_collected()
	$AnimationPlayer.play("bounce")
	set_collision_mask_value(1,false)


func _on_animation_player_animation_finished(anim_name):
	queue_free()
