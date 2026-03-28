extends OmniLight3D

# Thunder timing
@export var min_interval: float = 5.0
@export var max_interval: float = 15.0

# Flash properties
@export var flash_duration: float = 1.0
@export var flash_energy: float = 100.0

# Sound
@export var sound_player: AudioStreamPlayer3D

var next_flash_time: float = 0.0
var flash_remaining: float = 0.0
var rng = RandomNumberGenerator.new()

func _ready():
	print("Lightning effect ready")
	rng.randomize()
	light_energy = 0.0
	next_flash_time = rng.randf_range(min_interval, max_interval)
	
	# Check sound setup
	if sound_player:
		if sound_player.stream == null:
			push_warning("Thunder sound player has no audio stream assigned!")
	else:
		push_warning("No sound player assigned! Thunder will be silent.")

func _process(delta):
	next_flash_time -= delta
	
	if flash_remaining > 0:
		flash_remaining -= delta
		if flash_remaining <= 0:
			light_energy = 0.0
	
	if next_flash_time <= 0 and flash_remaining <= 0:
		start_flash()
		next_flash_time = rng.randf_range(min_interval, max_interval)

func start_flash():
	light_energy = flash_energy
	flash_remaining = flash_duration
	
	if sound_player and sound_player.stream:
		sound_player.play()
