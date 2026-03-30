class_name Radio
extends StaticBody3D
signal first_interaction_occurred()
@export var normal_song: AudioStream # The first, calm song
@export var scary_song: AudioStream # The song that plays during the event
@export var audio_player: AudioStreamPlayer3D # Assign a child AudioStreamPlayer3D

var first_interaction_done := false
var event_active := false
var prompt_text := "Bật Radio"

func _ready():
	# Ensure we have an audio player
	if not audio_player:
		audio_player = AudioStreamPlayer3D.new()
		add_child(audio_player)

func interact():
	"""Called by player when looking at radio and pressing interact."""
	if event_active:
		# Maybe show "The radio is crackling..." but we ignore further interaction during event
		return
	if not first_interaction_done:
		# First time: play the normal song
		first_interaction_done = true
		first_interaction_occurred.emit()
		audio_player.stream = normal_song
		audio_player.play()
		DialogueManager.show_text("Cái radio này...")
		DialogueManager.show_text("...nhạc nghe như con cặc đụ đĩ mẹ.")
		DialogueManager.show_text("Thằng Bảo chó rách.")
	else:
		# Subsequent interactions could be ignored or toggle on/off
		# For simplicity, we do nothing after the first time.
		pass

# Methods called by the paper to start the event
func start_scary_event():
		event_active = true
		audio_player.stop()
		audio_player.stream = scary_song
		audio_player.play()

func end_scary_event():
	event_active = false
	# Revert to normal song if it was played before
	if first_interaction_done:
		audio_player.stream = normal_song
		audio_player.play()
	else:
		audio_player.stop()
