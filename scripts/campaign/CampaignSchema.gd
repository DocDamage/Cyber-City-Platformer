class_name CampaignSchema
extends RefCounted

const REQUIRED_STAGE_FIELDS := [
	"id", "display_name", "act", "substage", "scene", "music_id",
	"mechanics", "expected_checkpoints", "expected_boss", "completion_target",
	"camera_bounds", "par_time", "collectible_count", "encounter_count",
	"unlock_dependencies", "enemy_roster",
]


static func validate(manifest: Dictionary) -> PackedStringArray:
	var failures := PackedStringArray()
	var seen_ids := {}
	var acts: Array = manifest.get("acts", [])
	if acts.size() != 4:
		failures.append("Campaign must contain exactly four acts.")
	for act_value: Variant in acts:
		if act_value is not Dictionary:
			failures.append("Campaign act entry is not a dictionary.")
			continue
		var act: Dictionary = act_value
		var stages: Array = act.get("stages", [])
		if stages.size() != 5:
			failures.append("Act %s must contain five stages." % act.get("number", "?"))
		for stage_value: Variant in stages:
			if stage_value is not Dictionary:
				failures.append("Stage entry is not a dictionary.")
				continue
			var stage: Dictionary = stage_value
			var stage_id := String(stage.get("id", ""))
			for field: String in REQUIRED_STAGE_FIELDS:
				if not stage.has(field):
					failures.append("Stage %s is missing '%s'." % [stage_id, field])
			if stage_id.is_empty() or seen_ids.has(stage_id):
				failures.append("Invalid or duplicate stage ID: %s" % stage_id)
			seen_ids[stage_id] = true
			var scene_path := String(stage.get("scene", ""))
			if scene_path.is_empty() or not ResourceLoader.exists(scene_path, "PackedScene"):
				failures.append("Stage %s scene does not exist: %s" % [stage_id, scene_path])
			var bounds: Array = stage.get("camera_bounds", [])
			if bounds.size() != 4 or float(bounds[2]) <= float(bounds[0]) or float(bounds[3]) <= float(bounds[1]):
				failures.append("Stage %s has invalid camera bounds." % stage_id)
	return failures
