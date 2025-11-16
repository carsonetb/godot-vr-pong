class_name Ball
extends RigidBody3D

var ball_owner: bool = false
var attached_to_paddle: bool = false

@export var detection_area: Area3D

func _ready() -> void:
	Global.ball = self
	Networking.lobby_joined.connect(_on_lobby_joined)
	detection_area.area_entered.connect(_on_detection_area_exited)

func _process(_delta: float) -> void:
	if ball_owner:
		Networking.call_remote_function(self, "_remote_update_ball_posrot", [position, rotation])

func _physics_process(_delta: float) -> void:
	if freeze:
		return
	apply_central_force(Util.compute_drag_from_vel(
		linear_velocity, 
		Util.PING_PONG_BALL_CROSS_AREA, 
		Util.PING_PONG_BALL_DRAG_COEFF
	))
	apply_central_force(Util.compute_magnus_effect(linear_velocity, angular_velocity))

func _on_detection_area_exited(area: Area3D) -> void:
	if area.name == "MyArea" && Networking.networking_enabled:
		Networking.call_remote_function(self, "_remote_transfer_ownership", [
			position, rotation, linear_velocity, angular_velocity
		])
		ball_owner = false
		freeze = true

func _on_lobby_joined() -> void:
	if Networking.is_lobby_owner:
		ball_owner = false
		freeze = true
		position = Vector3(1000, 1000, 1000) # Until we are respawned

func _remote_update_ball_posrot(pos: Vector3, rot: Vector3) -> void:
	ball_owner = false
	freeze = true
	position = pos
	rotation = rot

func _remote_transfer_ownership(pos: Vector3, rot: Vector3, vel: Vector3, rotvel: Vector3) -> void:
	ball_owner = true
	position = pos
	rotation = rot
	linear_velocity = vel
	angular_velocity = rotvel
	freeze = false

func _remote_take_ownership() -> void:
	ball_owner = false
	freeze = true
