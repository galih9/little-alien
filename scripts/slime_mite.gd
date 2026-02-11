extends CharacterBody2D

const SPEED = 80.0
const GRAVITY = 1200.0

enum State {SPAWN, CHASE, DEAD}
var current_state = State.SPAWN

var player: CharacterBody2D = null

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	add_to_group("enemies")
	animated_sprite.play("spawn")
	await animated_sprite.animation_finished
	
	current_state = State.CHASE
	animated_sprite.play("move")
	
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		# Fallback: search by name
		player = get_parent().find_child("Player")

func _physics_process(delta):
	if current_state == State.DEAD:
		return
	
	if current_state == State.SPAWN:
		# Apply gravity but don't move
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		return

	# Apply Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		
	if player:
		var direction = global_position.direction_to(player.global_position).x
		if direction > 0:
			velocity.x = SPEED
			animated_sprite.flip_h = false
		else:
			velocity.x = - SPEED
			animated_sprite.flip_h = true
	else:
		# Search/Verify player again if lost
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
			
	move_and_slide()
	
	# Check collision with player
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.name == "Player":
			if collider.has_method("take_damage"):
				collider.take_damage(1)

func die():
	if current_state == State.DEAD:
		return
		
	current_state = State.DEAD
	velocity.x = 0
	collision_shape.set_deferred("disabled", true)
	animated_sprite.play("dead")
	
	await animated_sprite.animation_finished
	queue_free()
