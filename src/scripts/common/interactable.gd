extends StaticBody3D  # or Area3D, CharacterBody3D, etc.

# Optional: if you want to keep the is_active toggle (e.g., for other purposes)
var is_active = false

func interact():
	# Get a reference to the AudioStreamPlayer3D node.
	# Adjust the node path if you named it differently.
	var audio_player = $radio_shape/AudioStreamPlayer3D
	
	# If the audio player isn't found, print an error.
	if not audio_player:
		print("Error: AudioStreamPlayer node not found!")
		return
	
	# Toggle playback
	if audio_player.playing:
		audio_player.stop()
		print("Music stopped")
	else:
		audio_player.play()
		print("Music started")
	
	# (Optional) Update your is_active variable if needed.
	is_active = audio_player.playing
