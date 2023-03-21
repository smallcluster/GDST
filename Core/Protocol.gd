class_name Protocol

func look(state : Dictionary, neighbours : Array[Drone]) -> Array:
	return []

func compute(state : Dictionary, obs : Array) -> Dictionary:
	return state

func get_default_state() -> Dictionary:
	return {
		"id": 0,
		"KILL": false,
		"active" : true
	}
	
func get_vision_radius() -> float:
	return 10.0
	
# -- FINAL FUNC --
func migrate_state(state : Dictionary) -> Dictionary:
	var new_state := get_default_state()
	for key in state:
		if new_state.has(key):
			new_state[key] = state[key]
	return new_state
		
	
