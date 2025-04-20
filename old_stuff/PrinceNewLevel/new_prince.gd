class_name NewPrince
extends Node2D

var boss_music = load("res://assets/audio/music/Tracks/the-epic-2-by-rafael-krux(chosic.com).mp3")
# Called when the node enters the scene tree for the first time.
func _ready():
	AudioManager.play_track(boss_music)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
