### GLOBAL PRELOAD - SceneManager
extends Node

var transition_time: float = 0.5

var music_player: AudioStreamPlayer
var default_volume

@onready var master_bus = AudioServer.get_bus_index("Master")
@onready var music_bus = AudioServer.get_bus_index("Music")
@onready var sfx_bus = AudioServer.get_bus_index("SFX")
@onready var music := preload("res://audio/Late Night Radio.mp3")

func _ready():
	AudioServer.set_bus_layout(load("res://audio/default_bus_layout.tres"))
	play_music(music)

## will use this for main menu i guess? could be useful in the future
# Add effects (example: low-pass filter on music)
#var eq = AudioEffectEQ.new()
#AudioServer.add_bus_effect(music_bus, eq, 0)

func change_scene_with_transition(new_scene_path: String, transition_type: String = "fade"):
	# Create a ColorRect for transition effect
	var transition = ColorRect.new()
	transition.color = Color.BLACK
	transition.size = get_viewport().size
	transition.z_index = 1000  # Make sure it's on top
	get_tree().root.add_child(transition)
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(transition, "color:a", 1.0, transition_time/2)
	tween.tween_callback(func():
		# Load new scene
		get_tree().change_scene_to_file(new_scene_path)
		
		# Fade in after scene loaded
		var new_tween = create_tween()
		new_tween.tween_property(transition, "color:a", 0.0, transition_time/2)
		new_tween.tween_callback(func(): transition.queue_free())
	)

func play_music(stream: AudioStream, volume: float = 0.0):
	if not music_player:
		music_player = AudioStreamPlayer.new()
		add_child(music_player)

	stream.loop = true
	music_player.bus = "Music"
	music_player.stream = stream
	music_player.volume_db = volume
	music_player.play()
