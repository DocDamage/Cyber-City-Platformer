extends Area2D


func _ready() -> void:
	add_to_group(&"kill_volume")
	add_to_group(&"teleport_forbidden")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(&"player") and body.has_method(&"kill"):
		body.call(&"kill")
