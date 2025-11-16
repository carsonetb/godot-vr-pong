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

func _ready() -> void:
	XR.environment = $WorldEnvironment.environment
	Global.other_origin = $OtherOrigin
	Global.primary_paddle = $Origin/RightHand
	Global.secondary_paddle = $Origin/LeftHand
	Global.main_world = self

func _process(_delta: float) -> void:
	other_head.position = lerp(other_head.position, other_head_target, 0.5)
	other_head.rotation = other_head.rotation.slerp(other_head_rot, 0.5)
	other_left_hand.position = lerp(other_left_hand.position, other_left_hand_target, 0.5)
	other_left_hand.rotation = other_left_hand.rotation.slerp(other_left_hand_rot, 0.5)
	other_right_hand.position = lerp(other_right_hand.position, other_right_hand_target, 0.5)
	other_right_hand.rotation = other_right_hand.rotation.slerp(other_right_hand_rot, 0.5)
	Networking.call_remote_function(self, "set_p2_poses", [
		this_head.position, 
		this_head.rotation,
		this_left_hand.position, 
		this_left_hand.rotation,
		this_right_hand.position,
		this_right_hand.rotation
	])


func set_p2_poses(pos: Vector3, rot: Vector3, left_hand: Vector3, lh_rot: Vector3, right_hand: Vector3, rh_rot: Vector3) -> void:
	other_head_target = pos 
	other_head_rot = rot
	other_left_hand_target = left_hand
	other_left_hand_rot = lh_rot
	other_right_hand_target = right_hand
	other_right_hand_rot = rh_rot
