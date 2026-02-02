extends Area2D

@export var spawn_position: Vector2 = Vector2(-160, -8)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		# Reset player position
		body.global_position = spawn_position
		# Reset velocity to prevent momentum carrying over
		body.velocity = Vector2.ZERO
	elif body.has_method("die"): # Check if it's an enemy with a die method
		body.die()
	elif body.is_in_group("enemies"): # orcheck if it's in enemies group
		body.queue_free()
	else:
		# safeguard for other physics bodies
		body.queue_free()
