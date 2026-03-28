extends StaticBody3D

@export var radio: Radio                     # Must have class_name Radio in radio script
@export var picture_texture: Texture2D       # The image to display
@export var close_with_interact: bool = true # Also close with Escape
@export var red_light: OmniLight3D           # The red light that turns on during event

# Two separate sounds:
@export var immediate_scary_sound: AudioStream   # Plays right when event starts
@export var delayed_scary_sound: AudioStream     # Plays after 25 seconds (was scary_sound_25s)

@export var audio_player: AudioStreamPlayer3D   # For playing both sounds

var event_triggered := false
var timer_30s: Timer
var timer_25s: Timer   # Restored for the delayed sound

var is_open: bool = false
var player: CharacterBody3D = null
var ui_layer: CanvasLayer
var picture_panel: Panel
var texture_rect: TextureRect

func _ready():
	# Create the UI overlay
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	# Panel that covers most of the screen
	picture_panel = Panel.new()
	picture_panel.anchor_left = 0.1
	picture_panel.anchor_right = 0.9
	picture_panel.anchor_top = 0.1
	picture_panel.anchor_bottom = 0.9
	picture_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	picture_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# TextureRect to display the image
	texture_rect = TextureRect.new()
	texture_rect.anchor_left = 0.05
	texture_rect.anchor_right = 0.95
	texture_rect.anchor_top = 0.05
	texture_rect.anchor_bottom = 0.95
	texture_rect.texture = picture_texture
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	picture_panel.add_child(texture_rect)
	ui_layer.add_child(picture_panel)
	picture_panel.hide()
	
	# Find the player (assumed to be in group "player")
	player = get_tree().get_first_node_in_group("player")
	
	# Create timers
	timer_30s = Timer.new()
	timer_30s.one_shot = true
	timer_30s.timeout.connect(_on_30s_timeout)
	add_child(timer_30s)
	
	timer_25s = Timer.new()          # Re‑added for delayed sound
	timer_25s.one_shot = true
	timer_25s.timeout.connect(_on_25s_timeout)
	add_child(timer_25s)
	
	# Ensure audio player exists
	if not audio_player:
		audio_player = AudioStreamPlayer3D.new()
		add_child(audio_player)
	
	# Make sure red light starts off
	if red_light:
		red_light.visible = false

func interact():
	"""Called by the player's raycast when pressing interact."""
	if is_open:
		return
	open_picture()

func open_picture():
	is_open = true
	picture_panel.show()
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_picture():
	if not is_open:
		return
	is_open = false
	picture_panel.hide()
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Start the horror event only once, when the picture is first closed
	if not event_triggered:
		_start_event()

func _input(event):
	if is_open:
		if (close_with_interact and event.is_action_pressed("interact")) or event.is_action_pressed("ui_cancel"):
			close_picture()
			get_viewport().set_input_as_handled()

# ---------- Event helper functions ----------
func _start_event():
	event_triggered = true
	if audio_player:
		audio_player.volume_db = 22.0
	
	# 1. Radio switches to scary song
	if radio and radio.has_method("start_scary_event"):
		radio.start_scary_event()
	
	# 2. Play the immediate scary sound
	if immediate_scary_sound and audio_player:
		audio_player.stream = immediate_scary_sound
		audio_player.play()
	
	# 3. Turn off all lights except the red light
	_toggle_all_lights(false)
	
	# 4. Turn on red light
	if red_light:
		red_light.visible = true
	
	# 5. Start 25‑second timer for delayed sound
	timer_25s.start(25.0)
	
	# 6. Start 30‑second timer to revert
	timer_30s.start(30.0)

func _toggle_all_lights(on: bool):
	"""Turn all lights in group 'lights' on or off, except the red light."""
	var lights = get_tree().get_nodes_in_group("lights")
	for light in lights:
		if light != red_light:
			light.visible = on

func _on_25s_timeout():
	"""Called after 25 seconds – play the delayed scary sound."""
	if delayed_scary_sound and audio_player:
		audio_player.stream = delayed_scary_sound
		audio_player.play()

func _on_30s_timeout():
	"""Called after 30 seconds – revert everything back to normal."""
	# Turn off red light
	if red_light:
		red_light.visible = false
	
	# Turn all normal lights back on
	_toggle_all_lights(true)
	
	# Tell radio to go back to normal
	if radio and radio.has_method("end_scary_event"):
		radio.end_scary_event()
