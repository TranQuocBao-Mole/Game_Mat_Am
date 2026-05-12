extends Node3D

@export var rain_particles: GPUParticles3D
@export var rain_sound: AudioStreamPlayer3D

func _ready():
	add_to_group("weather_manager")
	if rain_particles:
		rain_particles.emitting = false
	if rain_sound:
		rain_sound.stream_paused = true

func _process(_delta):
	if GameState.is_raining:
		var should_emit = not GameState.is_player_inside
		
		if rain_particles and rain_particles.emitting != should_emit:
			rain_particles.emitting = should_emit
		
		if rain_sound:
			if should_emit:
				if not rain_sound.playing:
					rain_sound.play()
				rain_sound.stream_paused = false
			else:
				rain_sound.stream_paused = true
	else:
		if rain_particles:
			rain_particles.emitting = false
		if rain_sound and rain_sound.playing:
			rain_sound.stop()
