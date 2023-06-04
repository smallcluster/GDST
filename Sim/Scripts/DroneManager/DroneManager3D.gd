extends Node3D
class_name DroneManager3D

var show_vision := false : set = _set_show_vision
var movement_time := 0.05

signal add_drone(id)
signal remove_drone(id)
signal update_drone_state(state)
signal exec_fail(exec)
signal new_frame(states, target)
signal no_op

@onready var _drones = $Drones
@onready var _lines : Lines3D = $Lines3D as Lines3D
@onready var _base_detection : Area3D = $Base/Detection
@onready var _target_vis = $SearchTeam



var _request_reset := false
var _request_loading_frame : Array[Dictionary] = []
var _hide_inactive := false
var _simulating := false # Act as a lock
var _drone_manager : DroneManager
var _protocol : Protocol
var _next_id := 0
var _search_drone : Drone3D = null
var _search_target_pos : Vector2
var _drone_scene := preload("res://Sim/Drone3D.tscn")
var _run_simulation := true
var _run_one_step := false
var _kill_inactive := false
var _deploy_ground_pos = null
var _draw_directed_graph := false
var _switch_protocol = null

func get_base_pos() -> Vector3:
	return _base_detection.position

func load_frame(states, target):
	_request_reset = true
	_request_loading_frame = states
	_search_target_pos = target

func reset()->void:
	_request_reset = true
	
func hide_inactive(val : bool) -> void:
	_hide_inactive = val

func run_simulation(running : bool) -> void:
	_run_simulation = running
	
func run_one_simulation_step() -> void:
	_run_one_step = true
	_run_simulation = false

func set_protocol(p : Protocol) -> void:
	_switch_protocol = p

	
func deploy_ground_drone_at(pos : Vector3) -> void:
	_deploy_ground_pos = pos
	
func set_search_target(pos : Vector2) -> void:
	_search_target_pos = pos
	
func kill_inactive() -> void:
	_kill_inactive = true
	
func draw_directed_graph(val : bool) -> void:
	_draw_directed_graph = val
	
func _ready():
	_protocol = PDefault.new()
	_drone_manager = DroneManager.new()
	_update_radius()
	
func _process(delta):
	_lines.clear() # clear previous drawing
	
	# DRAW SEARCH TEAM POSITION
	#-----------------------------------------------------------------------------------------------
	if _search_drone:
		var s := Vector3(_search_target_pos.x,0,_search_target_pos.y)
		var e := Vector3(_search_target_pos.x,_base_detection.position.y,_search_target_pos.y)
		_lines.create_line(s, e, Color.BLUE)
		_target_vis.position = Vector3(_search_target_pos.x, 0, _search_target_pos.y)
	
	#DRAW CONNEXION LINKS 
	#-----------------------------------------------------------------------------------------------
	_draw_links()

func _physics_process(delta):
	
	# UPDATE SIMULATION
	#-----------------------------------------------------------------------------------------------
	if not _simulating:
		if _perform_actions():
			return
		if (_run_simulation or _run_one_step):
			_simulation_step()
			_run_one_step = false
	
		
# Return if current physics frame needs to be skiped
func _perform_actions() -> bool:
	var skip_frame := false
	
	# reset simulation
	if _request_reset:	
		_target_vis.position = $Base.position
		_request_reset = false
		_next_id = 0
		for d in _drones.get_children():
			d.queue_free()
		_search_drone = null
		skip_frame = true
	
	if not _request_loading_frame.is_empty():
		# recreate drones
		_next_id = 0
		for s in _request_loading_frame:
			if _next_id < s["id"]:
				_next_id = s["id"]
			var state = _protocol.get_default_state()
			state["id"] = _next_id
			var d : Drone3D = _drone_scene.instantiate().init(s)
			d.set_show_vision(show_vision)
			d.set_vision_shape(_protocol.get_vision_shape())
			d.set_vision_meshes(_protocol.get_vision_meshes())
			d.position = s["position"]
			_drones.add_child(d)
			if s["id"] == 0:
				_search_drone = d
				_target_vis.position = Vector3(_search_target_pos.x, 0, _search_target_pos.y)
			emit_signal("add_drone", s["id"])
			emit_signal("update_drone_state", s)
		_next_id += 1
		_request_loading_frame = [] # DO NOT CLEAR REF FRAME !!!!
		skip_frame = true
			
		
	
	# Request switch protocol
	if _switch_protocol != null:
		_protocol = _switch_protocol
		for d in _drones.get_children():
			d.set_vision_shape(_protocol.get_vision_shape())
			d.set_vision_meshes(_protocol.get_vision_meshes())
			d.drone.state = _protocol.migrate_state(d.drone.state)
		_switch_protocol = null
		skip_frame = true
		
	# kill inactive
	if _kill_inactive:
		_kill_inactive = false
		for d in _drones.get_children():
			if not d.drone.state["active"]:
				emit_signal("remove_drone", d.drone.state["id"])
				d.queue_free()
		skip_frame = true
		
	# Manual drone deployement
	if _deploy_ground_pos != null and _next_id > 0:
		var target_pos = _deploy_ground_pos + Vector3(0,_base_detection.position.y, 0)
		_deploy_new_drone(target_pos)
		_deploy_ground_pos = null
		skip_frame = true
		
	# Append a new drone from base
	var drones_near_base = _base_detection.get_overlapping_bodies().filter(func(x): \
																	return x.drone.state["active"])
	var closest_to_base = drones_near_base.map(func(x): return \
					_base_detection.position.distance_squared_to(x.drone.state["position"])).min()
	var max_base_dist = _protocol.get_max_dist_from_base()
	if drones_near_base.is_empty() or (closest_to_base > max_base_dist*max_base_dist):
			_deploy_new_drone(_base_detection.position)
			skip_frame = true
			
	var drones = _drones.get_children()
	for d in drones:
		# Remove killed drones
		if d.drone.state["KILL"]:
			emit_signal("remove_drone", d.drone.state["id"])
			d.queue_free()
			skip_frame = true
			continue
		# show/hide inactive drones
		if not d.drone.state["active"]:
			d.visible = not _hide_inactive 
			
	
				
	return skip_frame
		
	
func _simulation_step() -> void:
	# LOCK ENV AND DO A SIMULATION STEP
	#-----------------------------------------------------------------------------------------------	
	_simulating = true # Place lock
	
	# Get all drones
	var drones3D = _drones.get_children()
	var drones : Array[Drone]
	drones.assign(drones3D.map(func(x): return x.drone))
	var prev_states : Array[Dictionary]
	prev_states.assign(drones.map(func(x): return x.state.duplicate(true)))
	
	
	var exec := _drone_manager.simulate(drones, _protocol, _base_detection.position)
	
	# Stop simulation on fail
	if exec.fail:
		emit_signal("exec_fail", exec)
		_run_simulation = false
	else:
		# move search drone
		if _search_drone:
			var offset : Vector2 = _search_target_pos - Vector2(_search_drone.position.x, \
																			_search_drone.position.z)
			var dist = offset.length()
			offset = offset.normalized() * clamp(dist, 0, _protocol.get_max_move_dist())
			_search_drone.drone.state["position"] += Vector3(offset.x, 0, offset.y)
			
		# send new state to gui
		for d in drones:
			emit_signal("update_drone_state", d.state)
		# Update visuals, move and wait for all movement to finish
		var tweens = drones3D.map(func(x): return x.update(movement_time))
		for t in tweens:
			await t.finished
		# Save new frame
		var states : Array[Dictionary]
		states.assign(drones.map(func(x): return x.state.duplicate(true)))
		
		var change := false
		if prev_states.size() != states.size():
			change = true
		else:
			for i in range(prev_states.size()):
				if change:
					break
					
				var ps = prev_states[i]
				var cs = states[i]
				# check for change
				var pkeys = ps.keys()
				var ckeys = cs.keys()

				if pkeys.size() != ckeys.size():
					change = true
					break
					
				for k in pkeys:
					if k not in ckeys:
						change = true
						break
					elif ps[k] != cs[k]:
						change = true
						break
		if change:
			emit_signal("new_frame", states, _search_target_pos)
		else:
			emit_signal("no_op")
					
						
	
	_simulating = false # Release lock
	
func _flat_dist(p1 : Vector3, p2: Vector3) -> float:
	return (p1.x-p2.x)*(p1.x-p2.x)+(p1.z-p2.z)*(p1.z-p2.z)
				
func _draw_links() -> void:
	var drones3D = _drones.get_children()
	var points : Array[Vector3] = []
	
	var arcs : Array = []
	for d in drones3D:
		if not d.drone.state["active"]:
			continue
			
		var Dmax : float = 7 * _protocol.D
		
		var others : Array = d.get_neighbours().filter(func(x): return x.drone.state["active"] \
			and (_flat_dist(d.position, x.position) <= Dmax*Dmax + 0.1) \
			and (x.drone.state["id"] < d.drone.state["id"] if _draw_directed_graph else true))
		
		
		if others.is_empty():
			continue
		
		for d2 in others:
			
			var new_arc := true
			for c in arcs:
				if d in c and d2 in c:
					new_arc = false
					break
			
			if new_arc:
				arcs.append([d, d2])
				points.append(d.position)
				points.append(d2.position)
			
	
	var others = _base_detection.get_overlapping_bodies().filter(func(x): return \
																			x.drone.state["active"])
	
	if not others.is_empty():
		for d in others:
			points.append($Base.position)
			points.append(d.position)
	
	# Generate graph mesh
	if not points.is_empty():
		_lines.create_graph(points, Color.CYAN, _draw_directed_graph)
		
			
func _update_radius() -> void:
	if not is_inside_tree(): await ready
	var r = _protocol.get_max_dist_from_base()
	var col := $Base/Detection/CollisionShape3D
	col.shape = SphereShape3D.new()
	col.shape.radius = r
	var vis := $Base/Detection/Visualization
	for c in vis.get_children():
		c.queue_free()
	vis.add_child(MeshCreator.create_circle(r, Color.GREEN))
	
func _set_show_vision(val : bool) -> void:
	if not is_inside_tree(): await ready
	show_vision = val
	$Base/Detection/Visualization.visible = show_vision
	for d in _drones.get_children():
		d.set_show_vision(show_vision)
	
func _deploy_new_drone(pos : Vector3) -> void:
	var state = _protocol.get_default_state()
	state["position"] = pos
	state["id"] = _next_id
	var d : Drone3D = _drone_scene.instantiate().init(state)
	d.set_show_vision(show_vision)
	d.set_vision_shape(_protocol.get_vision_shape())
	d.set_vision_meshes(_protocol.get_vision_meshes())
	d.position = pos
	# It's the search team
	if _next_id == 0:
		_search_drone = d
		_search_target_pos = Vector2(pos.x, pos.z)
	_drones.add_child(d)
	if _next_id == 0:
		var states : Array[Dictionary] = [d.drone.state.duplicate(true)]
		emit_signal("new_frame", states, _search_target_pos)
	emit_signal("add_drone", _next_id)
	emit_signal("update_drone_state", state)
	_next_id += 1
	

