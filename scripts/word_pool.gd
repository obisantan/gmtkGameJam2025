class_name WordPool
extends Node2D

@onready var sprite = $Sprite

## WORDPOOL GRID
var spawn_points: Array[Vector2] = [] # this holds all available spawn points in the word pool (only gets regenerated at level start)
var grid_size = Vector2(135, 70)  # adjust based on sprite size + spacing
var cols = 5
var start_pos = Vector2(-270, -70)

func _ready():
	var word_list: Array[String] = ["apple", "elephant", "tiger", "rat", "tree", "egg", "grape", "emu", "umbrella", "ant"]
	#var word_list: Array[String] = DictionaryManager.get_level_words()
	generate_spawn_points(DictionaryManager.total_words)
	spawn_word_nodes(word_list)

func _draw():
	var region_size = sprite.region_rect.size * sprite.scale
	#draw_rect(Rect2(-region_size / 2, region_size), Color.RED, false)

func is_inside(global_point: Vector2) -> bool:
	var region_size = sprite.region_rect.size * sprite.scale
	var bounds = Rect2(-region_size / 2, region_size)
	var local_pos = to_local(global_point)
	return bounds.has_point(local_pos)

###################################################################################################
## SPAWN AND REFILL LOGIC																		  ##
###################################################################################################

func generate_spawn_points(amount: int) -> void:
	spawn_points.clear()
	for i in range(amount):
		var local_point = start_pos + Vector2(i % cols, i / cols) * grid_size
		var global_point = to_global(local_point)
		spawn_points.append(global_point)

func spawn_word_nodes(word_list: Array[String], needed_spawn_points: Array[Vector2] = []):
	var word_scene = preload("res://scenes/word.tscn")
	
	# Determine spawn points: if none provided, fill all of them
	if needed_spawn_points.is_empty():
		needed_spawn_points = spawn_points

	for i in range(word_list.size()):
		var word_node = word_scene.instantiate()
		word_node.word = word_list[i]

		## VERY IMPORTANT: first, set global position, then add word to new parent, THEN save the spawn point
		# hold on, apparently not?
		add_child(word_node)
		word_node.global_position = needed_spawn_points[i]
		word_node.spawn_point = word_node.global_position
		word_node.spawn_in()

func shuffle_words() -> void:
	var all_words := []
	var all_spawn_points := []
	for word_node in get_tree().get_nodes_in_group("words"):
		if word_node.location == Utils.Location.POOL:
			all_words.append(word_node)
			all_spawn_points.append(word_node.spawn_point)
	if all_words.size() <= 1:
		return

	# Shuffle all words
	all_words.shuffle()

	for i in range(all_words.size()):
		var word_node = all_words[i]
		word_node.spawn_point = all_spawn_points[i]
		word_node.move_to_pos(word_node.spawn_point)
