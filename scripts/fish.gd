extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	add_to_group("enemies")
	animated_sprite.play("alive")
	
	# Create detection area programmatically for reliable collision
	# since we are moving via PathFollow2D (teleporting context)
	var area = Area2D.new()
	area.name = "Hitbox"
	add_child(area)
	
	var col = CollisionShape2D.new()
	col.shape = $CollisionShape2D.shape
	col.transform = $CollisionShape2D.transform
	area.add_child(col)
	
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		if body.has_method("die"):
			body.die()

func _physics_process(_delta):
	# Movement handles by parent PathFollow2D
	pass

func die():
	collision_shape.set_deferred("disabled", true)
	if has_node("Hitbox"):
		$Hitbox.set_deferred("monitoring", false)
		
	animated_sprite.play("dead")
	
	# Stop movement? The movement is controlled by Fislane (parent of parent)
	# We can't easily stop the PathFollow2D from here without reference.
	# But we can just vanish.
	set_physics_process(false)
	
	await animated_sprite.animation_finished
	queue_free()
