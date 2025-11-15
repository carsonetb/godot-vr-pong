extends Node

const AIR_DENSITY_AT_SEA_LEVEL: float = 1.225 ## kg/m^3
const PING_PONG_BALL_RADIUS: float = 0.02 ## m
const PING_PONG_BALL_CROSS_AREA: float = PI * pow(PING_PONG_BALL_RADIUS, 2)
const PING_PONG_BALL_DRAG_COEFF: float = 0.5
const PING_PONG_BALL_LIFT_COEFF: float = 0.28
const PING_PONG_BALL_MASS = 0.0027 ## kg

func plus_or_minus(a: float, b: float) -> float:
	return a + randf_range(-b, b)

## A force in Newtons, to be applied in the oposite direction of velocity normal.
func compute_drag(speed: float, area: float, drag_coefficient: float) -> float:
	return 0.5 * AIR_DENSITY_AT_SEA_LEVEL * pow(speed, 2.0) * drag_coefficient * area

func compute_drag_from_vel(velocity: Vector3, area: float, drag_coefficient: float) -> Vector3:
	return -velocity.normalized() * compute_drag(velocity.length(), area, drag_coefficient)

func compute_magnus_effect(angular_velocity: Vector3, velocity: Vector3) -> Vector3:
	return angular_velocity.cross(velocity) * \
		0.5 * AIR_DENSITY_AT_SEA_LEVEL * PING_PONG_BALL_CROSS_AREA * PING_PONG_BALL_LIFT_COEFF
