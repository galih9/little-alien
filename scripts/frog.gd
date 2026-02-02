extends CharacterBody2D

# Constants
const SPEED = 100.0
const JUMP_VELOCITY = -350.0
const GRAVITY = 1200.0

# State Machine
enum State {IDLE, CHASE, RETURN}
var current_state = State.IDLE

# Variables
var start_position: Vector2
var player: CharacterBody2D = null
var direction: int = 0 # -1 for left, 1 for right, 0 for none

# Node References
@onready var animated_sprite = $AnimatedSprite2D
@onready var vision_area = $Vision
@onready var jump_delay_timer = %JumpDelay
@onready var between_jump_timer = %BetweenJumpDelay
@onready var collision_shape = $CollisionShape2D

var was_on_floor: bool = false

func _ready():
	add_to_group("enemies")
	# Store initial position for return behavior
	start_position = global_position
	
	# Connect signals
	vision_area.body_entered.connect(_on_vision_body_entered)
	vision_area.body_exited.connect(_on_vision_body_exited)
	between_jump_timer.timeout.connect(_on_between_jump_timer_timeout)
	
	# Initial state check
	if current_state != State.IDLE:
		between_jump_timer.start()

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Track landing
	var is_currently_on_floor = is_on_floor()
	if is_currently_on_floor and not was_on_floor:
		# Just landed
		velocity.x = 0 # stop sliding
		if current_state == State.CHASE or current_state == State.RETURN:
			between_jump_timer.start()
	
	was_on_floor = is_currently_on_floor
	
	# Handle State Logic
	match current_state:
		State.IDLE:
			_handle_idle_state()
		State.CHASE:
			_handle_chase_state()
		State.RETURN:
			_handle_return_state()
			
	# Move
	move_and_slide()
	
	# Update Animation
	_update_animation()
	
	# Check for player collision (damage or be defeated)
	_check_player_collision()

func _handle_idle_state():
	# In idle, we just stay put unless we need to return or chase
	velocity.x = 0
	
	# If we are far from start position and not chasing, return
	if global_position.distance_to(start_position) > 10 and not player:
		current_state = State.RETURN
		between_jump_timer.start()

func _handle_chase_state():
	if player:
		# Determine direction to player
		var direction_to_player = global_position.direction_to(player.global_position).x
		direction = 1 if direction_to_player > 0 else -1
	else:
		current_state = State.RETURN
		# Timer continues from Chase to Return flow

func _handle_return_state():
	# Determine direction to start position
	var diff_x = start_position.x - global_position.x
	
	if abs(diff_x) < 5: # Close enough
		global_position.x = start_position.x
		velocity.x = 0
		direction = 0
		current_state = State.IDLE
		between_jump_timer.stop() # Stop jumping
	else:
		direction = 1 if diff_x > 0 else -1

func _on_between_jump_timer_timeout():
	# Only jump if on floor
	if is_on_floor():
		if current_state == State.CHASE or current_state == State.RETURN:
			# Jump towards direction
			velocity.y = JUMP_VELOCITY
			velocity.x = direction * SPEED

func _on_vision_body_entered(body):
	if body.name == "Player":
		player = body
		current_state = State.CHASE
		# If we were idle, start the jump cycle
		if between_jump_timer.is_stopped():
			between_jump_timer.start()

func _on_vision_body_exited(body):
	if body.name == "Player":
		player = null
		current_state = State.RETURN

func _update_animation():
	if not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("move") # Jump up
		else:
			animated_sprite.play("move") # Fall
	else:
		if velocity.x != 0:
			animated_sprite.play("move")
		else:
			animated_sprite.play("idle")
	
	# Flip sprite
	if direction != 0:
		animated_sprite.flip_h = (direction > 0)

func _check_player_collision():
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider.name == "Player":
			# Check if player is falling (landing on top)
			# We check if player's bottom is roughly above our center
			if collider.velocity.y > 0 and collider.global_position.y < global_position.y:
				die()
				# Bounce player
				collider.velocity.y = -300 # Bounce
			else:
				# Player hit from side/bottom
				pass

func die():
	between_jump_timer.stop()
	animated_sprite.play("dead")
	collision_shape.set_deferred("disabled", true)
	set_physics_process(false)
	
	# simple tween to fade out or just timer
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(queue_free)
