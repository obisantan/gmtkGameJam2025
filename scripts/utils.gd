### GLOBAL PRELOAD - Utils
extends Node

enum Location {POOL, LOOP}
enum ButtonType {RESTART, SHUFFLE, RESET, SUBMIT}
var debugging: bool = true

### points and loop number tracking
var this_run_total_points: int = 0
var this_run_best_loop_score: int = 0
var this_run_best_loop_word_amount: int = 0
var this_run_highest_level_reached: int = 1
var this_run_total_loops_submitted: int = 0

## TODO: persist highscores in file
var highscore_total_points: int = 0
var highscore_best_loop_score: int = 0
var highscore_best_loop_word_amount: int = 0
var highscore_highest_level_reached: int = 1
var highscore_total_loops_submitted: int = 0

var highscore_amount_of_wins: int = 0
var highscore_fastest_level_played
var highscore_fastest_win



func print_current_loop(loop: Array[Word]):
	print("=== CURRENT LOOP ===")
	for i in loop.size():
		print("%s: %s" % [i, loop[i].word])
