class_name InventoryState
extends RefCounted

var stacks: Dictionary = {}
var unique_items: Dictionary = {}
var currency := 0


func clear() -> void:
	stacks.clear()
	unique_items.clear()
	currency = 0


func add_item(item_id: StringName, amount := 1, unique := false) -> bool:
	var key := String(item_id)
	if key.is_empty() or amount <= 0:
		return false
	if unique:
		if unique_items.has(key):
			return false
		unique_items[key] = true
		return true
	stacks[key] = int(stacks.get(key, 0)) + amount
	return true


func remove_item(item_id: StringName, amount := 1) -> bool:
	var key := String(item_id)
	if amount <= 0 or int(stacks.get(key, 0)) < amount:
		return false
	var remaining := int(stacks[key]) - amount
	if remaining == 0:
		stacks.erase(key)
	else:
		stacks[key] = remaining
	return true


func has_item(item_id: StringName, amount := 1) -> bool:
	var key := String(item_id)
	return unique_items.has(key) or int(stacks.get(key, 0)) >= amount


func count(item_id: StringName) -> int:
	var key := String(item_id)
	return 1 if unique_items.has(key) else int(stacks.get(key, 0))


func to_dict() -> Dictionary:
	return {"stacks": stacks.duplicate(true), "unique_items": unique_items.duplicate(true), "currency": currency}


func load_dict(data: Variant) -> bool:
	if data is not Dictionary:
		return false
	var values := data as Dictionary
	stacks = _positive_ints(values.get("stacks", {}))
	unique_items = _truthy_keys(values.get("unique_items", {}))
	currency = maxi(int(values.get("currency", 0)), 0)
	return true


func _positive_ints(value: Variant) -> Dictionary:
	var result := {}
	if value is Dictionary:
		for key: Variant in value:
			var count_value := int(value[key])
			if count_value > 0:
				result[String(key)] = count_value
	return result


func _truthy_keys(value: Variant) -> Dictionary:
	var result := {}
	if value is Dictionary:
		for key: Variant in value:
			if bool(value[key]):
				result[String(key)] = true
	return result
