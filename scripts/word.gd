class_name Word
extends Node2D

@export var word: String = ""

@onready var label = %Label
@onready var sprite = %Sprite

static var currently_dragging_node: Word = null
static var z_max := 10

var drag_offset := Vector2.ZERO
var spawn_point := Vector2.ZERO
var dragging := false
var just_dropped := false


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
					just_dropped = false
					drag_offset = global_position - event.position
					z_index = 1000
					get_viewport().set_input_as_handled()
					print("%s: %s, z-max: %s" % [self.word, z_index, z_max])
			else:
				if currently_dragging_node == self:
					dragging = false
					just_dropped = true
					z_index = z_max + 1
					z_max = z_index
					currently_dragging_node = null
					print("%s: %s, z-max: %s" % [self.word, z_index, z_max])


	elif event is InputEventMouseMotion:
		if dragging and currently_dragging_node == self:
			global_position = event.position + drag_offset


func _is_mouse_over() -> bool:
	var region_size = sprite.region_rect.size * sprite.scale
	var bounds = Rect2(-region_size / 2, region_size)
	var mouse_pos = to_local(get_viewport().get_mouse_position())
	return bounds.has_point(mouse_pos)
