extends Node3D

func set_p2_head_pos(pos: Vector3) -> void:
	DebugDraw3D.draw_sphere($OtherVROrigin.position + pos, 0.5, Color.YELLOW)

func _process(delta: float) -> void:
	Networking.call_remote_function(self, "set_p2_head_pos", [$Origin/XRCamera3D.global_position])
