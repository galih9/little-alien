extends Node2D

@export var speed = 100.0
@onready var path_follow = %PathFollow2D

func _process(delta):
	path_follow.progress += speed * delta
