class_name Ball
extends RigidBody3D

func _physics_process(_delta: float) -> void:
	apply_central_force(Util.compute_drag_from_vel(
		linear_velocity, 
		Util.PING_PONG_BALL_CROSS_AREA, 
		Util.PING_PONG_BALL_DRAG_COEFF
	))
	apply_central_force(Util.compute_magnus_effect(linear_velocity, angular_velocity))
	
