class_name QuestDatabase
extends RefCounted

const DATA_PATH := "res://data/narrative/quests.json"
const EVENT_TYPES := [&"story_flag", &"item", &"ability", &"warp"]

static var _payload: Dictionary = {}


static func definitions() -> Dictionary:
	_ensure_loaded()
	return (_payload.get("quests", {}) as Dictionary).duplicate(true)


static func definition(quest_id: StringName) -> Dictionary:
	_ensure_loaded()
	return ((_payload.get("quests", {}) as Dictionary).get(String(quest_id), {}) as Dictionary).duplicate(true)


static func validate() -> PackedStringArray:
	_ensure_loaded()
	var errors := PackedStringArray()
	if int(_payload.get("schema_version", 0)) != 1:
		errors.append("Quest database schema_version must be 1.")
	var quests: Dictionary = _payload.get("quests", {})
	if quests.is_empty():
		errors.append("Quest database has no quests.")
		return errors
	for quest_key: Variant in quests:
		var quest_id := String(quest_key)
		var quest: Dictionary = quests[quest_key]
		if quest_id.is_empty() or String(quest.get("title", "")).is_empty():
			errors.append("Quest %s is missing an id or title." % quest_id)
		var mode := String(quest.get("mode", "sequential"))
		if mode not in ["sequential", "collection"]:
			errors.append("Quest %s has unsupported mode %s." % [quest_id, mode])
		var steps: Array = quest.get("steps", [])
		if steps.is_empty():
			errors.append("Quest %s has no steps." % quest_id)
		var step_ids: Dictionary = {}
		for step_value: Variant in steps:
			if step_value is not Dictionary:
				errors.append("Quest %s contains a non-dictionary step." % quest_id)
				continue
			var step := step_value as Dictionary
			var step_id := String(step.get("id", ""))
			var event_type := StringName(step.get("event_type", ""))
			var event_id := String(step.get("event_id", ""))
			if step_id.is_empty() or String(step.get("objective", "")).is_empty() or event_id.is_empty():
				errors.append("Quest %s contains an incomplete step." % quest_id)
			if step_ids.has(step_id):
				errors.append("Quest %s repeats step id %s." % [quest_id, step_id])
			step_ids[step_id] = true
			if event_type not in EVENT_TYPES:
				errors.append("Quest %s step %s uses unsupported event type %s." % [quest_id, step_id, event_type])
			if String(quest.get("category", "side")) == "main" and String(step.get("target_room_id", "")).is_empty():
				errors.append("Main quest %s step %s has no map target room." % [quest_id, step_id])
	return errors


static func initial_states() -> Dictionary:
	var result: Dictionary = {}
	for quest_id: Variant in definitions():
		var quest := definition(StringName(quest_id))
		result[String(quest_id)] = {
			"status": "active" if bool(quest.get("auto_start", false)) else "locked",
			"current_step": 0,
			"completed_steps": {},
		}
	return result


static func normalize_states(value: Variant) -> Dictionary:
	var result := initial_states()
	if value is not Dictionary:
		return result
	var supplied := value as Dictionary
	for quest_id: String in result:
		if supplied.get(quest_id) is not Dictionary:
			continue
		var raw := supplied[quest_id] as Dictionary
		var state := result[quest_id] as Dictionary
		var status := String(raw.get("status", state.status))
		state.status = status if status in ["locked", "active", "complete"] else state.status
		var step_count := (definition(StringName(quest_id)).get("steps", []) as Array).size()
		state.current_step = clampi(int(raw.get("current_step", 0)), 0, step_count)
		state.completed_steps = _truthy_keys(raw.get("completed_steps", {}))
		result[quest_id] = state
	return result


static func reconcile(states: Variant, snapshot: Dictionary) -> Dictionary:
	var result := normalize_states(states)
	for quest_id: String in result:
		var quest := definition(StringName(quest_id))
		var state := result[quest_id] as Dictionary
		if String(state.status) == "locked" and bool(quest.get("auto_start", false)):
			state.status = "active"
		if String(state.status) == "locked":
			continue
		var steps: Array = quest.get("steps", [])
		var completed: Dictionary = state.get("completed_steps", {})
		if String(quest.get("mode", "sequential")) == "collection":
			for step_value: Variant in steps:
				var step := step_value as Dictionary
				if _condition_met(step, snapshot):
					completed[String(step.get("id", ""))] = true
			state.current_step = completed.size()
			state.status = "complete" if completed.size() >= steps.size() else "active"
		else:
			var index := clampi(int(state.get("current_step", 0)), 0, steps.size())
			while index < steps.size():
				var step := steps[index] as Dictionary
				if not _condition_met(step, snapshot):
					break
				completed[String(step.get("id", ""))] = true
				index += 1
			state.current_step = index
			state.status = "complete" if index >= steps.size() else "active"
		state.completed_steps = completed
		result[quest_id] = state
	return result


static func current_objective(states: Variant) -> Dictionary:
	var normalized := normalize_states(states)
	var candidates: Array[String] = []
	for quest_id: String in normalized:
		if String((normalized[quest_id] as Dictionary).get("status", "")) == "active":
			candidates.append(quest_id)
	candidates.sort_custom(func(a: String, b: String) -> bool:
		var a_main := String(definition(StringName(a)).get("category", "side")) == "main"
		var b_main := String(definition(StringName(b)).get("category", "side")) == "main"
		return a_main and not b_main if a_main != b_main else a < b
	)
	if candidates.is_empty():
		return {}
	return quest_view(StringName(candidates[0]), normalized[candidates[0]])


static func journal_entries(states: Variant) -> Array[Dictionary]:
	var normalized := normalize_states(states)
	var result: Array[Dictionary] = []
	for quest_id: String in normalized:
		var state := normalized[quest_id] as Dictionary
		if String(state.get("status", "locked")) != "locked":
			result.append(quest_view(StringName(quest_id), state))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_main := String(a.get("category", "side")) == "main"
		var b_main := String(b.get("category", "side")) == "main"
		return a_main and not b_main if a_main != b_main else String(a.get("title", "")) < String(b.get("title", ""))
	)
	return result


static func quest_view(quest_id: StringName, state_value: Variant) -> Dictionary:
	var quest := definition(quest_id)
	var state := (state_value as Dictionary) if state_value is Dictionary else {}
	var steps: Array = quest.get("steps", [])
	var mode := String(quest.get("mode", "sequential"))
	var progress := int(state.get("current_step", 0))
	var objective := String(quest.get("completion_text", "Complete"))
	var target_room_id := ""
	if String(state.get("status", "")) == "active" and not steps.is_empty():
		if mode == "collection":
			objective = String(quest.get("active_objective", "%d / %d complete" % [progress, steps.size()]))
		else:
			var active_step := steps[clampi(progress, 0, steps.size() - 1)] as Dictionary
			objective = String(active_step.get("objective", ""))
			target_room_id = String(active_step.get("target_room_id", ""))
	return {
		"id": String(quest_id),
		"title": String(quest.get("title", String(quest_id).capitalize())),
		"category": String(quest.get("category", "side")),
		"status": String(state.get("status", "locked")),
		"objective": objective,
		"target_room_id": target_room_id,
		"progress": progress,
		"total": steps.size(),
	}


static func _condition_met(step: Dictionary, snapshot: Dictionary) -> bool:
	var event_type := String(step.get("event_type", ""))
	var event_id := String(step.get("event_id", ""))
	var values: Variant = snapshot.get(event_type, {})
	return values is Dictionary and bool((values as Dictionary).get(event_id, false))


static func _truthy_keys(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if value is Dictionary:
		for key: Variant in value:
			if bool(value[key]):
				result[String(key)] = true
	return result


static func _ensure_loaded() -> void:
	if not _payload.is_empty():
		return
	if not FileAccess.file_exists(DATA_PATH):
		push_error("Quest database is missing: %s" % DATA_PATH)
		_payload = {"schema_version": 0, "quests": {}}
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if parsed is not Dictionary:
		push_error("Quest database is invalid JSON: %s" % DATA_PATH)
		_payload = {"schema_version": 0, "quests": {}}
		return
	_payload = parsed as Dictionary
