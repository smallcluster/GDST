####################################################################################################
# AUTHOR: Pierre JAFFUER                                                                           #
# DESCRIPTION: This protocol blablabla                                                             #
####################################################################################################


extends Protocol
class_name ObliviousFinalProtocol

@export var D : float = 0.3
@export var depth := 2 * D
@export var base_pos : Vector3 = Vector3.ZERO

# TODO:
# as a final proof of concept, switch to a local coordiante system so we can get rid of the  
# memorized global position

func get_default_state() -> Dictionary:
	return {
		# Balabonski & Al.'s states
		"id" : 0,
		"active": true,
		"position": Vector3.ZERO,
		"light": false,
		
		# Jaffuer's states
		"border": false,
		"mode" : 0,
		# match(mode) 
		#  |0 -> maintaining connexion
		#  |2 -> returning to base
		#  |(mode > 2) -> following drone below
		# modes are sorted from lowest to highest drone height
		
		# GODOT SIMULATION SPECIFIC (to unload drone object)
		"KILL" : false
	}
	
func get_defaults_from_state(state : Dictionary) -> Dictionary:
	return {
		# Memorized state
		"id" : state["id"],
		"active": state["active"],
		"position": state["position"], 
		# In reality, global position isn't memorized, the drone can use its local coordinates (0,0) 
		# to compare distances to visible drones and move towards them.
		
		# Not memorized state
		"light": false,
		"border": false,
		"mode" : 0,
		"KILL" : state["KILL"]
	}
	
func look(state : Dictionary, neighbours : Array[Drone]) -> Array:
	var visible := neighbours.filter(func(x): return x.state["active"])
	
	return visible.map(func(x): return {
		"id" : x.state["id"],
		"position" : x.state["position"],
		"light" : x.state["light"],
		"border" : x.state["border"],
		"mode" : x.state["mode"]
	})
	
func compute(state : Dictionary, obs : Array) -> Dictionary:
	
	#***********************************************************************************************
	#*                                       CONSTANTS                                             *
	#***********************************************************************************************
	
	# PROTOCOL
	#-----------------------------------------------------------------------------------------------
	var Dmax := 7 * D
	var Dc := 2 * D
	var Dp := 7*D - D
	
	# CURRENT DRONE'S OBSERVABLE STATE
	#-----------------------------------------------------------------------------------------------
	var pos : Vector3 = state["position"]
	var id : int = state["id"]
	
	#***********************************************************************************************
	#*                                  COMPUTE NEXT STATE                                         *
	#***********************************************************************************************
	
	# Default new state
	var new_state = get_defaults_from_state(state)
	
	# SKIP COMPUTE IF INACTIVE AND IGNORE BIZANTIN DRONE 0
	if not state["active"] or id == 0:
		return new_state
		
	# Separate vision layer
	var self_layer = obs.filter(func(x): return abs(x["position"].y - pos.y) < 0.01	)
	var layer1 = obs.filter(func(x): return abs(x["position"].y - (pos.y-depth/2)) < 0.01)
	var layer2 = obs.filter(func(x): return abs(x["position"].y - (pos.y-depth)) < 0.01)
	
	# Layer filters
	var collision_filter = func(x): return x["id"] < id and _flat_dist_sq(x["position"], pos) < D*D
	var collision_warn_filter = func(x): return _flat_dist_sq(x["position"], pos) < 4*D*D
	
	# find in which mode we are
	#  |0 -> maintaining connexion
	#  |1 -> returning to base
	#  |(mode > 1) -> following a drone below
	var below_modes = (layer1 + layer2).map(func(x): return x["mode"])
	var current_mode = 0
	
	if not below_modes.is_empty():
		current_mode = below_modes.reduce(func(acc, x): return acc if acc > x else x, \
																				below_modes[0]) + 1
	elif not self_layer.is_empty():
		var self_layer_modes = self_layer.map(func(x): return x["mode"])
		current_mode = self_layer_modes.reduce(func(acc, x): return acc if acc > x else x, \
																				self_layer_modes[0])
	new_state["mode"] = current_mode

	# CHOSE WHICH ACTION TO PERFORM 
	#-----------------------------------------------------------------------------------------------
	
	# RESOLVE COLLISION ?
	var self_layer_collision = not self_layer.filter(collision_filter).is_empty()
	var layer1_warn_collision = not layer1.filter(collision_warn_filter).is_empty()
	
	if self_layer_collision or not layer1.is_empty():
		new_state["position"] = pos + Vector3.UP * D
		return new_state
		
	# GO DOWN ?
	if layer2.is_empty() and not layer1_warn_collision and self_layer.is_empty():
		new_state["position"] = pos - Vector3.UP * D
		return new_state
		
	# FOLLOW BELOW DRONES ?
	if current_mode > 1 : 
		# closest drone below or in the current plane
		var obs_pos
		if layer1.is_empty() and layer2.is_empty():
			obs_pos = self_layer.map(func(x): return x["position"])
		elif layer2.is_empty():
			obs_pos = layer1.map(func(x): return x["position"])
		else:
			obs_pos = layer2.map(func(x): return x["position"])
			
		var target_pos : Vector3 = obs_pos.reduce(func(acc, x): return acc if \
							_flat_dist_sq(acc, pos) < _flat_dist_sq(x, pos) else x, obs_pos[0])
		# Follow only if there is a chance of losing track of the lowest visible drone within 2
		# movement step (2*D)
		#if _flat_dist_sq(target_pos, pos) > Dd*Dd:
		target_pos.y = pos.y # stay in the same plane
		new_state["position"] = pos + (target_pos-pos).normalized() * D
		return new_state
	
	# RETURN TO BASE ?
	if current_mode == 1:
		# Already near base !
		if pos.distance_squared_to(base_pos) <= 25*D*D:
			new_state["KILL"] = true
			return new_state
		
		# look drones below !	
		obs = layer2 + layer1
		
		var on_border = obs.all(func(x): return x["border"])
		var target
		if on_border:
			target = obs.reduce(func(acc, x): return acc if acc["id"] < x["id"] else x, obs[0])
		else:
			# go to the larget id not on border
			var candidates = obs.filter(func(x): return not x["border"])
			target = candidates.reduce(func(acc, x): return acc if acc["id"] > x["id"] else x, \
																					candidates[0])
		var target_pos = target["position"]
		target_pos.y = pos.y
		new_state["position"] = pos + (target_pos - pos).normalized() * D
		return new_state
		
	
	# MAINTAINING CONNEXION...
	
	#-----------------------------------------------------------------------------------------------	
	# DISTRIBUTED ALGORITHM TO ISOLATE A STRICTLY ORDERED CHAIN FROM BASE TO SEARCH TEAM'S DRONE
	# (Needed for the "return to base" mode)
	#-----------------------------------------------------------------------------------------------
	
	#Going to search team
	obs = self_layer
	var connected_to_me = obs.filter(func(x): return x["id"] > id)
	# I am a leaf drone or all paths behind me are "border" path
	var con_to_base = _flat_dist_sq(base_pos, pos) < Dmax*Dmax
	var isolated = connected_to_me.all(func(x): return x["border"])
	
	if (connected_to_me.is_empty() or isolated) and not con_to_base and id > 0:
		new_state["border"] = true
	
	#-----------------------------------------------------------------------------------------------	
	# BALABONSKI & AL.'S CONNEXION PROTOCOL
	#-----------------------------------------------------------------------------------------------
	
	# Only look at neighbours with a lower id
	obs = obs.filter(func(x): return x["id"] < id)
	
	# Can't move
	if obs.is_empty():
		return new_state
	
	# Prefer neighbours who aren't dangerous
	var no_lights := obs.filter(func(x): return not x["light"])
	var candidates := obs if no_lights.is_empty() else no_lights
	
	# Find Closest drone position
	var cp = candidates.map(func(x): return x["position"])
	var target_pos = cp.reduce(func(acc, x): return acc if _flat_dist_sq(acc, pos) < \
																_flat_dist_sq(x, pos) else x, cp[0])

	# Stay if there is a danger
	if _flat_dist_sq(pos, target_pos) <= Dc*Dc:
		new_state["light"] = true
		return new_state
		
	# Move to target if necessary
	if _flat_dist_sq(pos, target_pos) > Dp*Dp:
		var vd = (target_pos - pos)
		new_state["position"] = pos + vd.normalized() * D
		
	return new_state
	

# Returns squared distance from two points in the XZ plane (Y is up)
func _flat_dist_sq(p1, p2) -> float:
	return (p1.x-p2.x)*(p1.x-p2.x)+(p1.z-p2.z)*(p1.z-p2.z)
