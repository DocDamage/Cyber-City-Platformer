extends SceneTree

const TEST_BODY_SCRIPT := preload("res://tests/fixtures/GravityTestBody.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(20.0, true, false, true).timeout.connect(func() -> void:
		push_error("Stage mechanics test timed out.")
		quit(1)
	)
	var world := Node2D.new()
	root.add_child(world)

	var platform := MovingPlatform.new()
	platform.path_points = PackedVector2Array([Vector2.ZERO, Vector2(120, -40), Vector2(240, 0)])
	platform.path_mode = MovingPlatform.PathMode.LOOP
	platform.wait_time = 0.1
	world.add_child(platform)
	await physics_frame
	if not _require(platform.get_route_points().size() == 3, "Moving platform did not retain its authored loop path."):
		return
	platform.position = Vector2(75, 30)
	platform.reset_platform()
	if not _require(platform.position == Vector2.ZERO, "Moving platform reset is not deterministic."):
		return

	var conveyor := Conveyor.new()
	conveyor.speed = 150.0
	conveyor.reversible = true
	conveyor.reverse_interval = 0.5
	conveyor.hazardous = true
	world.add_child(conveyor)
	await physics_frame
	if not _require(conveyor.constant_linear_velocity.x == 150.0 and conveyor.get_node_or_null("BeltHazard") is Hazard, "Hazard conveyor is incomplete."):
		return
	conveyor.reverse()
	if not _require(conveyor.constant_linear_velocity.x == -150.0, "Conveyor did not reverse predictably."):
		return
	conveyor.reset_conveyor()
	if not _require(conveyor.constant_linear_velocity.x == 150.0, "Conveyor reset did not restore its direction."):
		return

	var hazard_types: Array[Node] = [LaserGrid.new(), SteamVent.new(), ElectricalFloor.new(), ToxicPool.new(), VoidPit.new(), FallingHazard.new(), CrusherHazard.new(), RotatingLaser.new()]
	for hazard: Node in hazard_types:
		world.add_child(hazard)
	await physics_frame
	for hazard: Node in hazard_types:
		if not _require(hazard.is_in_group(&"hazards") or hazard.is_in_group(&"falling_hazards") or hazard.is_in_group(&"crushers") or hazard.is_in_group(&"rotating_lasers"), "Hazard implementation is not independently registered: %s" % hazard.get_class()):
			return
	var void_pit := hazard_types[4] as VoidPit
	if not _require(void_pit.instant_kill and void_pit.hazard_id == &"void_pit", "Void pit is not an instant-death implementation."):
		return
	var steam := hazard_types[1] as SteamVent
	if not _require(steam.knockback.y < -250.0 and steam.telegraph_duration > 0.0, "Steam vent lacks upward knockback or telegraphing."):
		return

	var body := CharacterBody2D.new()
	body.set_script(TEST_BODY_SCRIPT)
	world.add_child(body)
	var zone := GravityZone.new()
	zone.gravity_multiplier = -0.4
	world.add_child(zone)
	await physics_frame
	zone.call(&"_on_body_entered", body)
	if not _require(is_equal_approx(float(body.get("gravity_multiplier")), -0.4), "Gravity zone did not affect a compatible body."):
		return
	body.emit_signal(&"died")
	if not _require(is_equal_approx(float(body.get("gravity_multiplier")), 1.0), "Gravity remained modified after death."):
		return

	var gate := SecurityGate.new()
	gate.required_switches = 2
	world.add_child(gate)
	await physics_frame
	gate.request_open(&"switch_a")
	if not _require(not gate.is_open, "Multi-switch gate opened before all switches were active."):
		return
	gate.request_open(&"switch_b")
	if not _require(gate.is_open, "Multi-switch gate did not open after all switches were active."):
		return

	var linked_gate := SecurityGate.new()
	world.add_child(linked_gate)
	var terminal := InteractiveTerminal.new()
	terminal.terminal_id = &"test_terminal"
	terminal.link_target(linked_gate)
	world.add_child(terminal)
	await physics_frame
	terminal.activate()
	if not _require(terminal.is_activated() and linked_gate.is_open, "Terminal did not activate its linked gate."):
		return

	var turret := SecurityTurret.new()
	turret.fire_mode = SecurityTurret.FireMode.BURST
	turret.destructible = true
	turret.max_health = 2
	world.add_child(turret)
	await physics_frame
	if not _require(turret.take_damage(1) and turret.is_enabled(), "Destructible turret rejected damage."):
		return
	turret.take_damage(1)
	if not _require(not turret.is_enabled(), "Destructible turret did not remain disabled after destruction."):
		return

	print("STAGE_MECHANICS_TEST_OK hazards=8 platform_points=3 gate_switches=2")
	world.queue_free()
	await process_frame
	quit()


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
