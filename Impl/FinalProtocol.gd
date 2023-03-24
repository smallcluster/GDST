extends Protocol
class_name FinalProtocol

@export var D : float = 0.3
@export var base_pos : Vector3 = Vector3.ZERO

#-------------------------------------------------------------------------------

func get_default_state() -> Dictionary:
	return {
		"id" : 0,
		"KILL" : false,
		"active": true,
		"position": Vector3.ZERO,
		"light": false,
		"border": false,
		"layer" : 0
	}
	
func _flat_dist_sq(p1, p2) -> float:
	return (p1.x-p2.x)*(p1.x-p2.x)+(p1.z-p2.z)*(p1.z-p2.z)
	
	
func look(state : Dictionary, neighbours : Array[Drone]) -> Array:
	var visible := neighbours.filter(func(x): return x.state["active"])
	
	return visible.map(func(x): return {
		"id" : x.state["id"],
		"position" : x.state["position"],
		"light" : x.state["light"],
		"border" : x.state["border"]
	})
	
func compute(state : Dictionary, obs : Array) -> Dictionary:
	
	var Dmax := 7 * D
	var Dc := 2 * D
	var Dp := 7*D - D
	var depth := 5 * D
	
	var return_height = base_pos.y + 2*D
	
	# -- CURRENT STATE ATTRIBUTES --
	var pos = state["position"] # Vector2 or Vector3
	var id : int = state["id"]
	var active : bool = state["active"]
	var border : bool = state["border"]
	
	# Default new state
	var new_state = state.duplicate()
	new_state["light"] = false
	new_state["border"] = false
	
	# Do nothing if inactive
	if not active:
		return new_state

	# -- New Protocol:
	
	# detect layers
	var self_layer = obs.filter(func(x): return abs(x["position"].y - pos.y) < 0.01	)
	var layer1 = obs.filter(func(x): return abs(x["position"].y - (pos.y-depth/5)) < 0.01)
	var layer2 = obs.filter(func(x): return abs(x["position"].y - (pos.y-2*depth/5)) < 0.01)
	var layer3 = obs.filter(func(x): return abs(x["position"].y - (pos.y-3*depth/5)) < 0.01)
	var layer4 = obs.filter(func(x): return abs(x["position"].y - (pos.y-4*depth/5)) < 0.01)
	var layer5 = obs.filter(func(x): return abs(x["position"].y - (pos.y-depth)) < 0.01)
	
	var self_layer_collision = not self_layer.filter(func(x): return x["id"] < id).all(func(x): return _flat_dist_sq(x["position"], pos) > D*D)
	
	# Look below 
	var filter = func(x): return _flat_dist_sq(x["position"], pos) < 4*D*D
	var layer1_warn = layer1.filter(filter)
	var layer2_warn = layer2.filter(filter)
	var layer3_warn = layer1.filter(filter)
	var layer4_warn = layer2.filter(filter)
	

	# go up
	if self_layer_collision or state["layer"] == 1 or not layer1_warn.is_empty():
		new_state["position"] = pos + Vector3.UP * D
		new_state["layer"] += 1
		return new_state
		
	
	#TODO: OPTIMIZE DRONE FOLLOWING ON UPPER LAYERS 
	
	# go down
	if state["layer"] > 2 and ((layer1_warn.is_empty() and layer2_warn.is_empty() and not layer1.filter(func(x): return _flat_dist_sq(x["position"], pos) < Dp).is_empty()) or (layer1.is_empty() and layer2.is_empty())):
		new_state["position"] = pos - Vector3.UP * D
		new_state["layer"] -= 1
		return new_state
		
		
		
		
	if state["layer"] > 2:
		
		# follow the closest underself
		layer1.append_array(layer2)
		var choice = layer1.reduce(func(acc,x): return x if _flat_dist_sq(x["position"], pos) < _flat_dist_sq(acc["position"], pos) else acc, layer1[0])
		var target = choice["position"]
		target.y = pos.y
		new_state["position"] = pos +(target-pos).normalized() * D
		return new_state
		
		
		
	#- Going back to the base
	if state["layer"] == 2:
		# Already near base !
		if pos.distance_squared_to(base_pos) <= 25*D*D:
			new_state["KILL"] = true
			return new_state
			
		# follow the closest neighbours
		if layer2.is_empty():
			var choice = self_layer.reduce(func(acc,x): return x if _flat_dist_sq(x["position"], pos) < _flat_dist_sq(acc["position"], pos) else acc, self_layer[0])
			var target = choice["position"]
			new_state["position"] = pos +(target-pos).normalized() * D
			return new_state
		
		# look drones below !	
		obs = layer2
		
		var on_border = obs.all(func(x): return x["border"])
		var target
		if on_border:
			target = obs.reduce(func(acc, x): return acc if acc["id"] < x["id"] else x, obs[0])
		else:
			# go to the larget id not on border
			var candidates = obs.filter(func(x): return not x["border"])
			target = candidates.reduce(func(acc, x): return acc if acc["id"] > x["id"] else x, candidates[0])
		var new_pos = target["position"]
		new_pos.y = pos.y
		var vd = (new_pos - pos)
		new_state["position"] = pos + vd.normalized() * D
		return new_state
	
	
	#- Going to search team
	obs = self_layer
	
	var connected_to_me = obs.filter(func(x): return x["id"] > id)
	
	# I am a leaf drone or all paths behind me are "border" path
	var con_to_base = pos.distance_squared_to(base_pos) < 49*D*D
	var isolated = connected_to_me.all(func(x): return x["border"])
	
	if (connected_to_me.is_empty() or isolated) and not con_to_base and id > 0:
		new_state["border"] = true
	
	obs = obs.filter(func(x): return x["id"] < id) # default observation
	
	# no movement possible
	if obs.is_empty():
		return new_state
		
	# --- Default protocol:
	
	# Collision ? => return to base
	for o in obs:
		if pos.distance_squared_to(o["position"]) <= D*D:
			new_state["position"] = pos + Vector3.UP * D # goes up one layer
			new_state["layer"] += 1
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
	
