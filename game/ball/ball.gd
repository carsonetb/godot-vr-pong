class_name Ball
extends RigidBody3D

var ball_owner: bool = false
var attached_to_paddle: bool = false

@export var detection_area: Area3D

var should_override_and_unfreeze: bool
var position_to_override: Vector3
var rotation_to_override: Vector3
var velocity_to_override: Vector3
var angvel_to_override: Vector3
var target_pos: Vector3

func _ready() -> void:
	Global.ball = self
	Networking.lobby_joined.connect(_on_lobby_joined)
	detection_area.area_exited.connect(_on_detection_area_exited)

func _process(_delta: float) -> void:
	if ball_owner:
		Networking.call_remote_function(self, "_remote_update_ball_posrot", [position, rotation])

func _physics_process(delta: float) -> void:
	if freeze && !attached_to_paddle:
		position = position.lerp(target_pos, 0.5 * delta * 60)
		return
	apply_central_force(Util.compute_drag_from_vel(
		linear_velocity, 
		Util.PING_PONG_BALL_CROSS_AREA, 
		Util.PING_PONG_BALL_DRAG_COEFF
	))
	apply_central_force(Util.compute_magnus_effect(linear_velocity, angular_velocity))

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if should_override_and_unfreeze:
		should_override_and_unfreeze = false
		state.transform.origin = position_to_override
		state.transform.basis = Basis.from_euler(rotation_to_override)
		state.linear_velocity = velocity_to_override
		state.angular_velocity = angvel_to_override

func _on_detection_area_exited(area: Area3D) -> void:
	if area.name == "MyArea" && Networking.networking_enabled:
		Networking.call_remote_function(self, "_remote_transfer_ownership", [global_position, global_rotation, linear_velocity, angular_velocity])
		target_pos = global_position
		ball_owner = false
		freeze = true

func _on_lobby_joined() -> void:
	if Networking.is_lobby_owner:
		ball_owner = false
		freeze = true
		position = Vector3(1000, 1000, 1000) # Until we are respawned

func _remote_update_ball_posrot(pos: Vector3, rot: Vector3) -> void:
	if ball_owner: # Probably old packets
		return
	freeze = true
	target_pos = pos
	rotation = rot

func _remote_transfer_ownership(pos: Vector3, rot: Vector3, vel: Vector3, rotvel: Vector3) -> void:
	freeze = true
	ball_owner = true
	should_override_and_unfreeze = true
	position_to_override = pos
	rotation_to_override = rot
	velocity_to_override = vel
	angvel_to_override = rotvel
	freeze = false

func _remote_take_ownership() -> void:
	ball_owner = false
	freeze = true
