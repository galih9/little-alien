extends Area2D

@export var speed: float = 400.0
@export var fall_gravity: float = 800.0
var direction: int = 1
var vertical_velocity: float = -200.0

func _ready() -> void:
	# Ensure the fireball is destroyed after a few seconds to prevent memory leaks
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(queue_free)
	
	# Play the rotation animation
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("rotate")
		
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position.x += speed * direction * delta
	
	# Apply gravity
	vertical_velocity += fall_gravity * delta
	position.y += vertical_velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("die"):
			body.die()
		queue_free()
	elif body.name != "Player":
		# Destroy on hitting walls/ground, but ignore player
		queue_free()
