extends Camera2D

@export var target_path: NodePath
@export var smoothing: float = 5.0

var target: Node2D


func _ready() -> void:
	if target_path:
		target = get_node(target_path)


func _physics_process(delta: float) -> void:
	if target:
		global_position = global_position.lerp(target.global_position, smoothing * delta)
