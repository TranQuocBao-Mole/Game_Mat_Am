extends StaticBody3D

@export var audio_stream: AudioStream = preload("res://assets/audio/scene3_sound_effect/phonograph_audio.mp3")
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

var music_played: bool = false

func _ready():
	if not audio_player:
		audio_player = AudioStreamPlayer3D.new()
		add_child(audio_player)
	audio_player.stream = audio_stream

func interact():
	if audio_player.playing:
		audio_player.stop()
		DialogueManager.show_text("Bạn đã tắt máy hát.")
	else:
		audio_player.play()
		music_played = true
		DialogueManager.show_text("Tiếng nhạc cũ kỹ vang lên từ chiếc máy hát...")
