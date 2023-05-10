####################################################################################################
# AUTHOR: Pierre JAFFUER                                                                           #
# DESCRIPTION: This is an implementation of BALABONSKI's protocol.                                 #
####################################################################################################

extends Protocol
class_name PDefault

var D : float = 0.3

#-------------------------------------------------------------------------------

func get_max_dist_from_base() -> float:
	return 3 * D
	
func get_max_move_dist() -> float:
	return D

func get_default_state() -> Dictionary:
	return {
		"id" : 0,
		"active": true,
		"position": Vector3.ZERO,
		"light": false,
		
		# GODOT SIMULATION SPECIFIC (to unload drone object)
		"KILL" : false
	}
	
func look(state : Dictionary, neighbours : Array[Drone]) -> Array:
	var visible := neighbours.filter(func(x): return x.state["active"] and x.state["id"] < state["id"])
	return visible.map(func(x): return {
		"id" : x.state["id"],
		"position" : x.state["position"],
		"light" : x.state["light"]
	})

func compute(state : Dictionary, obs : Array, base_pos : Vector3) -> Dictionary:
	
	var Dmax := 7 * D
	var Dc := 2 * D
	var Dp := 7*D - D
	
	# -- CURRENT STATE ATTRIBUTES --
	var pos = state["position"] # Vector2 or Vector3
	var id : int = state["id"]
	var active : bool = state["active"]
	
	# Default new state
	var new_state = state.duplicate()
	new_state["light"] = false
	
	# Do nothing if inactive or no neighbours
	if not active or obs.is_empty():
		return new_state
	
	# Collision ? => EXPLODE
	for o in obs:
		if pos.distance_squared_to(o["position"]) <= D*D:
			new_state["active"] = false
			return new_state
	
	# Prefer a target that isn't dangerous
	var candidates := obs.filter(func(x): return not x["light"])
	
	# All dangerous :(
	if candidates.is_empty():
		candidates = obs 

	# Find Closest drone position
	var new_pos = candidates[0]["position"]
	for p in candidates:
		if pos.distance_squared_to(p["position"]) <= new_pos.distance_squared_to(p["position"]):
			new_pos = p["position"]
	
	# Danger ? => stay
	if new_pos.distance_squared_to(pos) <= Dc*Dc:
		new_state["light"] = true
		return new_state
		
	# All good ? => move to target only if it is in Dp zone
	if new_pos.distance_squared_to(pos) > Dp*Dp:
		var vd = (new_pos - pos)
		new_state["position"] = pos + vd.normalized() * D
		
	return new_state

# PARAMS FOR GODOT DRONE OBJECT
# --------------------------------------------------------------------------------------------------
func get_vision_shape() -> CollisionShape3D:
	var collision = CollisionShape3D.new()
	collision.shape = SphereShape3D.new()
	collision.shape.radius = 7*D
	return collision
	
func get_vision_meshes() -> Array[MeshInstance3D]:
	var dmax = MeshCreator.create_circle(7*D, Color.BLUE)
	var dp = MeshCreator.create_circle(7*D-D, Color.GREEN)
	var dc = MeshCreator.create_circle(2*D, Color.ORANGE)
	var d = MeshCreator.create_circle(D, Color.RED)
	
	return [d,dc,dp,dmax]
