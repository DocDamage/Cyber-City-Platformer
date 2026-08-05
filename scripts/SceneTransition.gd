extends CanvasLayer

signal fade_out_finished
signal fade_in_finished

@onready var fade_rect: ColorRect = $FadeRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _animating := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.color.a = 0.0


func fade_out() -> void:
	if _animating:
		await animation_player.animation_finished
	_animating = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	animation_player.play(&"fade_out")
	await animation_player.animation_finished
	_animating = false
	fade_out_finished.emit()


func fade_in() -> void:
	if _animating:
		await animation_player.animation_finished
	_animating = true
	animation_player.play(&"fade_in")
	await animation_player.animation_finished
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_animating = false
	fade_in_finished.emit()
