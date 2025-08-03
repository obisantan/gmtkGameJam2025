### GLOBAL PRELOAD - Utils
extends Node

############################
var debugging: bool = false
############################

enum Location {POOL, LOOP}
enum ButtonType {
	RESTART, # start game in main menu, or restart game in game_over/you_won screen
	SHUFFLE, # shuffle the words ingame
	RESET, # reset the loop ingame
	SUBMIT, # submit loop ingame
	MAIN_MENU, # return to main menu from are_you_sure/game_over/you_won screen
	ARE_YOU_SURE, # go to are you sure screen ingame
	HOW_TO_PLAY, # go to how to play in main menu
	CREDITS, # go to credits in main menu
	BACK # return from are_you_sure screen ingame, or return from how_to_play/credits screen in menu
}

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
