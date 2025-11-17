extends Node

const AIR_DENSITY_AT_SEA_LEVEL: float = 1.225 ## kg/m^3
const PING_PONG_BALL_RADIUS: float = 0.02 ## m
const PING_PONG_BALL_CROSS_AREA: float = PI * pow(PING_PONG_BALL_RADIUS, 2)
const PING_PONG_BALL_DRAG_COEFF: float = 0.5
const PING_PONG_BALL_LIFT_COEFF: float = 0.3
const PING_PONG_BALL_MASS = 0.03 ## kg
const MAGNUS_MULTIPLIER = 30.0

func plus_or_minus(a: float, b: float) -> float:
	return a + randf_range(-b, b)

## A force in Newtons, to be applied in the oposite direction of velocity normal.
func compute_drag(speed: float, area: float, drag_coefficient: float) -> float:
	return 0.5 * AIR_DENSITY_AT_SEA_LEVEL * pow(speed, 2.0) * drag_coefficient * area

func compute_drag_from_vel(velocity: Vector3, area: float, drag_coefficient: float) -> Vector3:
	return -velocity.normalized() * compute_drag(velocity.length(), area, drag_coefficient)

func compute_magnus_effect(w: Vector3, v: Vector3) -> Vector3:
	var v_mag: float = v.length()
	if v_mag < 1e-6 or w.length() < 1e-6:
		return Vector3.ZERO

	var dir: Vector3 = w.cross(v).normalized()
	var S: float = w.length() * PING_PONG_BALL_RADIUS / v_mag
	var Cl: float = PING_PONG_BALL_LIFT_COEFF * S

	var mag: float = 0.5 * AIR_DENSITY_AT_SEA_LEVEL * PING_PONG_BALL_CROSS_AREA * Cl * v_mag * v_mag
	return -dir * mag * 70.0
