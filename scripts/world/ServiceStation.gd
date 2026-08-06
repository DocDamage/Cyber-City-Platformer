class_name ServiceStation
extends Area2D

var service_type: StringName = &"barber"
var _nearby_player: Node2D
var _label: Label


func configure(data: Dictionary) -> void:
	service_type = StringName(data.get("type", "barber"))
	var values: Array = data.get("position", [480, 450])
	position = Vector2(float(values[0]), float(values[1]))


func _ready() -> void:
	add_to_group(&"world_services")
	collision_layer = 0
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 58.0
	collision.shape = shape
	add_child(collision)
	var kiosk := Polygon2D.new()
	kiosk.polygon = PackedVector2Array([Vector2(-28,-46),Vector2(28,-46),Vector2(34,35),Vector2(-34,35)])
	kiosk.color = Color("ff75c8") if service_type == &"barber" else Color("a879ff")
	add_child(kiosk)
	_label = Label.new()
	_label.position = Vector2(-42, -88)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.visible = false
	add_child(_label)
	_bind_prompt_updates()
	_refresh_prompt()
	body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group(&"player"):
			_nearby_player = body
			_label.visible = true
	)
	body_exited.connect(func(body: Node2D) -> void:
		if body == _nearby_player:
			_nearby_player = null
			_label.visible = false
	)


func _unhandled_input(event: InputEvent) -> void:
	if _nearby_player != null and event.is_action_pressed(&"interact"):
		var service := get_tree().get_first_node_in_group(&"customization_service") as CustomizationService
		if service != null:
			service.open(service_type)
		get_viewport().set_input_as_handled()


func _bind_prompt_updates() -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		return
	for signal_name: StringName in [&"input_device_changed", &"action_binding_changed"]:
		var callback := Callable(self, &"_refresh_prompt")
		if settings.has_signal(signal_name) and not settings.is_connected(signal_name, callback):
			settings.connect(signal_name, callback)


func _refresh_prompt(_unused: Variant = null) -> void:
	if _label == null:
		return
	var settings := get_node_or_null("/root/SettingsManager")
	var binding := String(settings.call(&"get_action_prompt", &"interact")) if settings != null else "INTERACT"
	_label.text = "%s\n[%s]" % [String(service_type).to_upper(), binding]
