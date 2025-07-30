class_name LoopArea
extends Node2D

@onready var sprite = $Sprite


func _draw():
	var region_size = sprite.region_rect.size * sprite.scale
	#draw_rect(Rect2(-region_size / 2, region_size), Color.RED, false)


func is_inside(global_point: Vector2) -> bool:
	var region_size = sprite.region_rect.size * sprite.scale
	var bounds = Rect2(-region_size / 2, region_size)
	var local_pos = to_local(global_point)
	return bounds.has_point(local_pos)
