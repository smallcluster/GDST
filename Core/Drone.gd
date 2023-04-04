class_name Drone

# -- PUBLIC ATTRIBUTES --
var state : Dictionary

# -- PRIVATE ATTRIBUTES --
var _next_state : Dictionary
var _neighbours : Array[Drone] = []
var _get_neighbours : Callable

#-------------------------------------------------------------------------------

# -- CONSTRUCTOR --
func _init(init_state : Dictionary, get_neighbours_func : Callable):
	state = init_state
	_next_state = init_state
	_get_neighbours = get_neighbours_func

# -- FINAL FUNCTIONS --
func compute_next_state(p : Protocol, base_pos : Vector3) -> void:
	_neighbours.assign(_get_neighbours.call())
	var obs := p.look(state, _neighbours)
	_next_state = p.compute(state, obs, base_pos)

func update_state() -> void:
	state = _next_state

