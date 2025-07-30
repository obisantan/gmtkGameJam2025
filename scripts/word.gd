class_name Word
extends Node2D

@export var word: String = ""

@onready var label = %Label
@onready var sprite = %Sprite

var dragging := false
var drag_offset := Vector2.ZERO

static var currently_dragging_node: Word = null


func _ready():
	label.text = word

#func _draw():
#	var region_size = sprite.region_rect.size * sprite.scale
#	draw_rect(Rect2(-region_size / 2, region_size), Color.RED, false)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if currently_dragging_node == null and _is_mouse_over():
					currently_dragging_node = self
					dragging = true
					drag_offset = global_position - event.position
					z_index = 1000
					get_viewport().set_input_as_handled()
			else:
				if currently_dragging_node == self:
					dragging = false
					z_index = 5
					currently_dragging_node = null

	elif event is InputEventMouseMotion:
		if dragging and currently_dragging_node == self:
			global_position = event.position + drag_offset


func _is_mouse_over() -> bool:
	var region_size = sprite.region_rect.size * sprite.scale
	var bounds = Rect2(-region_size / 2, region_size)
	var mouse_pos = to_local(get_viewport().get_mouse_position())
	return bounds.has_point(mouse_pos)
