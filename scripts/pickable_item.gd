extends Area2D

@export var item_texture: Texture2D
@export var item_type: String = "powerup"

@onready var sprite_2d: Sprite2D = %Sprite2D
@onready var animation_player: AnimationPlayer = %AnimationPlayer

func _ready() -> void:
	if item_texture:
		sprite_2d.texture = item_texture
	
	animation_player.play("idle")
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		if body.has_method("power_up"):
			body.power_up()
			
		# Disable collision to prevent double pickup
		$CollisionShape2D.set_deferred("disabled", true)
		
		animation_player.play("picked")
		await animation_player.animation_finished
		queue_free()
