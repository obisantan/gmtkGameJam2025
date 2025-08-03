### GLOBAL PRELOAD - DictionaryManager
extends Node

# WORD SETTINGS
var amount_of_words_per_level := 15  # Total number of words in a level
var min_word_length := 3
var max_word_length := 9

# LOOP SETTINGS
var loop_size_range := Vector2i(3, 15)  # Min and max length of the valid loop
var target_loop_count := 3  # How many valid loops to guarantee in each level
var target_loops_on_refill := 3  # How many valid loops to include in refills

# WORD STORAGE
var all_words: Array[String] = []
var filtered_words: Array[String] = []
var words_by_first_letter := {}
var full_word_graph: Dictionary = {}  # word → [words that follow it]

func _ready():
	load_words("res://dictionary/nouns.txt")

# LOAD AND PREPROCESS WORDS
func load_words(path: String):
	all_words.clear()
	filtered_words.clear()
	words_by_first_letter.clear()

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open dictionary file: %s" % path)
		return

	while not file.eof_reached():
		var word = file.get_line().strip_edges().to_lower()
		if word.length() >= min_word_length and word.length() <= max_word_length:
			filtered_words.append(word)
			var first = word[0]
			if not words_by_first_letter.has(first):
				words_by_first_letter[first] = []
			words_by_first_letter[first].append(word)

	file.close()
	full_word_graph = build_word_graph(filtered_words)

# GRAPH GENERATION
func build_word_graph(words: Array[String]) -> Dictionary:
	var graph := {}
	var index_by_letter := {}

	for word in words:
		var first = word[0]
		if not index_by_letter.has(first):
			index_by_letter[first] = []
		index_by_letter[first].append(word)

	for word in words:
		var last = word[-1]
		if index_by_letter.has(last):
			graph[word] = index_by_letter[last].filter(func(w): return w != word)
		else:
			graph[word] = []

	return graph

# FAST LOOP CHECK
func has_valid_loop(words: Array[String], min_length: int = 3) -> bool:
	var graph: Dictionary = {}

	# Fast path — use cached graph if checking full list
	if words.size() == filtered_words.size():
		graph = full_word_graph
	else:
		graph = {}
		for word in words:
			graph[word] = []
			var last = word[-1]
			for candidate in words:
				if candidate != word and candidate[0] == last:
					graph[word].append(candidate)

	for start_word in graph.keys():
		var stack = [[start_word, [start_word]]]

		while not stack.is_empty():
			var item = stack.pop_back()
			var current = item[0]
			var path = item[1]

			if path.size() >= min_length and path[-1][-1] == path[0][0]:
				return true

			for neighbor in graph.get(current, []):
				if neighbor not in path:
					stack.append([neighbor, path + [neighbor]])

	return false

# LOOP GENERATOR USING GRAPH
func create_valid_loop(loop_graph: Dictionary, loop_size: int) -> Array[String]:
	var candidates = loop_graph.keys()
	var tries = 100

	while tries > 0:
		var path: Array[String] = []
		var start = candidates.pick_random()
		path.append(start)

		while path.size() < loop_size:
			var last = path[-1]
			var next_candidates = loop_graph.get(last, []).filter(func(w): return w not in path)
			if next_candidates.is_empty():
				break
			path.append(next_candidates.pick_random())

		if path.size() == loop_size and path[-1][-1] == path[0][0]:
			return path

		tries -= 1

	return []

func get_level_words() -> Array[String]:
	var result: Array[String] = []
	var used_words: = {}
	var slots_remaining := amount_of_words_per_level
	var loops_found := 0
	var loop_attempts := 100

	while loops_found < target_loop_count and loop_attempts > 0 and slots_remaining > 0:
		var loop_size = randi_range(loop_size_range.x, loop_size_range.y)
		var loop = create_valid_loop(full_word_graph, loop_size)

		if loop.is_empty():
			loop_attempts -= 1
			continue

		var new_words = loop.filter(func(w): return not used_words.has(w))
		if new_words.size() > slots_remaining:
			loop_attempts -= 1
			continue

		for word in new_words:
			used_words[word] = true
			result.append(word)

		slots_remaining -= new_words.size()
		loops_found += 1

	if loops_found < target_loop_count:
		push_warning("Only %d loops generated (target: %d)" % [loops_found, target_loop_count])

	# Add distractors
	var distractors := filtered_words.filter(func(w): return not used_words.has(w))
	distractors.shuffle()

	for word in distractors:
		if result.size() >= amount_of_words_per_level:
			break
		result.append(word)
		used_words[word] = true

	result.shuffle()
	return result

func refill_word_pool(previously_used_words: Array[String], existing_words: Array[String], amount_needed: int) -> Array[String]:
	var banned := previously_used_words + existing_words
	var result: Array[String] = []
	var used_words := {}
	for word in banned:
		used_words[word] = true

	var slots_remaining := amount_needed
	var loops_found := 0
	var loop_attempts := 100

	while loops_found < target_loops_on_refill and loop_attempts > 0 and slots_remaining > 0:
		var loop_size = randi_range(loop_size_range.x, loop_size_range.y)
		var loop = create_valid_loop(full_word_graph, loop_size)

		if loop.is_empty():
			loop_attempts -= 1
			continue

		var new_words = loop.filter(func(w): return not used_words.has(w))
		if new_words.size() > slots_remaining:
			loop_attempts -= 1
			continue

		for word in new_words:
			used_words[word] = true
			result.append(word)

		slots_remaining -= new_words.size()
		loops_found += 1

	if loops_found < target_loops_on_refill:
		push_warning("Refill: Only %d loop(s) generated (target: %d)" % [loops_found, target_loops_on_refill])

	var distractors := filtered_words.filter(func(w): return not used_words.has(w))
	distractors.shuffle()

	for word in distractors:
		if result.size() >= amount_needed:
			break
		result.append(word)
		used_words[word] = true

	var test_pool = existing_words + result
	if not has_valid_loop(test_pool):
		push_warning("❌ Refill pool may not be solvable.")
	else:
		print("✅ Refill: %d words added (%d loop(s))" % [result.size(), loops_found])

	return result
