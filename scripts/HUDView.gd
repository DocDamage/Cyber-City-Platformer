extends CanvasLayer

@onready var health_bar: ProgressBar = %HealthBar
@onready var health_value: Label = %HealthValue
@onready var ammo_bar: ProgressBar = %AmmoBar
@onready var ammo_value: Label = %AmmoValue
@onready var score_label: Label = %ScoreLabel
@onready var checkpoint_notice: Label = %CheckpointNotice
@onready var boss_panel: PanelContainer = %BossPanel
@onready var boss_name_label: Label = %BossName
@onready var boss_phase_label: Label = %BossPhase
@onready var boss_health_bar: ProgressBar = %BossHealthBar

var _manager: Node
var _notice_tween: Tween
var _boss: BossBase


func _ready() -> void:
	add_to_group(&"hud")
	boss_panel.visible = false
	_manager = get_node_or_null("/root/GameManager")
	if _manager == null:
		push_warning("HUD requires the GameManager autoload.")
		return

	_connect_manager_signal(&"player_health_changed", _on_health_changed)
	_connect_manager_signal(&"player_energy_changed", _on_energy_changed)
	_connect_manager_signal(&"score_changed", _on_score_changed)
	_connect_manager_signal(&"checkpoint_changed", _on_checkpoint_changed)
	_on_health_changed(maxi(_manager.get("player_health"), 0), maxi(_manager.get("player_max_health"), 1))
	_on_energy_changed(maxf(_manager.get("player_energy"), 0.0), maxf(_manager.get("player_max_energy"), 1.0))
	_on_score_changed(_manager.get("current_score"))
	_bind_existing_boss.call_deferred()


func _connect_manager_signal(signal_name: StringName, callable: Callable) -> void:
	if not _manager.is_connected(signal_name, callable):
		_manager.connect(signal_name, callable)


func _on_health_changed(current: int, maximum: int) -> void:
	var safe_maximum := maxi(maximum, 1)
	health_bar.max_value = safe_maximum
	health_bar.value = clampi(current, 0, safe_maximum)
	health_value.text = "%02d / %02d" % [current, safe_maximum]


func _on_energy_changed(current: float, maximum: float) -> void:
	var safe_maximum := maxf(maximum, 1.0)
	ammo_bar.max_value = safe_maximum
	ammo_bar.value = clampf(current, 0.0, safe_maximum)
	ammo_value.text = "%03d / %03d" % [roundi(current), roundi(safe_maximum)]


func _on_score_changed(total: int) -> void:
	score_label.text = "%06d" % maxi(total, 0)


func _on_checkpoint_changed(_checkpoint_id: StringName, _position: Vector2) -> void:
	checkpoint_notice.text = "CHECKPOINT SYNCHRONIZED"
	checkpoint_notice.modulate.a = 1.0
	if _notice_tween != null and _notice_tween.is_valid():
		_notice_tween.kill()
	_notice_tween = create_tween()
	_notice_tween.tween_interval(1.5)
	_notice_tween.tween_property(checkpoint_notice, "modulate:a", 0.0, 0.6)


func bind_boss(boss: BossBase) -> void:
	if boss == null or boss == _boss:
		return
	_boss = boss
	boss_name_label.text = boss.boss_name
	boss_phase_label.text = "PHASE %d" % boss.get_phase_number()
	boss_health_bar.max_value = boss.max_health
	boss_health_bar.value = boss.health
	_connect_boss_signal(&"encounter_started", _on_boss_encounter_started)
	_connect_boss_signal(&"health_changed", _on_boss_health_changed)
	_connect_boss_signal(&"phase_changed", _on_boss_phase_changed)
	_connect_boss_signal(&"boss_defeated", _on_boss_defeated)
	_connect_boss_signal(&"encounter_reset", _on_boss_encounter_reset)
	if boss.encounter_active:
		_on_boss_encounter_started()


func _bind_existing_boss() -> void:
	for node: Node in get_tree().get_nodes_in_group(&"bosses"):
		if node is BossBase and _shares_stage_root(node):
			bind_boss(node as BossBase)
			return


func _connect_boss_signal(signal_name: StringName, callable: Callable) -> void:
	if _boss != null and not _boss.is_connected(signal_name, callable):
		_boss.connect(signal_name, callable)


func _on_boss_encounter_started() -> void:
	boss_panel.visible = true
	boss_panel.modulate.a = 0.0
	create_tween().tween_property(boss_panel, "modulate:a", 1.0, 0.28)


func _on_boss_health_changed(current: int, maximum: int, _percentage: float) -> void:
	boss_health_bar.max_value = maxi(maximum, 1)
	boss_health_bar.value = current


func _on_boss_phase_changed(_previous: BossBase.State, current: BossBase.State) -> void:
	boss_phase_label.text = "PHASE %d" % (int(current) + 1)
	boss_panel.modulate = Color(1.0, 0.45, 0.65)
	create_tween().tween_property(boss_panel, "modulate", Color.WHITE, 0.3)


func _on_boss_defeated() -> void:
	var tween := create_tween()
	tween.tween_interval(0.35)
	tween.tween_property(boss_panel, "modulate:a", 0.0, 0.4)
	await tween.finished
	boss_panel.visible = false


func _on_boss_encounter_reset() -> void:
	boss_panel.visible = false
	boss_panel.modulate.a = 1.0
	if _boss != null:
		boss_phase_label.text = "PHASE 1"
		boss_health_bar.value = _boss.max_health


func _shares_stage_root(other: Node) -> bool:
	return _top_level_scene_node(self) == _top_level_scene_node(other)


func _top_level_scene_node(node: Node) -> Node:
	var candidate := node
	while candidate.get_parent() != null and candidate.get_parent() != get_tree().root:
		candidate = candidate.get_parent()
	return candidate
