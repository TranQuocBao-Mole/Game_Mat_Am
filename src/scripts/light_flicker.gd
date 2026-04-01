extends OmniLight3D

@export var flicker_intensity: float = 0.5
@export var flicker_speed: float = 10.0
@export var min_energy: float = 0.5
@export var max_energy: float = 2.0

var noise: FastNoiseLite = FastNoiseLite.new()
var time_passed: float = 0.0

func _ready() -> void:
	noise.seed = randi()
	noise.frequency = 0.2
	# Standard lantern colors are warm
	light_color = Color(1.0, 0.5, 0.2) # Warm orange/red

func _process(delta: float) -> void:
	time_passed += delta * flicker_speed
	var n = noise.get_noise_1d(time_passed)
	# n is between -1 and 1
	var target_energy = lerp(min_energy, max_energy, (n + 1.0) / 2.0)
	light_energy = target_energy
