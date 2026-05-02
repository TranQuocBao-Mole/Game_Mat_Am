extends CanvasLayer

signal fade_finished

@onready var rect = $ColorRect
@onready var anim = $AnimationPlayer

func _ready():
	rect.color.a = 0
	rect.visible = false

func fade_to_black(duration: float = 1.0):
	rect.visible = true
	var tween = create_tween()
	tween.tween_property(rect, "color:a", 1.0, duration)
	await tween.finished
	fade_finished.emit()

func fade_from_black(duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(rect, "color:a", 0.0, duration)
	await tween.finished
	rect.visible = false
	fade_finished.emit()
