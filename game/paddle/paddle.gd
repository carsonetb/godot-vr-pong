class_name Paddle
extends AnimatableBody3D

@export var enabled: bool = true
@export var ball_scene: PackedScene
@export var ball_spawn_point: Marker3D
@export var affiliated_controller: XRController3D

var ball_spawned: bool = false

func _ready() -> void:
	await get_tree().process_frame
	Global.secondary_paddle.button_pressed.connect(_primary_controller_button_pressed)
	Global.secondary_paddle.button_released.connect(_primary_controller_button_released)
	
func _physics_process(delta: float) -> void:
	$CollisionShape3D1.disabled = !enabled
	$CollisionShape3D2.disabled = !enabled
	visible = enabled
	
	if affiliated_controller:
		position = position.lerp(affiliated_controller.position, 0.7 * delta * 60)
		transform.basis = transform.basis.slerp(affiliated_controller.transform.basis, 0.7 * delta * 60)
	if ball_spawned:
		Global.ball.global_position = ball_spawn_point.global_position

func _primary_controller_button_pressed(button: String) -> void:
	if button == "reset_ball" && !ball_spawned && !enabled && affiliated_controller:
		ball_spawned = true
		Global.ball.freeze = true
		Global.ball.ball_owner = true
		Global.ball.attached_to_paddle = true
		Global.ball.global_position = affiliated_controller.global_position
		Global.ball.linear_velocity = Vector3.ZERO
		Global.ball.angular_velocity = Vector3.ZERO
		Networking.call_remote_function(Global.ball, "_remote_transfer_ownership", [Global.ball.global_position, Global.ball.global_rotation, Global.ball.linear_velocity, Global.ball.angular_velocity])

func _primary_controller_button_released(button: String) -> void:
	if button == "reset_ball" && ball_spawned && !enabled && affiliated_controller:
		Global.ball.freeze = false
		Global.ball.attached_to_paddle = false
		ball_spawned = false
