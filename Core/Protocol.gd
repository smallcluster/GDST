class_name Protocol

func look(state : Dictionary, neighbours : Array[Drone]) -> Array:
	return []

func compute(state : Dictionary, obs : Array, base_pos : Vector3) -> Dictionary:
	return state

func get_default_state() -> Dictionary:
	return {
		"id": 0,
		"active" : true,
		"position": Vector3.ZERO,
		
		# GODOT SIMULATION SPECIFIC (to unload drone object)
		"KILL" : false
	}
	
func get_max_dist_from_base() -> float:
	return 3 * 0.3

func get_max_move_dist() -> float:
	return 0.3
	
# -- FINAL FUNC --
func migrate_state(state : Dictionary) -> Dictionary:
	var new_state := get_default_state()
	for key in state:
		if new_state.has(key):
			new_state[key] = state[key]
	return new_state
		
		
# PARAMS FOR GODOT DRONE OBJECT
# --------------------------------------------------------------------------------------------------
func get_vision_shape() -> CollisionShape3D:
	var collision = CollisionShape3D.new()
	collision.shape = SphereShape3D.new()
	return collision
	
func get_vision_meshes() -> Array[MeshInstance3D]:
	return []
