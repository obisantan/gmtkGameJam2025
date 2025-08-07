class_name LoopArea
extends Node2D

@onready var sprite = %NinePatchRect


func _draw():
	var region_size = sprite.size * sprite.scale
	#draw_rect(Rect2(-region_size / 2, region_size), Color.RED, false)


func is_inside(global_point: Vector2) -> bool:
	var region_size = sprite.size * sprite.scale
	# TODO: increase bounds to make it easier to drag words into loop_area
	var bounds: Rect2      = Rect2(-region_size / 2, region_size)
	var local_pos: Vector2 = to_local(global_point)
	return bounds.has_point(local_pos)
