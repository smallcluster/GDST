extends Drone
class_name Drone3DImpl

@onready var _detection : Area3D = $"../Detection"
@onready var _rep := $".."

func get_neighbours() -> Array[Drone]:
	return _detection.get_overlapping_bodies() \
	.map(func(x): return x.get_drone()) \
	.filter(func(x): return x.state["id"] != state["id"])


func update_state() -> void:
	super.update_state()
	
	if not state["active"]:
		_rep.dead = true
	else:
		_rep.warn = state["light"]
		#_rep.not_main = state["light"]
