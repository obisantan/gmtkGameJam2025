###################################################################################################
## MAIN (the game, essentially)																	 ##
###################################################################################################

class_name Main
extends Node2D

@onready var word_pool : WordPool = %WordPool
@onready var loop_area : LoopArea = %LoopArea
@onready var line_container = %LineContainer

@onready var message_label = %MessageLabel
@onready var points_label = %PointsLabel
@onready var curr_points_label = %CurrPointsLabel
@onready var level_label = %LevelLabel
@onready var loops_label = %LoopsLabel

@onready var game_over_screen : GameOverScreen = %GameOverScreen
@onready var you_won_screen : YouWonScreen = %YouWonScreen
@onready var are_you_sure_screen := %AreYouSureScreen

@onready var submit_button := %SubmitButton

## TRACKING WORDS AND LOOPS
var previously_used_words: Array[String] = []
var loop: Array[Word] = []
var line_nodes: Array[Line2D] = []
var loop_complete: bool = false
var pulse_time: float = 0.0

## LEVEL LOGIC
## TODO: make all of this a json thingy, where its one dictionary
var point_multipliers: Dictionary = {
	3: 1.0, 4: 1.0, 5: 1.5, 6: 1.5, 7: 2, 8: 3, 9: 4, 10: 5, 11: 10, 12: 15, 13: 20, 14: 50, 15: 100
}
var level_point_goals: Dictionary = {
	1: 50, 2: 75, 3: 100, 4: 200, 5: 300, 6: 400, 7: 500, 8: 750, 9: 1000, 10: 1500
}
# could be modified in the future, for now its just the round number
var level_loop_amount: Dictionary = {
	1: 5, 2: 5, 3: 5, 4: 5, 5: 5, 6: 5, 7: 5, 8: 5, 9: 5, 10: 5
}

############### STUFF USED FOR DEBUG
# could be modified in the future, for now its just the round number
var debug_level_loop_amount: Dictionary = {
	1: 1
}

### points and loop number tracking for ingame... global stats are saved in Utils
var level_points: int = 0
var current_loop_points: int = 0
var current_level: int = 1
var loops_submitted_in_level: int = 0
var loops_left_in_level: int = 1

func _ready():
	### TEST TODO
	submit_button.visible = false
	current_level = 1
	game_over_screen.visible = false
	you_won_screen.visible = false
	are_you_sure_screen.visible = false
	loops_left_in_level = debug_level_loop_amount[current_level] if Utils.debugging else level_loop_amount[current_level]
	message_label.visible = Utils.debugging
	message_label.text = ""
	if !Utils.debugging: message_label.visible = false
	update_ui()
	register_events()
	clear_lines()

func register_events():
	for button in get_tree().get_nodes_in_group("buttons"):
		button.connect("custom_button_pressed", Callable(self, "handle_custom_buttons"))

func handle_custom_buttons(button_type: Utils.ButtonType):
	match button_type:
		Utils.ButtonType.RESTART:
			on_restart_button()
		Utils.ButtonType.SHUFFLE:
			on_shuffle_button()
		Utils.ButtonType.RESET:
			on_reset_button()
		Utils.ButtonType.SUBMIT:
			on_submit_button()
		Utils.ButtonType.ARE_YOU_SURE:
			on_are_you_sure_button()
		Utils.ButtonType.MAIN_MENU:
			on_main_menu_button()
		Utils.ButtonType.BACK:
			on_back_button()

func on_reset_button():
	clear_lines()
	for word_node in loop:
		move_back_to_spawn(word_node)
	loop = []
	current_loop_points = 0
	update_ui()
	submit_button.visible = false
	message_label.text = "ℹ️ Loop Reset!"
	print(loop)

func on_restart_button():
	get_tree().reload_current_scene()

func on_are_you_sure_button():
	are_you_sure_screen.visible = true

func on_back_button():
	are_you_sure_screen.visible = false

func on_main_menu_button():
	# TODO: save state and add continue button
	game_over_screen.visible = false
	you_won_screen.visible = false
	are_you_sure_screen.visible = false
	SceneManager.change_scene_with_transition("res://scenes/main_menu.tscn")

func on_shuffle_button():
	word_pool.shuffle_words()

func on_submit_button():
	# before removing loop, we need to check how many words need to be replaced in the word pool, and where they spawned
	var amount_of_words_in_submitted_loop = loop.size()
	var new_spawn_points: Array[Vector2]
	for word_node in loop:
		new_spawn_points.append(word_node.spawn_point)
	
	# award points and keep track of score
	level_points += current_loop_points
	update_global_scores()
	remove_loop()

	## you achieved more points than required this level
	if (level_points >= level_point_goals[current_level]):
		if (current_level == get_amount_of_levels()):
			## you won the game
			you_won_screen.visible = true
		else:
			## you move to the next level
			current_level += 1
			loops_left_in_level = level_loop_amount[current_level]
			loops_submitted_in_level = 0
			level_points = 0
			var new_words = DictionaryManager.refill_word_pool(previously_used_words, get_words_currently_in_pool(), amount_of_words_in_submitted_loop)
			word_pool.spawn_word_nodes(new_words, new_spawn_points)

	else:
		## you did not achieve enough points to beat the level
		loops_left_in_level -= 1
		loops_submitted_in_level += 1
		if (loops_left_in_level == 0):
			## you are out of loops, game over
			game_over_screen.visible = true
		else:
			# you keep going in this level, refill board
			var new_words = DictionaryManager.refill_word_pool(previously_used_words, get_words_currently_in_pool(), amount_of_words_in_submitted_loop)
			word_pool.spawn_word_nodes(new_words, new_spawn_points)
			print(new_words)

	# this happens either way
	submit_button.visible = false
	update_ui()

###################################################################################################
## LOOP LOGIC																					 	##
###################################################################################################

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
						word_node.scale_to(word_node.loop_scale)
						word_node.move_to_pos(word_node.loop_point)

					word_node.dragging = false
				else:
					# Not dropped in pool area, reset drag
					word_node.dragging = false
					word_node.scale_to(word_node.loop_scale)
					word_node.move_to_pos(word_node.loop_point)

	# and at the end, keep lines up to date with word locations
	update_lines(delta)

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
	word_node.location = Utils.Location.LOOP
	word_node.global_position = drop_pos
	word_node.scale_to(word_node.loop_scale)
	arrange_loop_words()
	check_loop_complete(word_node, true)
	#Utils.print_current_loop(loop)
	redraw_lines()
	update_ui()

func arrange_loop_words():
	var radius_x = 180.0  # horizontal radius (ellipse width)
	var radius_y = 85.0   # vertical radius (ellipse height)
	var center = loop_area.global_position
	var count = loop.size()
	if count == 0:
		return

	var start_angle = PI
	for i in range(count):
		var angle = start_angle + i * TAU / float(count)

		# Elliptical offset using both radii
		var offset = Vector2(cos(angle) * radius_x, sin(angle) * radius_y)
		var global_pos = center + offset

		var current_word = loop[i]

		# Set position
		current_word.loop_point = global_pos
		current_word.move_to_pos(global_pos)

		# Set tangent rotation (for ellipse, approximate using angle)
		#current_word.rotation = angle + PI / 2  # or -PI / 2 for reverse orientation
		
		# Approximate "stretch" along the radial direction
		#var stretch_factor = 1.0 + 0.2 * sin(angle)  # vertical bulge
		#current_word.scale = Vector2(1.1, stretch_factor)

		# OPTIONAL: fake skew by offsetting the child label/sprite
		#if current_word.has_node("Sprite"):
		#	var sprite = current_word.get_node("Sprite")
		#	sprite.position = Vector2(0, 5 * sin(angle))  # vertical push

	redraw_lines()

func check_loop_complete(word_node: Word, was_added: bool):
	if was_added:
		if (loop.size() == 1):
			message_label.text = "✅ Loop started with %s!" % word_node.word
			submit_button.visible = false
		# lets assume (for now), that you need 3 or more to make a loop --> potentially look at 2 word loop in the future
		elif loop.size() >= 3 and loop[0].word[0] == loop[-1].word[-1]:
			message_label.text = "🥳🥂🍾 Loop Complete! 🥳🥂🍾"
			submit_button.visible = true
		else:
			message_label.text = "✅ '%s' added to Loop!" % word_node.word
			submit_button.visible = false
	else:
		if loop.size() >= 3 and loop[0].word[0] == loop[-1].word[-1]:
			message_label.text = "🥳🥂🍾 Loop Complete! 🥳🥂🍾"
			submit_button.visible = true
		elif loop.size() == 0:
			message_label.text = "ℹ️ Loop Reset!"
			submit_button.visible = false
		else:
			submit_button.visible = false

			if word_node == loop[0]:
				message_label.text = "✅ Removed %s, changed Loop start to %s!" % [word_node.word, loop[0].word]
			else:
				message_label.text = "✅ Removed %s!" % [word_node.word]

func can_remove_word(word_node: Word):
	if loop.size() == 0:
		print("how are you gonna remove a word from an empty array? 🤔")
		return false

	if word_node == loop[0] or word_node == loop[-1]:
		return true
	else:
		return false

func remove_word_from_loop(word_node: Word):
	if word_node == loop[0] or word_node == loop[-1]:
		loop.erase(word_node)
	
	# move it back to spawn
	move_back_to_spawn(word_node)
	
	#rearrange stuff
	arrange_loop_words()
	check_loop_complete(word_node, false)
	#Utils.print_current_loop(loop)
	redraw_lines()
	update_ui()

func move_back_to_spawn(word_node: Word) -> void:
	var drop_pos = word_node.global_position  # keep visual position before reparent
	word_node.get_parent().remove_child(word_node)
	word_pool.add_child(word_node)
	word_node.location = Utils.Location.POOL
	word_node.global_position = drop_pos  # keep position visually consistent
	word_node.scale_to(word_node.normal_scale)
	word_node.rotation = 0
	word_node.move_to_pos(word_node.spawn_point)  # tween to global position of spawn_point

func update_ui() -> void:
	if loop.size() < 3:
		loops_label.text = "%s / %s Loops" % [loops_submitted_in_level, loops_left_in_level]
		level_label.text = "Level %s" % current_level
		points_label.text = "%s / %s Points" % [level_points, level_point_goals[current_level]]
		curr_points_label.text = "- x -"
		return

	var points = 0
	var curr_mult = point_multipliers[loop.size()]

	for word in loop:
		points += word.points
	
	curr_points_label.text = "%s x %s" % [points, curr_mult]
	
	points *= curr_mult
	current_loop_points = points

func update_global_scores() -> void:
	Utils.this_run_total_points += current_loop_points
	Utils.this_run_total_loops_submitted += 1
	if (current_loop_points > Utils.this_run_best_loop_score): Utils.this_run_best_loop_score = current_loop_points
	if (loop.size() > Utils.this_run_best_loop_word_amount): Utils.this_run_best_loop_word_amount = loop.size()
	if (current_level > Utils.this_run_highest_level_reached): Utils.this_run_highest_level_reached = current_level

func remove_loop():
	for word_node in loop:
		previously_used_words.append(word_node.word)
		var tween = create_tween()
		tween.tween_property(word_node, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
		tween.tween_property(word_node, "scale", Vector2(1.2, 1.2), 0.4)
		tween.tween_callback(Callable(word_node, "queue_free"))
	loop.clear()
	current_loop_points = 0
	clear_lines()
	update_ui()

func get_words_currently_in_pool() -> Array[String]:
	var result: Array[String] = []
	for word_node in word_pool.get_children():
		if word_node.is_in_group("words"):
			result.append(word_node.word)
	return result

func get_amount_of_levels() -> int:
	return debug_level_loop_amount.size() if Utils.debugging else level_loop_amount.size()

###################################################################################################
## LINE STUFF																					 ##
###################################################################################################

func clear_lines():
	# Remove existing lines (if any)
	for line in line_nodes:
		line.queue_free()
	line_nodes.clear()

func redraw_lines():
	clear_lines()

	if loop.size() < 2:
		loop_complete = false
		return

	# Check if full loop is valid (first and last connect)
	loop_complete = loop.size() >= 3 and loop[0].word[0] == loop[-1].word[-1]

	for i in range(loop.size() - 1):
		var start_word = loop[i]
		var end_word = loop[i + 1]
		if start_word.word[-1] == end_word.word[0]:
			var line = Line2D.new()
			line.antialiased = true
			line.default_color = Color(0.122, 0.643, 0.004, 1.0) if loop_complete else Color(0.878, 0.282, 0.008, 1.0)
			line.width = 10.0
			line.points = [
				line_container.to_local(start_word.global_position),
				line_container.to_local(end_word.global_position)
			]
			line_container.add_child(line)
			line_nodes.append(line)

	# Only draw final closing line if loop is actually valid
	if loop_complete:
		var first = loop[0]
		var last = loop[-1]
		var final_line = Line2D.new()
		final_line.antialiased = true
		final_line.default_color = Color(0.122, 0.643, 0.004, 1.0)
		final_line.width = 10
		final_line.points = [
			line_container.to_local(last.global_position),
			line_container.to_local(first.global_position)
		]
		line_container.add_child(final_line)
		line_nodes.append(final_line)

func update_lines(delta):
	if loop.size() < 2 or line_nodes.size() == 0:
		return

	var index = 0
	for i in range(loop.size() - 1):
		var start_word = loop[i]
		var end_word = loop[i + 1]
		if start_word.word[-1] == end_word.word[0]:
			var line = line_nodes[index]
			line.points = [
				line_container.to_local(start_word.global_position),
				line_container.to_local(end_word.global_position)
			]

			if loop_complete:
				pulse_time += delta * 4.0
				line.width = 10 + sin(pulse_time) * 3
			index += 1

	if loop_complete and index < line_nodes.size():
		var first = loop[0]
		var last = loop[-1]
		var final_line = line_nodes[index]
		final_line.points = [
			line_container.to_local(last.global_position),
			line_container.to_local(first.global_position)
		]
		final_line.width = 10.0 + sin(pulse_time) * 3
