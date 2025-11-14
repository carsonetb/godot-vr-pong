class_name Ball
extends RigidBody3D

@export var apply_drag: bool = true

var previous_ball_positions: Array[Vector3]

func _ready() -> void:
	apply_central_impulse(Vector3(0.02, 0.01, 0))
	apply_torque_impulse(Vector3(0, 0.01, 0))

func _physics_process(_delta: float) -> void:
	if !apply_drag:
		return
	apply_central_force(Util.compute_drag_from_vel(
		linear_velocity, 
		Util.PING_PONG_BALL_CROSS_AREA, 
		Util.PING_PONG_BALL_DRAG_COEFF
	))
	apply_central_force(Util.compute_magnus_effect(linear_velocity, angular_velocity))

func _process(_delta: float) -> void:
	Engine.time_scale = 1
	previous_ball_positions.append(position)
	DebugDraw3D.draw_sphere(position, 0.1, Color.WHITE)
	for pos: Vector3 in previous_ball_positions:
		DebugDraw3D.draw_sphere(pos, 0.02, Color.BEIGE)
