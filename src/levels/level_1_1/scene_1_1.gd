extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var player_camera: Camera3D = $Player/Head/Camera3D
@onready var cutscene_camera: Camera3D = $CutsceneCamera
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var video_player: VideoStreamPlayer = $CutsceneCamera/VideoStreamPlayer
@onready var canvas: CanvasLayer =$AnimationPlayer/CanvasLayer
@onready var intro: CanvasLayer = $Intro   # the new intro canvas
@onready var  rain_sound = $rain_sound
func _ready():
	rain_sound.play()
	# Start by showing the intro and waiting for it to finish
	if intro:
		intro.intro_finished.connect(_on_intro_finished)
		# The intro will handle its own display/fade
	else:
		# If no intro, just start cutscene immediately
		start_cutscene()


func _on_intro_finished():
	start_cutscene()


func start_cutscene():
	# Disable player controls and switch cameras
	player.can_move = false
	player_camera.current = false
	cutscene_camera.current = true

	# Check if video and animation exist
	var has_video = video_player and video_player.stream
	var has_animation = animation_player and animation_player.has_animation("awake")

	# Start both at the same time
	if has_video:
		video_player.play()
	if has_animation:
		animation_player.play("awake")

	# Wait for the video to finish (if any)
	if has_video:
		await video_player.finished
		# Hide and remove the video player immediately
		video_player.visible = false
		canvas.visible = false
		canvas.queue_free()
		video_player.queue_free()
		video_player = null

	# Wait for the animation to finish (if any)
	if has_animation:
		await animation_player.animation_finished

	# End the cutscene
	end_cutscene()

func end_cutscene():
	# Switch back to player camera
	cutscene_camera.current = false
	player_camera.current = true

	# Re-enable player controls
	player.can_move = true

	# Optional: free the cutscene camera if not reused
	# cutscene_camera.queue_free()


func _on_intro_intro_finished() -> void:
	pass # Replace with function body.


func _on_radio_interact_first_interaction_occurred() -> void:
	pass # Replace with function body.
