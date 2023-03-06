extends Drone
class_name Drone3DImpl
@onready var _detection : Area3D = $"../Detection"

func get_neighbours() -> Array[Drone]:
	return _detection.get_overlapping_bodies() \
	.map(func(x): return x.get_drone()) \
	.filter(func(x): return x.state["id"] != state["id"])
