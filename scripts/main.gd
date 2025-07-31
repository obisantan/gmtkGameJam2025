class_name Main
extends Node2D

@onready var reset_button := %ResetButton
@onready var restart_button := %RestartButton

@onready var word_pool = $WordPool
@onready var loop_area : LoopArea = $LoopArea
@onready var message_label = %MessageLabel

var word_list_debug = ["apple", "elephant", "tiger", "rat", "tree", "egg", "grape", "emu", "umbrella", "ant"]
var word_list = []
var current_loop: Array[Node2D] = []

func _ready():
	word_list = DictionaryManager.get_level_words()
	register_events()
	spawn_word_nodes()

func register_events():
	# currently there is not a reason for eventManager yet...
	reset_button.button_up.connect(on_reset_button)
	#EventManager.button_pressed_reset.connect(on_reset_button)
	restart_button.button_up.connect(on_restart_button)
	#EventManager.button_pressed_restart.connect(on_restart_button)	

func on_reset_button():
	# reset current loop, but all words back
	for word_node in current_loop:
		move_back_to_spawn(word_node)
	current_loop = []
	message_label.text = "ℹ️ Loop Reset!"
	print(current_loop)

func on_restart_button():
	get_tree().reload_current_scene()


func spawn_word_nodes():
	var grid_size = Vector2(135, 70)  # adjust based on sprite size + spacing
	var cols = 5
	var start_pos = Vector2(-270, 0)
	
	var word_scene = preload("res://scenes/word.tscn")
	for i in range(word_list.size()):
		var word_node = word_scene.instantiate()
		word_node.word = word_list[i]
		word_node.global_position = start_pos + Vector2(i % cols, i / cols) * grid_size
		word_pool.add_child(word_node)
		word_node.spawn_point = word_node.position  # local position, relative to word_pool

func _process(delta):
	for word_node in word_pool.get_children():
		if word_node.is_in_group("words") and word_node.just_dropped:
			#print("%s dragging? %s, mouse pressed? %s" % [word_node.word, word_node.dragging, Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)])

			# Check if word is released over loop_area
			if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				if loop_area.is_inside(word_node.global_position):
					if can_add_word(word_node.word):
						add_word_to_loop(word_node)
					else:
						message_label.text = "❌ Invalid connection for '%s'!" % word_node.word
						move_back_to_spawn(word_node)

					word_node.dragging = false
					#for i in current_loop:
						#print(i.word)
				else:
					# Not dropped in loop area, reset drag
					word_node.dragging = false
					move_back_to_spawn(word_node)

func can_add_word(word: String) -> bool:
	if current_loop.size() == 0:
		return true
	var last_word = current_loop[-1].word
	return last_word[-1] == word[0]

func add_word_to_loop(word_node: Word):
	current_loop.append(word_node)

	# Store the current global position before reparenting
	var drop_pos = word_node.global_position

	word_node.get_parent().remove_child(word_node)
	loop_area.add_child(word_node)

	# Tell the word to smoothly move from its old position to new layout
	word_node.global_position = drop_pos  # restore so it appears in the same spot
	arrange_loop_words()
	check_loop_complete(word_node)

func arrange_loop_words():
	var radius = 85.0
	var center = loop_area.global_position
	var count = current_loop.size()
	if count == 0:
		return

	var start_angle = PI
	for i in range(count):
		var angle = start_angle + i * TAU / count
		var offset = Vector2(cos(angle), sin(angle)) * radius
		var global_pos = center + offset

		current_loop[i].move_to_pos(global_pos)

func check_loop_complete(word_node: Node2D):
	if (current_loop.size() == 1):
		message_label.text = "✅ Loop started with %s!" % word_node.word
	elif current_loop.size() >= 2 and current_loop[0].word[0] == current_loop[-1].word[-1]:
		message_label.text = "✅ Loop Complete!"
	else:
		message_label.text = "✅ '%s' added to Loop!" % word_node.word


func move_back_to_spawn(word_node: Word) -> void:
	word_node.just_dropped = false
	var drop_pos = word_node.global_position  # keep visual position before reparent
	word_node.get_parent().remove_child(word_node)
	word_pool.add_child(word_node)
	word_node.global_position = drop_pos  # keep position visually consistent
	word_node.move_to_pos(word_node.get_parent().to_global(word_node.spawn_point))  # tween to global position of spawn_pointn
