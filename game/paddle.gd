extends RigidBody3D

@export var enabled: bool = true

func _ready() -> void:
	
func _process(delta: float) -> void:
	$CollisionShape3D.disabled = !enabled
	$CollisionShape3D2.disabled = !enabled
	$CollisionShape3D3.disabled = !enabled
	$CollisionShape3D4.disabled = !enabled
	$CollisionShape3D5.disabled = !enabled
	visible = enabled
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	transform
