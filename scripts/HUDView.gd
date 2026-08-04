extends Control

const COIN_FRAMES: Array[Texture2D] = [
	preload("res://assets/Stages/Cyber City/Cyber City/Prop/Coin/coin1.png"),
	preload("res://assets/Stages/Cyber City/Cyber City/Prop/Coin/coin2.png"),
	preload("res://assets/Stages/Cyber City/Cyber City/Prop/Coin/coin3.png"),
	preload("res://assets/Stages/Cyber City/Cyber City/Prop/Coin/coin4.png"),
	preload("res://assets/Stages/Cyber City/Cyber City/Prop/Coin/coin5.png"),
	preload("res://assets/Stages/Cyber City/Cyber City/Prop/Coin/coin6.png"),
	preload("res://assets/Stages/Cyber City/Cyber City/Prop/Coin/coin7.png"),
	preload("res://assets/Stages/Cyber City/Cyber City/Prop/Coin/coin8.png"),
]

var _health := 1
var _max_health := 1
var _energy := 0.0
var _max_energy := 100.0
var _score := 0
var _elapsed := 0.0
var _coin_frame := 0
var _checkpoint_message := ""
var _checkpoint_message_time := 0.0
var _damage_flash := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var manager := get_node_or_null("/root/GameManager")
	if manager == null:
		return
	manager.connect("player_health_changed", _on_health_changed)
	manager.connect("player_energy_changed", _on_energy_changed)
	manager.connect("score_changed", _on_score_changed)
	manager.connect("checkpoint_changed", _on_checkpoint_changed)
	_on_health_changed(maxi(manager.get("player_health"), 0), maxi(manager.get("player_max_health"), 1))
	_on_energy_changed(maxf(manager.get("player_energy"), 0.0), maxf(manager.get("player_max_energy"), 1.0))
	_on_score_changed(manager.get("current_score"))


func _process(delta: float) -> void:
	_elapsed += delta
	_damage_flash = maxf(_damage_flash - delta, 0.0)
	_checkpoint_message_time = maxf(_checkpoint_message_time - delta, 0.0)
	_coin_frame = int(_elapsed * 12.0) % COIN_FRAMES.size()
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	_draw_status_panel(font)
	_draw_score_panel(font)
	if _checkpoint_message_time > 0.0:
		_draw_checkpoint_notice(font)


func _draw_status_panel(font: Font) -> void:
	var panel := Rect2(20.0, 18.0, 278.0, 139.0)
	_draw_panel(panel, Color("10dff5"))
	draw_string(font, Vector2(37.0, 42.0), "VITAL INTEGRITY", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("83f6ff"))
	draw_string(font, Vector2(263.0, 42.0), "%02d" % _health, HORIZONTAL_ALIGNMENT_RIGHT, 24, 15, Color.WHITE)

	var gap := 5.0
	var available := 238.0
	var segment_width := (available - gap * (_max_health - 1)) / _max_health
	for index in range(_max_health):
		var rect := Rect2(38.0 + index * (segment_width + gap), 52.0, segment_width, 25.0)
		draw_rect(rect, Color(0.02, 0.11, 0.16, 0.92), true)
		draw_rect(rect, Color("276479"), false, 1.0)
		if index < _health:
			var color := Color("ff2f88") if _health <= ceili(_max_health * 0.4) else Color("28efff")
			if _damage_flash > 0.0:
				color = Color.WHITE
			draw_rect(rect.grow(-3.0), color, true)
			draw_rect(Rect2(rect.position + Vector2(3.0, 3.0), Vector2(rect.size.x - 6.0, 3.0)), Color(1, 1, 1, 0.6), true)

	draw_string(font, Vector2(37.0, 101.0), "DASH / WEAPON ENERGY", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("b38cff"))
	var lit_segments := ceili((_energy / _max_energy) * 12.0)
	for index in range(12):
		var energy_rect := Rect2(38.0 + index * 19.8, 111.0, 14.5, 20.0)
		draw_rect(energy_rect, Color(0.04, 0.06, 0.15, 0.94), true)
		if index < lit_segments:
			var glow := 0.85 + sin(_elapsed * 5.0 + index * 0.35) * 0.15
			draw_rect(energy_rect.grow(-2.0), Color(0.55, 0.28, 1.0, glow), true)
	_draw_scanline(panel)


func _draw_score_panel(font: Font) -> void:
	var panel := Rect2(size.x - 224.0, 18.0, 204.0, 70.0)
	_draw_panel(panel, Color("ff2f91"))
	var texture := COIN_FRAMES[_coin_frame]
	draw_texture_rect(texture, Rect2(panel.position + Vector2(15.0, 15.0), Vector2(40.0, 40.0)), false)
	draw_string(font, panel.position + Vector2(65.0, 28.0), "CREDITS", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ff91c2"))
	draw_string(font, panel.position + Vector2(65.0, 52.0), "%06d" % _score, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	_draw_scanline(panel)


func _draw_checkpoint_notice(font: Font) -> void:
	var alpha := clampf(_checkpoint_message_time * 2.0, 0.0, 1.0)
	var notice := Rect2(size.x * 0.5 - 130.0, 37.0, 260.0, 46.0)
	draw_rect(notice, Color(0.02, 0.08, 0.1, 0.9 * alpha), true)
	draw_rect(notice, Color(0.3, 1.0, 0.68, alpha), false, 2.0)
	draw_string(font, notice.position + Vector2(0.0, 29.0), _checkpoint_message, HORIZONTAL_ALIGNMENT_CENTER, notice.size.x, 16, Color(0.55, 1.0, 0.78, alpha))


func _draw_panel(rect: Rect2, accent: Color) -> void:
	draw_rect(rect, Color(0.015, 0.035, 0.075, 0.88), true)
	draw_rect(rect, Color(accent, 0.85), false, 2.0)
	draw_line(rect.position + Vector2(0.0, 7.0), rect.position + Vector2(7.0, 0.0), accent, 2.0)
	draw_line(rect.end - Vector2(0.0, 7.0), rect.end - Vector2(7.0, 0.0), accent, 2.0)


func _draw_scanline(rect: Rect2) -> void:
	var y := rect.position.y + fmod(_elapsed * 23.0, rect.size.y)
	draw_line(Vector2(rect.position.x + 2.0, y), Vector2(rect.end.x - 2.0, y), Color(0.3, 0.95, 1.0, 0.08), 1.0)


func _on_health_changed(current: int, maximum: int) -> void:
	if current < _health:
		_damage_flash = 0.2
	_health = current
	_max_health = maxi(maximum, 1)
	queue_redraw()


func _on_energy_changed(current: float, maximum: float) -> void:
	_energy = current
	_max_energy = maxf(maximum, 1.0)
	queue_redraw()


func _on_score_changed(total: int) -> void:
	_score = total
	queue_redraw()


func _on_checkpoint_changed(_checkpoint_id: StringName, _position: Vector2) -> void:
	_checkpoint_message = "CHECKPOINT SYNCHRONIZED"
	_checkpoint_message_time = 2.4
