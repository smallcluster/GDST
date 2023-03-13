@tool
extends Node3D
class_name DroneManager3D

@export var D := 0.3 : set = set_D
@export var show_radius := false : set = _set_show_radius
@export var movement_time := 0.05



@onready var _drones = $Drones
@onready var _lines : Lines3D = $Lines3D as Lines3D
@onready var _base = $Base
@onready var _base_detection : Area3D = $Base/Detection
@onready var _target_vis = $SearchTeam
var _simulating := false # Act as a lock
var _drone_manager : DroneManager
var _protocol : Protocol
var _next_id := 0
var _search_drone : Drone3D = null
var _search_target_pos : Vector2
var _drone_scene := preload("res://Sim/Drone3D.tscn")
var _request_reset := false
var _hide_inactive := false


# Link visualization
var _link_filter = null
var _link_reducer = null

func set_protocol(index : int) -> void:
	if index == 0:
		_protocol = BCProtocol.new()
		_protocol.D = D
	elif index == 1:
		_protocol = SaveProtocol.new()
		_protocol.D = D
		_protocol.base_pos = _base_detection.position
		
	for d in _drones.get_children():
		d.drone.state = _protocol.migrate_state(d.drone.state)
	

func set_D(val : float) -> void:
	if not is_inside_tree(): await ready
	D = val
	_protocol.D = D
	for d in _drones.get_children():
		d.D = D
	_update_radius()
	
func hide_inactive(val : bool) -> void:
	_hide_inactive = val
	for d in _drones.get_children():
		if not d.drone.state["active"]:
			d.visible = val
			
func set_link_pipeline(op, red) -> void:
	_link_filter = op
	_link_reducer = red
		
func reset() -> void:
	_request_reset = true
	
func _ready():
	_protocol = BCProtocol.new()
	_protocol.D = D
	_drone_manager = DroneManager.new()
	set_D(D)
	
func _physics_process(delta):
	if Engine.is_editor_hint():
		return
		
	# -- UPDATE --
	
	# reset simulation
	if _request_reset and not _simulating:	
		_target_vis.position = _base.position
		_request_reset = false
		_next_id = 0
		for d in _drones.get_children():
			d.queue_free()
			_search_drone = null
		return
	
	# Simulate
	var drones3D : Array[Drone3D]
	drones3D.assign(_drones.get_children())
	_simulation_loop(drones3D)
	
	# -- DRAWING --
	_lines.clear() # clear previous lines
	#_draw_all_connections(drones3D)
	_draw_links(drones3D)
	
	# Draw beacon from search_team target
	if _search_drone:
		var s := Vector3(_search_target_pos.x,0,_search_target_pos.y)
		var e := Vector3(_search_target_pos.x,_base_detection.position.y,_search_target_pos.y)
		_lines.create_line(s, e, Color.BLUE)
		
	
	
func _simulation_loop(drones3D : Array[Drone3D]) -> void:
	if _simulating:
		return
		
	_simulating = true # Place lock
	
	# Append a new drone ?
	var drones_near_base = _base_detection.get_overlapping_bodies().filter(
		func(x): return x.drone.state["active"]
	)
	var closest_to_base = drones_near_base \
		.map(func(x): return _base_detection.position.distance_squared_to(x.drone.state["position"])) \
		.min()
	
	# TODO : CORRECT BUG (2 drones launched) IF MOVEMENT TIME IS TOO LOW !!!!!
	if drones_near_base.is_empty() or closest_to_base >= 9*D*D:
		await _deploy_new_drone().finished
		
	# move search drone
	if _search_drone:
		var offset : Vector2 = _search_target_pos - Vector2(_search_drone.position.x, _search_drone.position.z)
		var dist = offset.length()
		offset = offset.normalized() * clamp(dist, 0, D)
		_search_drone.drone.state["position"] += Vector3(offset.x, 0, offset.y)
		
	# simulates all drones
	var drones : Array[Drone]
	drones.assign(drones3D.map(func(x): return x.drone))
	_drone_manager.simulate(drones, _protocol)
	
	# Update visualisations
	for d in drones3D:
		d.update()
		
	# Move and wait for all movement to finish
	var tweens = drones3D.map(func(x): return x.move(movement_time))
	for t in tweens:
		await t.finished
		
	# Post processing
	for d in drones3D:
		if d.drone.state["KILL"]:
			d.queue_free()
		elif not d.drone.state["active"]:
			if d.visible != not _hide_inactive:
				d.visible = not _hide_inactive
				
	_simulating = false # Release lock
	
				
func _draw_links(drones3D : Array[Drone3D]) -> void:
	var points : Array[Vector3] = []
	
	if _link_filter == null:
		return
	
	for d in drones3D:
		if not d.drone.state["active"]:
			continue
			
		var others : Array = d.get_neighbours()
		var others_state = others.map(func(x): return x.drone.state).filter(func(x): return _link_filter.call(d.drone.state, x))
		
		if others_state.is_empty():
			continue
		
		if _link_reducer:
			var state_choice = others_state.reduce(_link_reducer, others_state[0])
			var choice = others.filter(func(x): return x.id == state_choice["id"])[0]
			points.append(d.position)
			points.append(choice.position)
		else:
			for d2 in others:
				points.append(d.position)
				points.append(d2.position)
	
	var others = _base_detection.get_overlapping_bodies().filter(func(x): return x.drone.state["active"])
	var others_state = others.map(func(x): return x.drone.state)
	
	if not others_state.is_empty():
		if _link_reducer:
			var state_choice = others_state.reduce(_link_reducer, others_state[0])
			var choice = others.filter(func(x): return x.id == state_choice["id"])[0]
			points.append(_base.position)
			points.append(choice.position)
		else:
			for d in others:
				points.append(_base.position)
				points.append(d.position)
	
	# Generate graph mesh
	if not points.is_empty():
		_lines.create_graph(points, Color.CYAN)
			
func _update_radius() -> void:
	if not is_inside_tree(): await ready
	var col := $Base/Detection/CollisionShape3D
	col.shape = SphereShape3D.new()
	col.shape.radius = 7 * D
	var vis := $Base/Detection/Visualization
	for c in vis.get_children():
		c.queue_free()
	vis.add_child(MeshCreator.create_circle(7*D, Color.RED))
	vis.add_child(MeshCreator.create_circle(3*D, Color.GREEN))
	
func _set_show_radius(val : bool) -> void:
	if not is_inside_tree(): await ready
	show_radius = val
	$Base/Detection/Visualization.visible = show_radius
	for d in _drones.get_children():
		d.show_radius = show_radius
	
func _deploy_new_drone() -> Tween:
	var state = _protocol.get_default_state()
	var target_pos = _base_detection.position
	state["position"] = target_pos
	state["id"] = _next_id
	var d : Drone3D = _drone_scene.instantiate().init(_next_id, state, D)
	d.show_radius = show_radius
	
	# It's the search team
	if _next_id == 0:
		_search_drone = d
		_search_target_pos = Vector2(target_pos.x, target_pos.z)
		
	_next_id += 1
	d.position = _base_detection.position + Vector3.DOWN * 7*D
	_drones.add_child(d)
	return d.move(movement_time)
	
func deploy_ground_drone_at(pos : Vector3) -> void:
	var state = _protocol.get_default_state()
	var target_pos = pos + Vector3(0,_base_detection.position.y, 0)
	state["position"] = target_pos
	state["id"] = _next_id
	var d : Drone3D = _drone_scene.instantiate().init(_next_id, state, D)
	d.show_radius = show_radius
	_next_id += 1
	d.position = target_pos
	_drones.add_child(d)
	
	
func set_search_target(pos : Vector2) -> void:
	if _search_drone:
		_search_target_pos = pos
		_target_vis.position = Vector3(pos.x, _base.position.y, pos.y)
	
			
func kill_inactive() -> void:
	for d in _drones.get_children():
		if not d.drone.state["active"]:
			d.queue_free()
	

