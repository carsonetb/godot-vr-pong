extends Node3D

@onready var other_head: Node3D = $OtherOrigin/Headset
@onready var other_left_hand: Node3D = $OtherOrigin/Paddle1
@onready var other_right_hand: Node3D = $OtherOrigin/Paddle2
@onready var this_head: Node3D = $Origin/XRCamera3D
@onready var this_left_hand: Node3D = $Origin/LeftHand
@onready var this_right_hand: Node3D = $Origin/RightHand

var other_head_target: Vector3
var other_head_rot: Vector3
var other_left_hand_target: Vector3
var other_left_hand_rot: Vector3
var other_right_hand_target: Vector3
var other_right_hand_rot: Vector3

var other_origin_pos: Vector3 = Vector3(0.0, 0.0, -3.533)
var other_origin_rot: Vector3 = Vector3(0.0, 180.0, 0.0)

func _ready() -> void:
	XR.environment = $WorldEnvironment.environment
	Global.other_origin = $OtherOrigin
	Global.primary_paddle = $Origin/RightHand
	Global.secondary_paddle = $Origin/LeftHand
	Global.main_world = self
	Networking.lobby_joined.connect(_on_lobby_joined)

func _process(_delta: float) -> void:
	other_head.global_position = lerp(other_head.global_position, other_head_target, 0.5)
	other_head.global_rotation = other_head.global_rotation.slerp(other_head_rot, 0.5)
	other_left_hand.global_position = lerp(other_left_hand.global_position, other_left_hand_target, 0.5)
	other_left_hand.global_rotation = other_left_hand.global_rotation.slerp(other_left_hand_rot, 0.5)
	other_right_hand.global_position = lerp(other_right_hand.global_position, other_right_hand_target, 0.5)
	other_right_hand.global_rotation = other_right_hand.global_rotation.slerp(other_right_hand_rot, 0.5)
	Networking.call_remote_function(self, "set_p2_poses", [
		this_head.global_position, 
		this_head.global_rotation,
		this_left_hand.global_position, 
		this_left_hand.global_rotation,
		this_right_hand.global_position,
		this_right_hand.global_rotation
	])

func set_p2_poses(pos: Vector3, rot: Vector3, left_hand: Vector3, lh_rot: Vector3, right_hand: Vector3, rh_rot: Vector3) -> void:
	other_head_target = pos 
	other_head_rot = rot
	other_left_hand_target = left_hand
	other_left_hand_rot = lh_rot
	other_right_hand_target = right_hand
	other_right_hand_rot = rh_rot

func _on_lobby_joined() -> void:
	if !Networking.is_lobby_owner:
		$Origin.position = other_origin_pos
		$Origin.rotation = other_origin_rot
