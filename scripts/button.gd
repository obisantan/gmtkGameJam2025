@tool
extends Control

signal custom_button_pressed

@export var button_type: Utils.ButtonType
@export var text : String = "CLICK" :
	set(value):
		text = value
		update_button_text()

@onready var background = $Sprite
@onready var label = $Label

func _ready():
	size = background.size
	label.text = text

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed == false:
		emit_signal("custom_button_pressed", button_type)

func update_button_text():
	if is_inside_tree():  # Safe to call during editing and runtime
		label.text = text
