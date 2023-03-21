extends Protocol
class_name SaveProtocol

@export var D : float = 0.3
@export var base_pos : Vector3 = Vector3.ZERO

var choice_reduction : Callable = func(acc, x): return acc if acc["id"] > x["id"] else x

#-------------------------------------------------------------------------------

func get_default_state() -> Dictionary:
	return {
		"id" : 0,
		"KILL" : false,
		"active": true,
		"position": Vector3.ZERO,
		"light": false,
		"border": false,
		"connectedId" : -1
	}

func look(state : Dictionary, neighbours : Array[Drone]) -> Array:
	var visible := neighbours.filter(func(x): return x.state["active"])
	return visible.map(func(x): return {
		"id" : x.state["id"],
		"position" : x.state["position"],
		"light" : x.state["light"],
		"border" : x.state["border"],
		"connectedId" : x.state["connectedId"]
	})
	
func compute(state : Dictionary, obs : Array) -> Dictionary:
	
	var Dmax := 7 * D
	var Dc := 2 * D
	var Dp := 7*D - D
	
	var return_height = base_pos.y + 2*D
	
	# -- CURRENT STATE ATTRIBUTES --
	var pos = state["position"] # Vector2 or Vector3
	var id : int = state["id"]
	var active : bool = state["active"]
	var border : bool = state["border"]
	var connectedId : int = state["connectedId"]
	
	# Default new state
	var new_state = state.duplicate()
	new_state["light"] = false
	new_state["border"] = false
	new_state["connectedId"] = -1
	
	# Do nothing if inactive
	if not active:
		return new_state

	# -- New Protocol:
	
	#- Going back to the base
	if abs(state["position"].y - return_height) < 0.1:
		
		# Already near base !
		if pos.distance_squared_to(base_pos) <= 25*D*D:
			new_state["KILL"] = true
			return new_state
			
		# look drones below !
		obs = obs.filter(func(x): return abs(x["position"].y - return_height) >= 0.1 )
		
		var on_border = obs.all(func(x): return x["border"])
		var target
		if on_border:
			target = obs.reduce(func(acc, x): return acc if acc["id"] < x["id"] else x, obs[0])
		else:
			# go to the larget id not on border
			var candidates = obs.filter(func(x): return not x["border"])
			target = candidates.reduce(func(acc, x): return acc if acc["id"] > x["id"] else x, candidates[0])
		var new_pos = target["position"]
		new_pos.y = return_height
		var vd = (new_pos - pos)
		new_state["position"] = pos + vd.normalized() * D
		return new_state
	
	
	#- Going to search team
	obs = obs.filter(func(x): return abs(x["position"].y - return_height) >= 0.1 )
	
	var connected_to_me = obs.filter(func(x): return x["connectedId"] == id and x["id"] > id)
	
	# I am a leaf drone or all paths behind me are "border" path
	var con_to_base = pos.distance_squared_to(base_pos) < 49*D*D
	var con_to_branche = connected_to_me.all(func(x): return x["border"])
	
	if (connected_to_me.is_empty() or con_to_branche) and not con_to_base and id > 0:
		new_state["border"] = true
	
	obs = obs.filter(func(x): return x["id"] < id) # default observation
	
	# Chose who to connect to	
	
	
	if obs.is_empty():
		return new_state
		
	# no movement possible
	new_state["connectedId"] = obs.reduce(choice_reduction, obs[0])["id"]
	
	

	# --- Default protocol:
	
	# Collision ? => return to base
	for o in obs:
		if pos.distance_squared_to(o["position"]) <= D*D:
			new_state["position"] = pos
			new_state["position"].y = return_height
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
	
