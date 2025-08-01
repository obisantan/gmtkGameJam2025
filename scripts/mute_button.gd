class_name MuteButton
extends TextureButton

func _ready():
	if AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")):
		self.button_pressed = true
	toggled.connect(_on_toggle)

func _on_toggle(toggled_on: bool):
	if (toggled_on):
		AudioServer.set_bus_mute(SceneManager.music_bus, true)
	else:
		AudioServer.set_bus_mute(SceneManager.music_bus, false)
