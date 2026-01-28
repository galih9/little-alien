extends CharacterBody2D

# Movement parameters
@export var speed: float = 300.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

# Jump parameters
@export var jump_velocity: float = -600.0
@export var gravity: float = 1200.0
@export var coyote_time: float = 0.15 # Time after leaving ground where jump is still allowed
@export var jump_buffer_time: float = 0.1 # Time before landing where jump input is remembered

# Crouch parameters
@export var crouch_collision_scale: float = 0.6 # How much to shrink collision when crouching
@export var crouch_sprite_offset: float = 20.0 # How much to push sprite down when crouching

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# State tracking
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_crouching: bool = false
var was_on_floor: bool = false

# Original values for crouch adjustments
var original_collision_height: float
var original_collision_position: Vector2
var original_sprite_position: Vector2


func _ready() -> void:
	# Store original values for crouch adjustments
	var capsule = collision_shape.shape as CapsuleShape2D
	original_collision_height = capsule.height
	original_collision_position = collision_shape.position
	original_sprite_position = animated_sprite.position


func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Track coyote time
	if is_on_floor():
		coyote_timer = coyote_time
		was_on_floor = true
	else:
		coyote_timer -= delta
		if was_on_floor and coyote_timer <= 0:
			was_on_floor = false
	
	# Track jump buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta
	
	# Handle crouching
	var was_crouching := is_crouching
	is_crouching = Input.is_action_pressed("crouch") and is_on_floor()
	
	# Update crouch collision/sprite when state changes
	if is_crouching != was_crouching:
		update_crouch_state()
	
	# Handle jumping (with coyote time and jump buffer)
	if jump_buffer_timer > 0 and coyote_timer > 0 and not is_crouching:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
	
	# Variable jump height - release jump early for shorter jump
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5
	
	# Get horizontal input (disabled when crouching)
	var input_direction := 0.0
	if not is_crouching:
		input_direction = Input.get_axis("move_left", "move_right")
	
	# Apply horizontal movement with acceleration/friction
	if input_direction != 0:
		velocity.x = move_toward(velocity.x, input_direction * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	# Move the character
	move_and_slide()
	
	# Update animations and sprite direction
	update_animation(input_direction)


func update_animation(input_direction: float) -> void:
	# Flip sprite based on movement direction
	if input_direction > 0:
		animated_sprite.flip_h = false
	elif input_direction < 0:
		animated_sprite.flip_h = true
	
	# Choose animation based on state
	if is_crouching:
		animated_sprite.play("crouch")
	elif not is_on_floor():
		animated_sprite.play("jump")
	elif abs(velocity.x) > 10:
		animated_sprite.play("walking")
	else:
		animated_sprite.play("standing")


func update_crouch_state() -> void:
	var capsule = collision_shape.shape as CapsuleShape2D
	
	if is_crouching:
		# Shrink collision and move it down so feet stay on ground
		var new_height := original_collision_height * crouch_collision_scale
		var height_diff := original_collision_height - new_height
		capsule.height = new_height
		collision_shape.position.y = original_collision_position.y + (height_diff / 2.0)
		
		# Move sprite down
		animated_sprite.position.y = original_sprite_position.y + crouch_sprite_offset
	else:
		# Restore original values
		capsule.height = original_collision_height
		collision_shape.position = original_collision_position
		animated_sprite.position = original_sprite_position
