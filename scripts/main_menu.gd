class_name MainMenu
extends CanvasLayer

@onready var main_menu := %MainMenuUI
@onready var how_to_play_menu := %HowToPlayUI
@onready var credits_menu := %CreditsUI

@onready var start_button := %StartButton
@onready var credits_button := %CreditsButton
@onready var how_to_play_button := %HowToPlayButton

func _ready():
	main_menu.visible = true
	how_to_play_menu.visible = false
	credits_menu.visible = false
	register_events()

func register_events():
	for button in get_tree().get_nodes_in_group("buttons"):
		button.connect("custom_button_pressed", Callable(self, "handle_custom_buttons"))

func handle_custom_buttons(button_type: Utils.ButtonType):
	match button_type:
		Utils.ButtonType.RESTART:
			on_start_button()
		Utils.ButtonType.HOW_TO_PLAY:
			on_how_to_play_button()
		Utils.ButtonType.CREDITS:
			on_credits_button()
		Utils.ButtonType.BACK:
			on_back_button()

func on_start_button():
	main_menu.visible = false
	SceneManager.change_scene_with_transition("res://scenes/main.tscn")

func on_how_to_play_button():
	main_menu.visible = false
	how_to_play_menu.visible = true

func on_credits_button():
	main_menu.visible = false
	credits_menu.visible = true

func on_back_button():
	main_menu.visible = true
	how_to_play_menu.visible = false
	credits_menu.visible = false
