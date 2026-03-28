# Intro.gd (attached to the CanvasLayer node)
extends CanvasLayer

signal intro_finished

@export var fade_duration := 5.0          # seconds to fade out
@export var wait_for_input := false       # if true, wait for any key to start fading

@onready var color_rect = $ColorRect

var fading := false
var timer := 0.0

func _ready():
	color_rect.color.a = 1.0   # start fully opaque
	if not wait_for_input:
		start_fade_out()

func start_fade_out():
	fading = true
	timer = fade_duration

func _process(delta):
	if fading:
		timer -= delta
		if timer <= 0:
			color_rect.color.a = 0.0
			fading = false
			intro_finished.emit()
			queue_free()        # remove the intro canvas completely
		else:
			color_rect.color.a = timer / fade_duration   # linear fade

func _input(event):
	if wait_for_input and not fading and event.is_pressed() and not event.is_echo():
		start_fade_out()
