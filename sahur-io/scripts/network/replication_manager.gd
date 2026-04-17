extends RefCounted
class_name ReplicationManager

var accumulator: float = 0.0

func tick(delta: float, rate: float) -> bool:
	if rate <= 0.0:
		return false
	accumulator += delta
	var interval := 1.0 / rate
	if accumulator >= interval:
		accumulator = fmod(accumulator, interval)
		return true
	return false
