class_name Drone

var _state : DroneState
var _next_state : DroneState
var _messages : Array[String]
var _neighbours : Array[Drone]

func compute_next_state(p : Protocol) -> void:
	_neighbours = get_neighbours()
	var obs : Array[ObservableState] = p.look(_neighbours)
	_next_state = p.compute(_state, _messages, obs)
	
func broadcast_message(msg : String) -> void:
	for d in _neighbours:
		d.receive_message(msg)
		
func receive_message(msg : String) -> void:
	_messages.append(msg)
	
func get_messages() -> Array[String]:
	return _messages
	
# Override with custom logic
func update_state() -> void:
	_state = _next_state

# ABSTRACT FUNCTIONS
func get_neighbours() -> Array[Drone]:
	push_error("get_neighbours isn't implemented in child class of Drone")
	return []
	

