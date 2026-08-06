class_name DistrictArtCatalog
extends RefCounted

const PATH := "res://data/world/district_art_profiles.json"
const PROFILE_SOURCE := "district_art_bible_v1"
const REQUIRED_COLOR_FIELDS := [
	"background_color",
	"architecture_color",
	"platform_color",
	"trim_color",
	"accent_color",
	"atmosphere_color",
	"foreground_color",
]
const REGION_IDS := ["cyber_city", "robot_factory", "neon_moon", "abyssal_night"]

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			_data = parsed as Dictionary
		else:
			push_error("District art catalog is invalid: %s" % PATH)
	return _data


static func profiles() -> Dictionary:
	return (data().get("profiles", {}) as Dictionary).duplicate(true)


static func profile(district_id: String) -> Dictionary:
	return ((data().get("profiles", {}) as Dictionary).get(district_id, {}) as Dictionary).duplicate(true)


static func profile_color(art_profile: Dictionary, field: String, fallback: Color) -> Color:
	return Color.from_string(String(art_profile.get(field, "")), fallback)


static func validate(expected_districts: Dictionary = {}) -> PackedStringArray:
	var errors := PackedStringArray()
	if int(data().get("schema_version", 0)) != 1 or String(data().get("profile_source", "")) != PROFILE_SOURCE:
		errors.append("District art catalog does not declare schema 1 and %s." % PROFILE_SOURCE)
	var definitions := profiles()
	if definitions.size() != 20:
		errors.append("District art catalog contains %d profiles; expected 20." % definitions.size())
	var used_props := {}
	var landmark_signatures := {}
	var backdrop_signatures := {}
	for district_id: String in definitions:
		var art_profile := definitions[district_id] as Dictionary
		var region_id := String(art_profile.get("region_id", ""))
		if region_id not in REGION_IDS:
			errors.append("District art profile %s has invalid region %s." % [district_id, region_id])
		if expected_districts.has(district_id) and String(expected_districts[district_id]) != region_id:
			errors.append("District art profile %s region %s does not match world region %s." % [district_id, region_id, expected_districts[district_id]])
		if String(art_profile.get("art_direction", "")).length() < 24:
			errors.append("District art profile %s lacks an authored art direction." % district_id)
		for field: String in REQUIRED_COLOR_FIELDS:
			if not _valid_color(String(art_profile.get(field, ""))):
				errors.append("District art profile %s has invalid %s." % [district_id, field])
		var backdrop := art_profile.get("backdrop_heights", []) as Array
		if backdrop.size() != 8:
			errors.append("District art profile %s requires eight skyline heights." % district_id)
		else:
			for height_value: Variant in backdrop:
				var height := float(height_value)
				if height < 0.18 or height > 0.9:
					errors.append("District art profile %s has an out-of-range skyline height." % district_id)
			var backdrop_signature := JSON.stringify(backdrop)
			if backdrop_signatures.has(backdrop_signature):
				errors.append("District art profile %s duplicates the skyline of %s." % [district_id, backdrop_signatures[backdrop_signature]])
			backdrop_signatures[backdrop_signature] = district_id
		var points := art_profile.get("landmark_points", []) as Array
		if points.size() < 7:
			errors.append("District art profile %s has insufficient landmark geometry." % district_id)
		else:
			for point_value: Variant in points:
				if point_value is not Array or (point_value as Array).size() != 2:
					errors.append("District art profile %s has an invalid landmark point." % district_id)
			var landmark_signature := JSON.stringify(points)
			if landmark_signatures.has(landmark_signature):
				errors.append("District art profile %s duplicates the landmark geometry of %s." % [district_id, landmark_signatures[landmark_signature]])
			landmark_signatures[landmark_signature] = district_id
		var prop_paths := art_profile.get("prop_paths", []) as Array
		var prop_scales := art_profile.get("prop_scale", []) as Array
		if prop_paths.size() != 2 or prop_scales.size() != prop_paths.size():
			errors.append("District art profile %s requires two normalized prop records." % district_id)
		for index: int in range(prop_paths.size()):
			var path := String(prop_paths[index])
			if not path.begins_with("res://assets/runtime/props/") or not ResourceLoader.exists(path, "Texture2D"):
				errors.append("District art profile %s has missing runtime prop %s." % [district_id, path])
			if used_props.has(path):
				errors.append("District art profile %s reuses prop %s from %s." % [district_id, path, used_props[path]])
			used_props[path] = district_id
			if index >= prop_scales.size() or float(prop_scales[index]) < 1.0 or float(prop_scales[index]) > 3.0:
				errors.append("District art profile %s has an invalid normalized prop scale." % district_id)
	for district_id: String in expected_districts:
		if not definitions.has(district_id):
			errors.append("World district %s has no district art profile." % district_id)
	for district_id: String in definitions:
		if not expected_districts.is_empty() and not expected_districts.has(district_id):
			errors.append("District art profile %s has no matching world district." % district_id)
	if landmark_signatures.size() != definitions.size() or backdrop_signatures.size() != definitions.size():
		errors.append("District art catalog does not provide unique landmark and skyline geometry for every profile.")
	return errors


static func clear_runtime_cache() -> void:
	_data.clear()


static func _valid_color(value: String) -> bool:
	return value.length() in [6, 8] and value.is_valid_hex_number(false)
