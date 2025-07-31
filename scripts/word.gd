class_name Word
extends Node2D

@onready var label = %Label
@onready var sprite = %Sprite
var word: String = ""


static var currently_dragging_node: Word = null
static var z_max := 10

var drag_offset := Vector2.ZERO
var spawn_point := Vector2.ZERO
var loop_point := Vector2.ZERO
var dragging := false
var just_dropped := false
var tweening := false
var current_location := Utils.Location.POOL

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
					#print("%s: %s, z-max: %s" % [self.word, z_index, z_max])
			else:
				if currently_dragging_node == self:
					dragging = false
					just_dropped = true
					z_index = z_max + 1
					z_max = z_index
					currently_dragging_node = null
					#print("%s: %s, z-max: %s" % [self.word, z_index, z_max])


	elif event is InputEventMouseMotion:
		if dragging and currently_dragging_node == self:
			global_position = event.position + drag_offset

func move_to_pos(global_pos: Vector2) -> void:
	tweening = true
	var tween := get_tree().create_tween()
	tween.tween_property(self, "position", get_parent().to_local(global_pos), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		tweening = false
		just_dropped = false
	)

func _is_mouse_over() -> bool:
	var region_size = sprite.region_rect.size * sprite.scale
	var bounds = Rect2(-region_size / 2, region_size)
	var mouse_pos = to_local(get_viewport().get_mouse_position())
	return bounds.has_point(mouse_pos)
