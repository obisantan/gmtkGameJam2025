### GLOBAL PRELOAD - Utils
extends Node

signal event_button_pressed_reset
signal event_button_pressed_restart
signal event_button_pressed_shuffle

enum Location {
	POOL,
	LOOP
}



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func print_current_loop(loop: Array[Word]):
	print("=== CURRENT LOOP ===")
	for i in loop.size():
		print("%s: %s" % [i, loop[i].word])
