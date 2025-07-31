class_name Word
extends Node2D

static var currently_dragging_node: Word = null
static var z_max := 10

@onready var label = %Label
@onready var sprite = %Sprite

const MAX_WIDTH = 55       # Or whatever width your sprite allows
const MIN_FONT_SIZE = 45     # Avoid fonts getting too tiny
const MAX_FONT_SIZE = 75     # Starting point for big text

var next : Word = null
var prev : Word = null

var normal_scale := Vector2.ONE
var loop_scale := Vector2(0.7, 0.7)  # adjust this to what looks good
var tween: Tween = null

var word: String = ""
var current_location := Utils.Location.POOL
var spawn_point := Vector2.ZERO
var loop_point := Vector2.ZERO
var drag_offset := Vector2.ZERO
var dragging := false
var just_dropped := false
var tweening := false

func _ready():
	label.text = word
	scale = normal_scale
	fit_text_to_width()

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
					toggle_scale()
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
	#tween.set_trans(Tween.TRANS_SINE) # standard linear
	tween.set_trans(Tween.TRANS_BACK) # bouncy
	#tween.set_trans(Tween.TRANS_ELASTIC) # very snappy, maybe for invalid motions?
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", get_parent().to_local(global_pos), 0.4)
	
	# when movement is over, set these variables
	tween.finished.connect(func():
		tweening = false
		just_dropped = false
		#bounce_scale()
	)

## very bouncy, cartoony reaction to being dropped off
## currently not in use, but could be useful
func bounce_scale():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 0.8), 0.1).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)

func toggle_scale() -> void:
	if (scale == normal_scale):
		scale_to(loop_scale)
	else:
		scale_to(normal_scale)

func scale_to(target_scale: Vector2, duration: float = 0.2):
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", target_scale, duration)

func _is_mouse_over() -> bool:
	var region_size = sprite.region_rect.size * sprite.scale
	var bounds = Rect2(-region_size / 2, region_size)
	var mouse_pos = to_local(get_viewport().get_mouse_position())
	return bounds.has_point(mouse_pos)

func fit_text_to_width():
	var font: Font = label.get_theme_font("font")
	var best_size := MIN_FONT_SIZE

	for size in range(MAX_FONT_SIZE, MIN_FONT_SIZE - 1, -1):
		var width := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, size).x
		if width <= MAX_WIDTH:
			best_size = size
			break

	# Ensure label_settings exists
	if label.label_settings == null:
		label.label_settings = LabelSettings.new()
	else:
		label.label_settings = label.label_settings.duplicate()

	label.label_settings.font_size = best_size
