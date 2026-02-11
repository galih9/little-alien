extends CharacterBody2D

const SPEED = 150.0
const PUSH_FORCE = 400.0

enum State {IDLE, CHASE, DEAD}
var current_state = State.IDLE

var player: CharacterBody2D = null

@onready var animated_sprite = $AnimatedSprite2D
@onready var vision_area = $Vision
@onready var collision_shape = $CollisionShape2D

func _ready():
	add_to_group("enemies")
	vision_area.body_entered.connect(_on_vision_body_entered)
	vision_area.body_exited.connect(_on_vision_body_exited)
	
	# Handle collision with player directly if simple collision body
	# However, usually we want an Area2D for hit detection or use collision info
	# For CharacterBody2D, we can check slide collisions

func _physics_process(_delta):
	if current_state == State.DEAD:
		return
		
	if current_state == State.CHASE and player:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * SPEED
		
		# Flip sprite based on direction
		animated_sprite.flip_h = direction.x < 0
		
		if animated_sprite.animation != "fly":
			animated_sprite.play("fly")
			
	elif current_state == State.IDLE:
		velocity = Vector2.ZERO
		# Optional: Hover animation or wandering
		
	move_and_slide()
	
	# Check for collisions with player
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider.name == "Player":
			if collider.has_method("take_damage"):
				collider.take_damage(1)
				push_back(collision.get_normal())

func _on_vision_body_entered(body):
	if body.name == "Player":
		player = body
		current_state = State.CHASE

func _on_vision_body_exited(body):
	if body.name == "Player":
		player = null
		current_state = State.IDLE

func push_back(normal: Vector2):
	# Simple bounce affect
	velocity = normal * PUSH_FORCE
	move_and_slide()

func die():
	if current_state == State.DEAD:
		return
		
	current_state = State.DEAD
	velocity = Vector2.ZERO
	hit_flash() # Optional
	animated_sprite.play("dead")
	collision_shape.set_deferred("disabled", true)
	
	await animated_sprite.animation_finished
	queue_free()

func hit_flash():
	modulate = Color.RED
	var timer = get_tree().create_timer(0.1)
	await timer.timeout
	modulate = Color.WHITE
