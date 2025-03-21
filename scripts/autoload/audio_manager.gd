extends Node

## Enhanced Audio Manager for managing all game audio
## Supports categories, multiple channels, and persistent settings

# Audio bus names
const MASTER_BUS = "Master"
const MUSIC_BUS = "Music"
const SFX_BUS = "SFX"
const UI_BUS = "UI"
const VOICE_BUS = "Voice"

# Volume ranges
const MIN_VOLUME_DB = -80.0
const MAX_VOLUME_DB = 6.0

# Fade durations
const DEFAULT_FADE_DURATION = 1.0

# Music properties
@export var autoplay: bool = false
@export var default_music_stream: AudioStream = null
@export var default_music_volume: float = 0.0  # in dB
@export var crossfade_duration: float = 1.0

# Current audio tracks
var current_music_track: AudioStream = null
var current_music_player: AudioStreamPlayer = null
var next_music_player: AudioStreamPlayer = null  # For crossfading

# Audio player pools
var music_players = []
var sfx_players = {}
var ui_players = []
var voice_players = []

# Audio stream cache
var stream_cache = {}

# Signals
signal music_started(track_name)
signal music_stopped()
signal music_finished()
signal music_faded(from_volume, to_volume)
signal sfx_played(sfx_name)

func _ready():
	# Ensure we have all the audio buses we need
	_setup_audio_buses()
	
	# Create initial audio players
	_setup_audio_players()
	
	# Load settings
	_load_audio_settings()
	
	# Autoplay if enabled
	if autoplay and default_music_stream:
		play_music(default_music_stream)

func _setup_audio_buses():
	# Create buses if they don't exist
	var bus_names = [MASTER_BUS, MUSIC_BUS, SFX_BUS, UI_BUS, VOICE_BUS]
	
	for i in range(AudioServer.get_bus_count()):
		var bus_name = AudioServer.get_bus_name(i)
		bus_names.erase(bus_name)
	
	# Add any missing buses
	for bus_name in bus_names:
		if bus_name != MASTER_BUS:  # Master is always bus 0
			var idx = AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			
			# Connect to Master
			AudioServer.set_bus_send(idx, MASTER_BUS)

func _setup_audio_players():
	# Create music players for crossfading
	for i in range(2):
		var player = AudioStreamPlayer.new()
		player.name = "MusicPlayer_" + str(i)
		player.bus = MUSIC_BUS
		player.volume_db = default_music_volume
		add_child(player)
		music_players.append(player)
		player.finished.connect(_on_music_finished.bind(player))
	
	# Set current music player
	current_music_player = music_players[0]

# Music playback control
func play_music(stream: AudioStream, fade_in: float = DEFAULT_FADE_DURATION, volume_db: float = default_music_volume, loop: bool = true):
	if not stream:
		push_error("Cannot play null music stream")
		return
	
	# Check if this is the current track
	if current_music_track == stream and current_music_player.playing:
		return
	
	# Choose which player to use
	var player
	if current_music_player and current_music_player.playing:
		# Crossfade
		player = _get_unused_music_player()
		next_music_player = player
	else:
		# No crossfade needed
		player = current_music_player if current_music_player else music_players[0]
	
	# Set up the player
	player.stream = stream
	player.volume_db = MIN_VOLUME_DB if fade_in > 0 else volume_db
	player.play()
	
	# Apply loop setting
	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.loop = loop
	
	# Store current track
	current_music_track = stream
	
	# Handle fade in if needed
	if fade_in > 0:
		var tween = create_tween()
		tween.tween_property(player, "volume_db", volume_db, fade_in)
		
		# If we're crossfading, fade out the old track
		if current_music_player and current_music_player != player and current_music_player.playing:
			var fade_out_tween = create_tween()
			fade_out_tween.tween_property(current_music_player, "volume_db", MIN_VOLUME_DB, fade_in)
			fade_out_tween.tween_callback(func(): current_music_player.stop())
	
	# Update current player reference
	current_music_player = player
	
	var track_name = stream.resource_path.get_file()
	emit_signal("music_started", track_name)

func stop_music(fade_out: float = DEFAULT_FADE_DURATION):
	if not current_music_player or not current_music_player.playing:
		return
	
	if fade_out > 0:
		var tween = create_tween()
		tween.tween_property(current_music_player, "volume_db", MIN_VOLUME_DB, fade_out)
		tween.tween_callback(func(): 
			current_music_player.stop()
			current_music_track = null
			emit_signal("music_stopped")
		)
	else:
		current_music_player.stop()
		current_music_track = null
		emit_signal("music_stopped")

func pause_music():
	if current_music_player and current_music_player.playing:
		current_music_player.stream_paused = true

func resume_music():
	if current_music_player and current_music_player.stream_paused:
		current_music_player.stream_paused = false

func is_music_playing() -> bool:
	return current_music_player != null and current_music_player.playing

func fade_music(to_volume_db: float, duration: float = DEFAULT_FADE_DURATION):
	if not current_music_player or not current_music_player.playing:
		return
	
	var from_volume = current_music_player.volume_db
	
	var tween = create_tween()
	tween.tween_property(current_music_player, "volume_db", to_volume_db, duration)
	tween.tween_callback(func(): emit_signal("music_faded", from_volume, to_volume_db))

# SFX playback
func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0, bus: String = SFX_BUS) -> AudioStreamPlayer:
	if not stream:
		push_error("Cannot play null SFX stream")
		return null
	
	# Get or create an available SFX player
	var sfx_player = _get_available_sfx_player(bus)
	
	# Set up the player
	sfx_player.stream = stream
	sfx_player.volume_db = volume_db
	sfx_player.pitch_scale = pitch_scale
	sfx_player.play()
	
	var sfx_name = stream.resource_path.get_file()
	emit_signal("sfx_played", sfx_name)
	
	return sfx_player

func play_sfx_at_position(stream: AudioStream, position: Vector2, volume_db: float = 0.0, 
						pitch_scale: float = 1.0, bus: String = SFX_BUS, 
						falloff: float = 1.0, max_distance: float = 2000) -> AudioStreamPlayer2D:
	if not stream:
		push_error("Cannot play positional SFX with null stream")
		return null
	
	# Create a temporary 2D audio player
	var sfx_player = AudioStreamPlayer2D.new()
	sfx_player.name = "TempSFX2D_" + str(randi())
	sfx_player.stream = stream
	sfx_player.volume_db = volume_db
	sfx_player.pitch_scale = pitch_scale
	sfx_player.bus = bus
	sfx_player.position = position
	sfx_player.max_distance = max_distance
	sfx_player.attenuation = falloff
	
	# Add to tree temporarily
	add_child(sfx_player)
	sfx_player.play()
	
	# Connect to finished to auto-remove
	sfx_player.finished.connect(func(): sfx_player.queue_free())
	
	var sfx_name = stream.resource_path.get_file()
	emit_signal("sfx_played", sfx_name)
	
	return sfx_player

func play_ui_sound(stream: AudioStream, volume_db: float = 0.0) -> AudioStreamPlayer:
	return play_sfx(stream, volume_db, 1.0, UI_BUS)

func play_voice(stream: AudioStream, volume_db: float = 0.0) -> AudioStreamPlayer:
	return play_sfx(stream, volume_db, 1.0, VOICE_BUS)

# Volume control
func set_volume(bus_name: String, volume_db: float) -> bool:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		push_error("Audio bus not found: " + bus_name)
		return false
	
	var clamped_volume = clamp(volume_db, MIN_VOLUME_DB, MAX_VOLUME_DB)
	AudioServer.set_bus_volume_db(bus_idx, clamped_volume)
	return true

func get_volume(bus_name: String) -> float:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		push_error("Audio bus not found: " + bus_name)
		return 0.0
	
	return AudioServer.get_bus_volume_db(bus_idx)

func set_mute(bus_name: String, mute: bool) -> bool:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		push_error("Audio bus not found: " + bus_name)
		return false
	
	AudioServer.set_bus_mute(bus_idx, mute)
	return true

func is_muted(bus_name: String) -> bool:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		push_error("Audio bus not found: " + bus_name)
		return false
	
	return AudioServer.is_bus_mute(bus_idx)

# Stream loading helper
func load_stream(path: String) -> AudioStream:
	# Check cache first
	if stream_cache.has(path):
		return stream_cache[path]
	
	# Load the stream
	var stream = load(path)
	if stream is AudioStream:
		stream_cache[path] = stream
		return stream
	
	push_error("Failed to load audio stream: " + path)
	return null

# Preload a collection of audio streams
func preload_streams(paths: Array) -> void:
	for path in paths:
		load_stream(path)

# Save and load audio settings
func save_audio_settings() -> bool:
	var config = ConfigFile.new()
	
	# Save volumes
	for bus_name in [MASTER_BUS, MUSIC_BUS, SFX_BUS, UI_BUS, VOICE_BUS]:
		var bus_idx = AudioServer.get_bus_index(bus_name)
		if bus_idx >= 0:
			config.set_value("volume", bus_name, AudioServer.get_bus_volume_db(bus_idx))
			config.set_value("mute", bus_name, AudioServer.is_bus_mute(bus_idx))
	
	# Save the config
	var err = config.save("user://audio_settings.cfg")
	return err == OK

func _load_audio_settings() -> bool:
	var config = ConfigFile.new()
	var err = config.load("user://audio_settings.cfg")
	
	if err != OK:
		# Create default settings
		for bus_name in [MASTER_BUS, MUSIC_BUS, SFX_BUS, UI_BUS, VOICE_BUS]:
			set_volume(bus_name, 0.0)
			set_mute(bus_name, false)
		return false
	
	# Load volumes
	for bus_name in [MASTER_BUS, MUSIC_BUS, SFX_BUS, UI_BUS, VOICE_BUS]:
		var volume = config.get_value("volume", bus_name, 0.0)
		var muted = config.get_value("mute", bus_name, false)
		
		set_volume(bus_name, volume)
		set_mute(bus_name, muted)
	
	return true

# Private utility functions
func _get_unused_music_player() -> AudioStreamPlayer:
	for player in music_players:
		if player != current_music_player or not player.playing:
			return player
	
	# All players are in use, create a new one
	var player = AudioStreamPlayer.new()
	player.name = "MusicPlayer_" + str(music_players.size())
	player.bus = MUSIC_BUS
	add_child(player)
	music_players.append(player)
	player.finished.connect(_on_music_finished.bind(player))
	
	return player

func _get_available_sfx_player(bus: String = SFX_BUS) -> AudioStreamPlayer:
	# Check for existing player in the bus category
	if not sfx_players.has(bus):
		sfx_players[bus] = []
	
	var bus_players = sfx_players[bus]
	
	# Look for an available player
	for player in bus_players:
		if not player.playing:
			return player
	
	# Create a new player
	var player = AudioStreamPlayer.new()
	player.name = "SFXPlayer_" + bus + "_" + str(bus_players.size())
	player.bus = bus
	add_child(player)
	bus_players.append(player)
	
	return player

func _on_music_finished(player):
	if player == current_music_player:
		emit_signal("music_finished")
		
		# Check if we have a looping track
		if current_music_track:
			var is_looping = false
			if current_music_track is AudioStreamMP3 or current_music_track is AudioStreamOggVorbis:
				is_looping = current_music_track.loop
			
			if is_looping:
				# Restart the track
				player.play()

# Legacy API for backward compatibility
func play_track(audio_stream: AudioStream):
	play_music(audio_stream)

func stop_track():
	stop_music()

func is_playing() -> bool:
	return is_music_playing()
