extends Node


var music_playing = false
var current_track: AudioStream = null


func _ready():
	var audio_player = $AudioStreamPlayer
	if !music_playing:
		audio_player.stream = load("res://Ressources/Audio/Tracks/the-epic-2-by-rafael-krux(chosic.com).mp3")
		audio_player.play()
		music_playing = true
	else:
		audio_player.play()
		
func play_track(audio_stream: AudioStream):
	var audio_player = $AudioStreamPlayer
	if audio_stream != current_track:
		audio_player.stop()
		audio_player.stream = audio_stream
		audio_player.play()
		current_track = audio_stream
		music_playing = true
	elif not audio_player.playing:
		audio_player.play()
