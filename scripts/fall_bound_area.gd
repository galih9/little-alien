extends Area2D

@export var spawn_position: Vector2 = Vector2(-160, -8)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		# Reset player position
		body.global_position = spawn_position
		# Reset velocity to prevent momentum carrying over
		body.velocity = Vector2.ZERO
