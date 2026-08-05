class_name EnemyAttackController
extends Node

signal attack_committed(kind: StringName)
signal recovery_started
signal attack_finished

var _generation := 0


func start_attack(kind: StringName, telegraph_time: float, active_time: float, recovery_time: float) -> void:
	_generation += 1
	var generation := _generation
	_run_attack(kind, telegraph_time, active_time, recovery_time, generation)


func cancel() -> void:
	_generation += 1


func _run_attack(kind: StringName, telegraph_time: float, active_time: float, recovery_time: float, generation: int) -> void:
	await get_tree().create_timer(maxf(telegraph_time, 0.01)).timeout
	if generation != _generation:
		return
	attack_committed.emit(kind)
	await get_tree().create_timer(maxf(active_time, 0.01)).timeout
	if generation != _generation:
		return
	recovery_started.emit()
	await get_tree().create_timer(maxf(recovery_time, 0.01)).timeout
	if generation == _generation:
		attack_finished.emit()
