extends Node

@export var autoplay: bool = false
@export var default_stream: AudioStream = null

var audio_player: AudioStreamPlayer
var current_track: AudioStream = null

func _ready():
	# Initialize the AudioStreamPlayer
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "AudioStreamPlayer"
	add_child(audio_player)
	
	# Connect the finished signal to handle when music ends
	audio_player.finished.connect(_on_audio_finished)
	
	# Autoplay if enabled
	if autoplay and default_stream:
		play_track(default_stream)

func play_track(audio_stream: AudioStream):
	if audio_stream != current_track:
		audio_player.stop()
		audio_player.stream = audio_stream
		audio_player.play()
		current_track = audio_stream
	elif not audio_player.playing:
		audio_player.play()

func stop_track():
	audio_player.stop()

func is_playing() -> bool:
	return audio_player.playing

func _on_audio_finished():
	current_track = null  # Reset track when finished
