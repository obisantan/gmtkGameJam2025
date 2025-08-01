### GLOBAL PRELOAD - DictionaryManager
extends Node

# Parameters for difficulty tuning
var total_words := 15  # Total number of words in a level
var loop_size_range := Vector2i(4, 6)  # Min and max length of the valid loop
var min_word_length := 4
var max_word_length := 10

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

func create_valid_loop() -> Array[String]:
	var loop: Array[String] = []
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

func get_level_words() -> Array[String]:
	var loop = create_valid_loop()
	if loop.is_empty():
		loop = create_valid_loop()

		if loop.is_empty():
			print("Could not generate a valid word loop for level.")
			return []

	var result := loop.duplicate()
	while result.size() < total_words:
		var word = filtered_words.pick_random()
		if word not in result:
			result.append(word)

	result.shuffle()
	return result

func refill_word_pool(previously_used_words: Array[String], existing_words: Array[String], amount_needed: int) -> Array[String]:
	var candidates: Array[String] = []
	var banned_words := previously_used_words + existing_words

	# Start from words not previously used or already on screen
	for word in filtered_words:
		if not banned_words.has(word):
			candidates.append(word)

	var tries := 100
	while tries > 0:
		var new_words : Array[String] = []
		var shuffled := candidates.duplicate()
		shuffled.shuffle()

		for i in range(min(amount_needed, shuffled.size())):
			new_words.append(shuffled[i])

		var test_pool: Array[String] = existing_words + new_words
		if has_valid_loop(test_pool):
			return new_words  # ✅ Success

		tries -= 1

	push_error("❌ DictionaryManager: Couldn't generate valid new words for pool.")
	return []  # fallback — better than crash

func has_valid_loop(words: Array[String]) -> bool:
	var map := {}  # first letter → list of words
	for word in words:
		var first = word[0]
		if not map.has(first):
			map[first] = []
		map[first].append(word)

	for word in words:
		var visited : Array[String] = [word]
		if _search_loop(word, word, words, visited, map):
			return true

	return false

func _search_loop(start_word: String, current_word: String, all_words: Array[String], visited: Array[String], map: Dictionary) -> bool:
	if visited.size() >= 3 and current_word[-1] == start_word[0]:
		return true  # loop complete

	var next_candidates = map.get(current_word[-1])
	if next_candidates == null:
		return false

	for next_word in next_candidates:
		if not visited.has(next_word):
			visited.append(next_word)
			if _search_loop(start_word, next_word, all_words, visited, map):
				return true
			visited.pop_back()

	return false
