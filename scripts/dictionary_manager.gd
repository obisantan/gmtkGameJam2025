### GLOBAL PRELOAD - DictionaryManager
extends Node


# Parameters for difficulty tuning
var total_words := 10  # Total number of words in a level
var loop_size_range := Vector2i(4, 6)  # Min and max length of the valid loop
var min_word_length := 4
var max_word_length := 7

# Internal storage
var all_words := []
var filtered_words := []
var words_by_first_letter := {}

func _ready():
	load_words("res://dictionary/nouns.txt")

func load_words(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open dictionary file: %s" % path)
		return

	all_words.clear()
	filtered_words.clear()
	words_by_first_letter.clear()

	while not file.eof_reached():
		var word = file.get_line().strip_edges().to_lower()
		if word.length() >= min_word_length and word.length() <= max_word_length:
			filtered_words.append(word)
			var first = word[0]
			if not words_by_first_letter.has(first):
				words_by_first_letter[first] = []
			words_by_first_letter[first].append(word)
	file.close()

func create_valid_loop() -> Array:
	var loop = []
	var tries = 100
	var loop_size = randi_range(loop_size_range.x, loop_size_range.y)

	while tries > 0:
		loop.clear()
		var word = filtered_words.pick_random()
		loop.append(word)

		while loop.size() < loop_size:
			var last_letter = loop[-1][-1]
			if not words_by_first_letter.has(last_letter):
				break
			var candidates = words_by_first_letter[last_letter].filter(
				func(w): return w not in loop and w.length() >= min_word_length and w.length() <= max_word_length
			)
			if candidates.is_empty():
				break
			loop.append(candidates.pick_random())

		if loop.size() == loop_size and loop[-1][-1] == loop[0][0]:
			return loop

		tries -= 1

	return []  # Fallback if no loop found

func get_level_words() -> Array:
	var loop = create_valid_loop()
	if loop.is_empty():
		loop = create_valid_loop()

		if loop.is_empty():
			#push_warning("Could not generate a valid word loop for level.")
			print("Could not generate a valid word loop for level.")
			return []

	var result = loop.duplicate()
	while result.size() < total_words:
		var word = filtered_words.pick_random()
		if word not in result:
			result.append(word)

	result.shuffle()
	return result
