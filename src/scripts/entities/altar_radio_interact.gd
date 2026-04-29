extends StaticBody3D

@export var prompt_text: String = "Tương tác với Radio"
@export var radio_sound: AudioStream = preload("res://assets/audio/scene3_sound_effect/siuuuuuuu-bass-boosted.mp3")

var audio_player: AudioStreamPlayer3D

func _ready() -> void:
	audio_player = AudioStreamPlayer3D.new()
	audio_player.stream = radio_sound
	audio_player.volume_db = 10.0 # Tăng âm lượng gấp khoảng 3 lần
	add_child(audio_player)
	audio_player.finished.connect(_on_audio_finished)

func interact() -> void:
	if not GameState.is_candle_puzzle_solved:
		DialogueManager.show_text("một chiếc radio cũ. Không biết nó còn sử dụng được không?")
	else:
		if not audio_player.playing:
			audio_player.play()
		print("444")

func _on_audio_finished() -> void:
	DialogueManager.show_text("Ôi giọng anh 7,")
	DialogueManager.show_text("tại sao radio lại phát đoạn thu âm này nhỉ?")
	DialogueManager.show_text("kì lạ thật.")
