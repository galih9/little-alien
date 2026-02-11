extends CharacterBody2D

const SPEED = 50.0
const GRAVITY = 1200.0

enum State {IDLE, CHASE, DEAD}
var current_state = State.IDLE

var player: CharacterBody2D = null
var slime_mite_scene = preload("res://scenes/enemies/slime_mite.tscn")

@onready var animated_sprite = $AnimatedSprite2D
@onready var vision_area = $Area2D # Vision area (Area2D)
@onready var collision_shape = $CollisionShape2D

func _ready():
	add_to_group("enemies")
	vision_area.body_entered.connect(_on_vision_body_entered)
	vision_area.body_exited.connect(_on_vision_body_exited)
	animated_sprite.play("idle")

func _physics_process(delta):
	if current_state == State.DEAD:
		return
		
	# Apply Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	if current_state == State.CHASE and player:
		var direction = global_position.direction_to(player.global_position).x
		if direction > 0:
			velocity.x = SPEED
			animated_sprite.flip_h = false
		else:
			velocity.x = - SPEED
			animated_sprite.flip_h = true
			
		if is_on_floor():
			animated_sprite.play("move")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor():
			animated_sprite.play("idle")
			
	move_and_slide()
	
	# Check collision with player
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.name == "Player":
			if collider.has_method("take_damage"):
				collider.take_damage(1)

func _on_vision_body_entered(body):
	if body.name == "Player":
		player = body
		current_state = State.CHASE

func _on_vision_body_exited(body):
	if body.name == "Player":
		player = null
		current_state = State.IDLE

func die():
	if current_state == State.DEAD:
		return
		
	current_state = State.DEAD
	velocity.x = 0
	collision_shape.set_deferred("disabled", true)
	animated_sprite.play("dead")
	
	spawn_mites()
	
	await animated_sprite.animation_finished
	queue_free()

func spawn_mites():
	for i in range(2):
		var mite = slime_mite_scene.instantiate()
		mite.global_position = global_position + Vector2(randf_range(-20, 20), -10)
		get_parent().call_deferred("add_child", mite)
