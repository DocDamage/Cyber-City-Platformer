extends SceneTree

const PLAYER_SCENE := preload("res://scenes/Player.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(12.0, true, false, true).timeout.connect(func() -> void:
		push_error("Teleport/weapon test timed out.")
		quit(1)
	)
	if not _require(WeaponCatalog.validate().is_empty(), "Weapon catalog validation failed."):
		return
	var sword := WeaponCatalog.attack_profile(&"sword", false, 1)
	var dagger := WeaponCatalog.attack_profile(&"dagger", false, 1)
	var spear := WeaponCatalog.attack_profile(&"spear", false, 1)
	var heavy := WeaponCatalog.attack_profile(&"heavy", false, 1)
	if not _require(float(dagger.startup) < float(sword.startup) and float(spear.hitbox[0]) > float(sword.hitbox[0]) and float(heavy.recovery) > float(sword.recovery), "Weapon families do not express distinct timing and reach."):
		return
	var manager := root.get_node("GameManager")
	manager.call(&"new_game")
	var arena := Node2D.new()
	arena.name = "TeleportArena"
	root.add_child(arena)
	_add_world_block(arena, Vector2(0.0, 100.0), Vector2(420.0, 20.0))
	_add_world_block(arena, Vector2(180.0, 50.0), Vector2(20.0, 120.0))
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	player.position = Vector2(0.0, 58.0)
	arena.add_child(player)
	for _frame: int in range(40):
		await physics_frame
	if not _require(player.is_on_floor(), "Teleport test player did not settle."):
		return
	var resolver: TeleportDestinationResolver = player.teleport_controller.resolver
	var floor_destination := resolver.resolve(Vector2(80.0, 90.0), Vector2.UP)
	if not _require(bool(floor_destination.valid) and Vector2(floor_destination.position).distance_to(Vector2(80.0, 58.0)) < 10.0, "Floor destination did not resolve with full-body clearance: %s" % floor_destination):
		return
	var blocked := resolver.validate_position(Vector2(80.0, 92.0))
	if not _require(not bool(blocked.valid), "Destination resolver accepted embedded geometry."):
		return
	var forbidden := Area2D.new()
	forbidden.add_to_group(&"teleport_forbidden")
	forbidden.collision_layer = 128
	forbidden.collision_mask = 0
	var forbidden_shape := CollisionShape2D.new()
	var forbidden_rectangle := RectangleShape2D.new()
	forbidden_rectangle.size = Vector2(40.0, 70.0)
	forbidden_shape.shape = forbidden_rectangle
	forbidden.add_child(forbidden_shape)
	forbidden.position = Vector2(-100.0, 58.0)
	arena.add_child(forbidden)
	await physics_frame
	var forbidden_result := resolver.validate_position(forbidden.position)
	if not _require(not bool(forbidden_result.valid) and StringName(forbidden_result.reason) == &"forbidden_volume", "Forbidden destination was not identified."):
		return
	var teleport: TeleportController = player.teleport_controller
	if not _require(teleport.begin_aim(Vector2.RIGHT) and teleport.throw_marker(), "Teleport marker could not be thrown."):
		return
	for _frame: int in range(40):
		await physics_frame
		if teleport.state == TeleportController.MarkerState.ATTACHED:
			break
	if not _require(teleport.state == TeleportController.MarkerState.ATTACHED and teleport.destination_valid, "Marker did not attach to a safe wall destination: %s" % teleport.rejection_reason):
		return
	var destination := teleport.destination
	if not _require(teleport.warp_to_marker(), "Safe marker destination could not be warped to."):
		return
	if not _require(player.global_position.distance_to(destination) < 1.0 and teleport.state == TeleportController.MarkerState.READY, "Warp did not finish at the validated destination."):
		return
	print("TELEPORT_WEAPON_TEST_OK families=6 destination=", destination, " blocked=", blocked.reason)
	player.queue_free()
	forbidden.queue_free()
	arena.queue_free()
	await process_frame
	CreatorAnimationCatalog.clear_runtime_cache()
	quit()


func _add_world_block(parent: Node2D, position: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = position
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
