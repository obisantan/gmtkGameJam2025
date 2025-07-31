class_name Main
extends Node2D

@onready var reset_button := %ResetButton
@onready var restart_button := %RestartButton

@onready var word_pool = $WordPool
@onready var loop_area : LoopArea = $LoopArea
@onready var message_label = %MessageLabel

var word_list_debug = ["apple", "elephant", "tiger", "rat", "tree", "egg", "grape", "emu", "umbrella", "ant"]
var word_list = []
var loop: Array[Word] = []

func _ready():
	word_list = word_list_debug
	#word_list = DictionaryManager.get_level_words()
	register_events()
	spawn_word_nodes()

func register_events():
	# currently there is not a reason for global events yet...
	reset_button.button_up.connect(on_reset_button)
	#Utils.event_button_pressed_reset.connect(on_reset_button)
	restart_button.button_up.connect(on_restart_button)
	#Utils.event_button_pressed_restart.connect(on_restart_button)	

func on_reset_button():
	# reset current loop, but all words back
	for word_node in loop:
		move_back_to_spawn(word_node)
	loop = []
	message_label.text = "ℹ️ Loop Reset!"
	print(loop)

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
	# loops over all words assigned to word_pool
	for word_node in word_pool.get_children():
		if word_node.is_in_group("words") and word_node.just_dropped and not word_node.tweening:
			#print("%s dragging? %s, mouse pressed? %s" % [word_node.word, word_node.dragging, Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)])

			# Check if word is released over loop_area
			if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				
				# if word is dropped inside loop_area
				if loop_area.is_inside(word_node.global_position):
					if can_add_word(word_node.word):
						add_word_to_loop(word_node)
					else:
						message_label.text = "❌ Invalid connection for '%s'!" % word_node.word
						move_back_to_spawn(word_node)

					word_node.dragging = false
					#for i in loop:
						#print(i.word)
				else:
					# Not dropped in loop area, reset drag
					word_node.dragging = false
					move_back_to_spawn(word_node)
	
	# loops over all words assigned to loop_area
	for word_node in loop_area.get_children():
		if word_node.is_in_group("words") and word_node.just_dropped and not word_node.tweening:
			if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				
				# if word is dropped inside word_pool
				if word_pool.is_inside(word_node.global_position):
					if can_remove_word(word_node):
						remove_word_from_loop(word_node)
					else:
						message_label.text = "❌ Cannot remove '%s' from Loop!" % word_node.word
						word_node.move_to_pos(word_node.get_parent().to_global(word_node.loop_point))

					word_node.dragging = false
				else:
					# Not dropped in pool area, reset drag
					word_node.dragging = false
					word_node.move_to_pos(word_node.get_parent().to_global(word_node.loop_point))

func can_add_word(word: String) -> bool:
	if loop.size() == 0:
		return true
	var last_word = loop[-1].word # references last word 
	return last_word[-1] == word[0] # compares the last letter in the last word to the current first letter

func add_word_to_loop(word_node: Word):
	loop.append(word_node)
	# Store the current global position before reparenting
	var drop_pos = word_node.global_position
	word_node.get_parent().remove_child(word_node)
	loop_area.add_child(word_node)
	word_node.current_location = Utils.Location.LOOP

	# Tell the word to smoothly move from its old position to new layout
	word_node.global_position = drop_pos  # restore so it appears in the same spot
	arrange_loop_words()
	check_loop_complete(word_node, true)
	Utils.print_current_loop(loop)

func arrange_loop_words():
	var radius = 85.0
	var center = loop_area.global_position
	var count = loop.size()
	if count == 0:
		return

	var start_angle = PI
	for i in range(count):
		var angle = start_angle + i * TAU / count
		var offset = Vector2(cos(angle), sin(angle)) * radius
		var global_pos = center + offset
		var current_word = loop[i]
		current_word.move_to_pos(global_pos)
		current_word.loop_point = current_word.position # just like spawn_point, local coords instead of global

func check_loop_complete(word_node: Word, was_added: bool):
	if was_added:
		if (loop.size() == 1):
			message_label.text = "✅ Loop started with %s!" % word_node.word
		# lets assume (for now), that you need 3 or more to make a loop --> potentially look at 2 word loop in the future
		elif loop.size() >= 3 and loop[0].word[0] == loop[-1].word[-1]:
			message_label.text = "🥳🥂🍾 Loop Complete! 🥳🥂🍾"
		else:
			message_label.text = "✅ '%s' added to Loop!" % word_node.word
	else:
		if loop.size() >= 3 and loop[0].word[0] == loop[-1].word[-1]:
			message_label.text = "🥳🥂🍾 Loop Complete! 🥳🥂🍾"
		elif loop.size() == 0:
			message_label.text = "ℹ️ Loop Reset!"
		else:
			message_label.text = "✅ Removed %s, changed Loop start to %s!" % [word_node.word, loop[0].word]

func can_remove_word(word_node: Word):
	if loop.size() == 0:
		print("how are you gonna remove a word from an empty array? 🤔")
		return false

	if word_node == loop[0] or word_node == loop[-1]:
		return true
	else:
		return false

func remove_word_from_loop(word_node: Word):
	# lets see if it is possible to do the same for both cases
	if word_node == loop[0]:
		loop.erase(word_node)

	elif word_node == loop[-1]:
		loop.erase(word_node)
	
	# move it back to spawn
	move_back_to_spawn(word_node)
	
	#rearrange stuff
	arrange_loop_words()
	check_loop_complete(word_node, false)
	Utils.print_current_loop(loop)

func move_back_to_spawn(word_node: Word) -> void:
	#word_node.just_dropped = false
	var drop_pos = word_node.global_position  # keep visual position before reparent
	word_node.get_parent().remove_child(word_node)
	word_pool.add_child(word_node)
	word_node.current_location = Utils.Location.POOL
	word_node.global_position = drop_pos  # keep position visually consistent
	word_node.move_to_pos(word_node.get_parent().to_global(word_node.spawn_point))  # tween to global position of spawn_point
