class_name YouWonScreen
extends CanvasLayer

@onready var final_score_label := %FinalScoreLabel
@onready var highest_level_reached_label := %HighestLevelLabel
@onready var total_loops_label := %TotalLoopsLabel
@onready var best_loop_label := %BestLoopLabel

@onready var restart_button := %RestartButton

func _ready():
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	final_score_label.text = "Final Score: %s" % Utils.this_run_total_points
	highest_level_reached_label.text = "You beat all %s levels" % Utils.this_run_highest_level_reached
	total_loops_label.text = "And submitted %s %s" % [Utils.this_run_total_loops_submitted, "loop" if Utils.this_run_total_loops_submitted == 1 else "loops"]
	best_loop_label.text = "Best Loop: %s words, %s points" % [Utils.this_run_best_loop_word_amount, Utils.this_run_best_loop_score]
