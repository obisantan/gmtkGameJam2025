class_name Main
extends Node2D


@onready var word_pool = $WordPool
@onready var loop_area : LoopArea = $LoopArea
@onready var message_label = $MessageLabel

var word_list = ["apple", "elephant", "tiger", "rat", "tree", "egg", "grape", "emu", "umbrella", "ant"]
var current_loop: Array[Node2D] = []

func _ready():
	spawn_word_nodes()

func spawn_word_nodes():
	var word_scene = preload("res://scenes/word.tscn")
	for i in range(word_list.size()):
		var word_node = word_scene.instantiate()
		word_node.word = word_list[i]
		word_node.position = Vector2(i * 10, 0)
		word_pool.add_child(word_node)

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
						message_label.text = "❌ Invalid connection for '%s'" % word_node.word
					word_node.dragging = false
				else:
					# Not dropped in loop area, reset drag
					word_node.dragging = false

func can_add_word(word: String) -> bool:
	if current_loop.size() == 0:
		return true
	var last_word = current_loop[-1].word
	return last_word[-1] == word[0]

func add_word_to_loop(word_node: Node2D):
	current_loop.append(word_node)
	word_node.get_parent().remove_child(word_node)
	loop_area.add_child(word_node)
	word_node.position = Vector2(-390 + current_loop.size() * 150, 0)
	check_loop_complete(word_node)

func check_loop_complete(word_node: Node2D):
	if (current_loop.size() == 1):
		message_label.text = "✅ Loop started with %s!" % word_node.word
	elif current_loop.size() >= 3 and current_loop[0].word[0] == current_loop[-1].word[-1]:
		message_label.text = "✅ Loop Complete!"
	else:
		message_label.text = "✅ '%s' added to Loop!" % word_node.word
