class_name Paddle
extends AnimatableBody3D

@export var enabled: bool = true
@export var ball_scene: PackedScene
@export var ball_spawn_point: Marker3D
@export var affiliated_controller: XRController3D

var ball_spawned: bool = false
var ball: Ball

func _ready() -> void:
	await get_tree().process_frame
	Global.primary_paddle.button_pressed.connect(_primary_controller_button_pressed)
	Global.primary_paddle.button_released.connect(_primary_controller_button_released)
	
func _process(_delta: float) -> void:
	$CollisionShape3D1.disabled = !enabled
	$CollisionShape3D2.disabled = !enabled
	visible = enabled
	if affiliated_controller:
		global_transform = affiliated_controller.global_transform

func _primary_controller_button_pressed(button: String) -> void:
	if button == "reset_ball" && !ball_spawned && enabled:
		ball_spawned = true
		ball = ball_scene.instantiate()
		ball.freeze = true
		ball_spawn_point.add_child(ball)

func _primary_controller_button_released(button: String) -> void:
	if button == "reset_ball" && ball_spawned && enabled:
		ball.freeze = false
		ball_spawned = false
		ball.reparent(Global.main_world)
