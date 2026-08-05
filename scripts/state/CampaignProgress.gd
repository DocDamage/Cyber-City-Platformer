class_name CampaignProgress
extends RefCounted

var unlocked_acts: Dictionary = {"1": true}
var completed_stages: Dictionary = {}
var best_scores: Dictionary = {}
var best_times: Dictionary = {}
var defeated_bosses: Dictionary = {}
var campaign_complete := false
var total_play_time := 0.0


func clear() -> void:
	unlocked_acts = {"1": true}
	completed_stages.clear()
	best_scores.clear()
	best_times.clear()
	defeated_bosses.clear()
	campaign_complete = false
	total_play_time = 0.0


func complete_stage(stage_id: String, score: int, elapsed_seconds: float) -> void:
	completed_stages[stage_id] = true
	if score > int(best_scores.get(stage_id, -1)):
		best_scores[stage_id] = score
	if elapsed_seconds > 0.0 and (
			not best_times.has(stage_id) or elapsed_seconds < float(best_times[stage_id])
	):
		best_times[stage_id] = elapsed_seconds
	var act_number := stage_id.get_slice("-", 0).to_int()
	var stage_number := stage_id.get_slice("-", 1).to_int()
	if stage_number == 5 and act_number < 4:
		unlocked_acts[str(act_number + 1)] = true


func to_dict() -> Dictionary:
	return {
		"unlocked_acts": unlocked_acts.duplicate(true),
		"completed_stages": completed_stages.duplicate(true),
		"best_scores": best_scores.duplicate(true),
		"best_times": best_times.duplicate(true),
		"defeated_bosses": defeated_bosses.duplicate(true),
		"campaign_complete": campaign_complete,
		"total_play_time": total_play_time,
	}


func load_dict(data: Dictionary) -> bool:
	if not data.has("unlocked_acts") or not data.has("completed_stages"):
		return false
	unlocked_acts = (data.get("unlocked_acts", {"1": true}) as Dictionary).duplicate(true)
	completed_stages = (data.get("completed_stages", {}) as Dictionary).duplicate(true)
	best_scores = (data.get("best_scores", {}) as Dictionary).duplicate(true)
	best_times = (data.get("best_times", {}) as Dictionary).duplicate(true)
	defeated_bosses = (data.get("defeated_bosses", {}) as Dictionary).duplicate(true)
	campaign_complete = bool(data.get("campaign_complete", false))
	total_play_time = maxf(float(data.get("total_play_time", 0.0)), 0.0)
	return true
