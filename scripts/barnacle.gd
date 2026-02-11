extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var hit_area = $HitArea
@onready var collision_shape = $CollisionPolygon2D # Using Polygon from inspection
# Note: The hit area collision shape is likely seperate

func _ready():
	add_to_group("enemies")
	animated_sprite.play("idle")
	
	# Connect HitArea signal
	hit_area.body_entered.connect(_on_hit_area_body_entered)

func _physics_process(_delta):
	# Barnacle is static, maybe plays idle loop
	pass

func _on_hit_area_body_entered(body):
	if body.name == "Player":
		animated_sprite.play("attack")
		if body.has_method("die"):
			body.die()

func die():
	hit_area.set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)
	animated_sprite.play("dead")
	
	await animated_sprite.animation_finished
	queue_free()
