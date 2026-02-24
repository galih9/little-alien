extends CharacterBody2D

# Movement parameters
@export var speed: float = 1000.0        # Lowered for better control without acceleration
@export var jump_velocity: float = -1000.0
@export var gravity: float = 2600.0      # Higher gravity for less "floaty" feel
@export var wall_jump_push: float = 400.0 # Horizontal force when jumping off a wall
@export var wall_slide_speed: float = 150.0

# Jump parameters
@export var max_jumps: int = 2          # Set to 2 for Double Jump
@export var coyote_time: float = 0.15 
@export var jump_buffer_time: float = 0.1 

# Crouch parameters
@export var crouch_collision_scale: float = 0.6 
@export var crouch_sprite_offset: float = 20.0 

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# State tracking
var jumps_made: int = 0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_crouching: bool = false
var was_on_floor: bool = false
var ispowered: bool = false
var health: int = 3

var fireball_scene: PackedScene = preload("res://scenes/fireball.tscn")

# Original values for crouch adjustments
var original_collision_height: float
var original_collision_position: Vector2
var original_sprite_position: Vector2

func _ready() -> void:
	var capsule = collision_shape.shape as CapsuleShape2D
	original_collision_height = capsule.height
	original_collision_position = collision_shape.position
	original_sprite_position = animated_sprite.position

func _physics_process(delta: float) -> void:
	# 1. GRAVITY & WALL SLIDING
	if not is_on_floor():
		if is_on_wall_only() and velocity.y > 0:
			# Slide down walls slowly
			velocity.y = move_toward(velocity.y, wall_slide_speed, gravity * delta)
		else:
			velocity.y += gravity * delta
	
	# 2. JUMP TRACKING (Coyote & Reset)
	if is_on_floor():
		coyote_timer = coyote_time
		jumps_made = 0 
		was_on_floor = true
	else:
		coyote_timer -= delta
	
	# 3. INPUT HANDLING
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	# 4. CROUCHING LOGIC
	var was_crouching := is_crouching
	is_crouching = Input.is_action_pressed("crouch") and is_on_floor()
	if is_crouching != was_crouching:
		update_crouch_state()

	# 5. JUMPING EXECUTION
	if jump_buffer_timer > 0:
		# Wall Jump
		if is_on_wall_only():
			velocity.y = jump_velocity
			# Push away from the wall
			var wall_normal = get_wall_normal()
			velocity.x = wall_normal.x * speed 
			jump_buffer_timer = 0
		
		# Floor Jump or Double Jump
		elif (is_on_floor() or coyote_timer > 0 or jumps_made < max_jumps) and not is_crouching:
			velocity.y = jump_velocity
			jumps_made += 1
			jump_buffer_timer = 0
			coyote_timer = 0 # Disable coyote after first jump

	# Variable jump height
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5
	
	# 6. SNAPPY HORIZONTAL MOVEMENT
	var input_direction := 0.0
	if not is_crouching:
		input_direction = Input.get_axis("move_left", "move_right")
	
	if input_direction != 0:
		velocity.x = input_direction * speed
	else:
		velocity.x = 0 # Instant stop
	
	move_and_slide()
	update_animation(input_direction)
	
	if Input.is_action_just_pressed("fire"):
		fire()

func update_animation(input_direction: float) -> void:
	if input_direction > 0:
		animated_sprite.flip_h = false
	elif input_direction < 0:
		animated_sprite.flip_h = true
	
	if is_crouching:
		animated_sprite.play("crouch")
	elif is_on_wall_only() and velocity.y > 0:
		# If you have a wall slide animation, play it here
		animated_sprite.play("jump") 
	elif not is_on_floor():
		animated_sprite.play("jump")
	elif abs(velocity.x) > 10:
		animated_sprite.play("walking")
	else:
		animated_sprite.play("standing")

func update_crouch_state() -> void:
	var capsule = collision_shape.shape as CapsuleShape2D
	if is_crouching:
		var new_height := original_collision_height * crouch_collision_scale
		capsule.height = new_height
		collision_shape.position.y = original_collision_position.y + ((original_collision_height - new_height) / 2.0)
		animated_sprite.position.y = original_sprite_position.y + crouch_sprite_offset
	else:
		capsule.height = original_collision_height
		collision_shape.position = original_collision_position
		animated_sprite.position = original_sprite_position

# ... Rest of your Powerup, Fire, and Damage functions remain the same ...

func power_up() -> void:
	ispowered = true

func fire() -> void:
	if not ispowered: return
	var fireball = fireball_scene.instantiate()
	fireball.global_position = global_position
	fireball.global_position.y -= 20
	if animated_sprite.flip_h:
		fireball.direction = -1
		fireball.global_position.x -= 40
	else:
		fireball.direction = 1
		fireball.global_position.x += 40
	get_parent().add_child(fireball)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()
	else:
		print("Player took damage! Health: ", health)

func die() -> void:
	print("Player died!")
	get_tree().reload_current_scene()
