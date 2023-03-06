extends Node
class_name Drone

# -- PUBLIC ATTRIBUTES --
var state : Dictionary

# -- PRIVATE ATTRIBUTES --
var _next_state : Dictionary
var _messages : Array[String] = []
var _neighbours : Array[Drone] = []

#-------------------------------------------------------------------------------

# -- ABSTRACT FUNCTIONS --
func get_neighbours() -> Array[Drone]:
	assert("get_neighbours isn't implemented in child class of Drone")
	return []
	
# -- TO OVERRIDE --
func update_state() -> void:
	state = _next_state

# -- CONSTRUCTOR --
func _init(init_state : Dictionary):
	state = init_state
	_next_state = init_state

# -- FINAL FUNCTIONS --
func compute_next_state(p : Protocol) -> void:
	_neighbours = get_neighbours()
	var obs : Array[Dictionary] = p.look(state, _neighbours)
	var msg = _messages.duplicate()
	_messages.clear()
	var result : ComputeResult = p.compute(state, msg, obs)
	_next_state = result.state
	
	# broadcast messages
	for s in result.broadcast_msg:
		broadcast_message(s)	
			
func broadcast_message(msg : String) -> void:
	for d in _neighbours:
		d.receive_message(msg)
		
func receive_message(msg : String) -> void:
	_messages.append(msg)

