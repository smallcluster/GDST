####################################################################################################
# AUTHOR: Pierre JAFFUER                                                                           #
# DESCRIPTION: This protocol iteratively transform the visibility graph to it's largest            #
#              unilaterally connected sub graph by removing drones that are local maximums (no     #
#              neighbour with a higer id).                                                         #
#              Returning drones always follow largest id.                                          #
#              To resolve collisions while returning to the base, all drones but one (lowest id    #
#              involved) will move up, making a (high) pile of robots.                             # 
####################################################################################################

extends Protocol
class_name PReturnO2

var D : float = 0.3

func get_max_dist_from_base() -> float:
	return 3 * D
	
func get_max_move_dist() -> float:
	return D

func get_default_state() -> Dictionary:
	return {
		# Balabonski & Al.'s states
		"id" : 0,
		"active": true,
		"position": Vector3.ZERO,
		"light": false,
		# Jaffuer's states
		"returning" : false,
		
		# -- GODOT SIMULATION SPECIFIC --
		"KILL" : false # To unload drone object
	}
	
func get_defaults_from_state(state : Dictionary) -> Dictionary:
	return {
		# Memorized state
		"id" : state["id"],
		"active": state["active"],
		"position": state["position"], 
		"light": false,
		"returning" : false,
	
		# -- GODOT SIMULATION SPECIFIC --
		"KILL" : state["KILL"] # To unload drone object
	}
	
func look(state : Dictionary, neighbours : Array[Drone]) -> Array:
	var Dmax := 7 * D
	# + 0.1 thanks to float precision...
	var visible := neighbours.filter(func(x): return x.state["active"] and _flat_dist_sq(x.state["position"], state["position"]) <= Dmax*Dmax + 0.1)
	
	return visible.map(func(x): return {
		"id" : x.state["id"],
		"position" : x.state["position"],
		"light" : x.state["light"],
		"returning" : x.state["returning"]
	})
	
func compute(state : Dictionary, obs : Array, base_pos : Vector3) -> ExecReturn:
	
	if state["position"].y < base_pos.y:
		return ExecReturn.new(true, "CONNEXION LOST: drone below base", state)
	
	#***********************************************************************************************
	#*                                       CONSTANTS                                             *
	#***********************************************************************************************
	
	# PROTOCOL
	#-----------------------------------------------------------------------------------------------
	var Dmax := 7 * D
	var Dc := 2 * D
	var Dp := 7 * D - D
	var depth := 2 * D
	
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
		return ExecReturn.new(false, "", new_state)
		
	# Separate vision layer
	var self_layer = obs.filter(func(x): return abs(x["position"].y - pos.y) < 0.01	)
	var layer1 = obs.filter(func(x): return abs(x["position"].y - (pos.y-depth/2)) < 0.01)
	var layer2 = obs.filter(func(x): return abs(x["position"].y - (pos.y-depth)) < 0.01)
	
	# Layer filters
	var collision_filter = func(x): return x["id"] < id and _flat_dist_sq(x["position"], pos) < D*D
	var collision_warn_filter = func(x): return x["id"] < id and _flat_dist_sq(x["position"], pos) < 4*D*D
	
	# Base retrival is a bit higher
	var con_to_base = _flat_dist_sq(pos, base_pos) < Dmax*Dmax and  (pos.y - base_pos.y) <= depth+0.1
	
	var returning = not self_layer.all(func(x): return not x["returning"]) or not \
								(layer1+layer2).is_empty() or (layer1+layer2+self_layer).is_empty()
	new_state["returning"] = returning

	# CHOSE WHICH ACTION TO PERFORM 
	#-----------------------------------------------------------------------------------------------
	
	# RESOLVE COLLISION ?
	var self_layer_collision = self_layer.any(collision_filter)
	var self_layer_warn_collision = self_layer.any(collision_warn_filter)
	
	if self_layer_collision or not layer1.is_empty() or (returning and self_layer_warn_collision):
		new_state["position"] = pos + Vector3.UP * D
		return ExecReturn.new(false, "", new_state)
		

	# RETURN TO BASE ?
	if returning:
		# Already near base !
		if con_to_base:
			# Base capture drone
			if(_flat_dist_sq(pos, base_pos) < 4*D*D):
				new_state["KILL"] = true
				return ExecReturn.new(false, "", new_state)
			# go towards base pos in current plane
			var target_pos = base_pos
			target_pos.y = pos.y
			new_state["position"] = pos + (target_pos-pos).normalized() * D
			return ExecReturn.new(false, "", new_state)
		
		# GO DOWN ?
		if (layer1+layer2).is_empty():
			new_state["position"] = pos - Vector3.UP * D
			return ExecReturn.new(false, "", new_state)
		
		# look drones below and follow largest id	
		obs = layer2 + layer1
		var target = obs.reduce(func(acc, x): return acc if acc["id"] > x["id"] else x, \
																					obs[0])
		var target_pos = target["position"]
		target_pos.y = pos.y
		new_state["position"] = pos + (target_pos - pos).normalized() * D
		return ExecReturn.new(false, "", new_state)
		

	#-----------------------------------------------------------------------------------------------	
	# Try to return unecessary drone to base
	#-----------------------------------------------------------------------------------------------
	
	var leaf_drone = self_layer.filter(func(x): return x["id"] > id).is_empty()
	
	# Only look at neighbours with a lower id
	obs = self_layer.filter(func(x): return x["id"] < id)
	
	# Prefer neighbours who aren't dangerous
	var no_lights := obs.filter(func(x): return not x["light"])
	var candidates := obs if no_lights.is_empty() else no_lights
	
	# Find Closest drone position (with light off priority)
	var cp = candidates.map(func(x): return x["position"])
	
	if cp.is_empty():
		return ExecReturn.new(true, "CONNEXION LOST: no neighbors", new_state)
	
	var target_pos = cp.reduce(func(acc, x): return acc if _flat_dist_sq(acc, pos) < \
																_flat_dist_sq(x, pos) else x, cp[0])
												
	
	# I am a leaf drone so i'm not usefull for maintaining connexion
	if leaf_drone and not con_to_base:
		# check if we won't lose the connexion after moving up :
		# 2D for base retrival
		# 2D for max lag after moving up
		if obs.any(func(x): return _flat_dist_sq(pos, x["position"]) < (Dmax-4*D)*(Dmax-4*D)):
			new_state["position"] = pos + Vector3.UP * D
		else:
			# Move to closest lower id
			# Rem : there is no collision warning now as Dmax-4D = 3D, so it's safe to move 1D 
			# towards it
			new_state["position"] = pos + (target_pos-pos).normalized() * D
			
		return ExecReturn.new(false, "", new_state)
			
	#-----------------------------------------------------------------------------------------------	
	# BALABONSKI & AL.'S CONNEXION PROTOCOL
	#-----------------------------------------------------------------------------------------------
	
	# Stay if there is a danger
	if _flat_dist_sq(pos, target_pos) <= Dc*Dc:
		new_state["light"] = true
		return ExecReturn.new(false, "", new_state)
		
	# Move to target if necessary
	if _flat_dist_sq(pos, target_pos) >= Dp*Dp:
		var vd = (target_pos - pos)
		new_state["position"] = pos + vd.normalized() * D
		
	return ExecReturn.new(false, "", new_state)
	

# Returns squared distance from two points in the XZ plane (Y is up)
func _flat_dist_sq(p1, p2) -> float:
	var x : float = max(p1.x, p2.x) - min(p1.x, p2.x)
	var y : float = max(p1.z, p2.z) - min(p1.z, p2.z)
	return x*x + y*y
	
	
# PARAMS FOR GODOT DRONE OBJECT
# --------------------------------------------------------------------------------------------------
func get_vision_shape() -> CollisionShape3D:
	var collision = CollisionShape3D.new()
	collision.shape = CylinderShape3D.new()
	collision.shape.radius = 7*D
	collision.shape.height = 2*D
	collision.position = Vector3(0, -D, 0)
	return collision
	
func get_vision_meshes() -> Array[MeshInstance3D]:
	var d = MeshCreator.create_cylinder(D, 2*D, Color.RED, 32, Vector3(0, -D, 0))
	var dc = MeshCreator.create_cylinder(2*D, 2*D, Color.ORANGE, 32, Vector3(0, -D, 0))
	var dp = MeshCreator.create_cylinder(7*D-D, 2*D, Color.GREEN, 32, Vector3(0, -D, 0))
	var dmax = MeshCreator.create_cylinder(7*D, 2*D, Color.BLUE, 32, Vector3(0, -D, 0))
	return [d,dc,dp,dmax]
