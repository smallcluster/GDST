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
var _protocol : BCProtocol
var _next_id := 0
var _search_drone : Drone3D = null
var _search_target_pos : Vector2
var _drone_scene := preload("res://Sim/Drone3D.tscn")
var _request_reset := false
var _hide_inactive := false

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
		if not d.get_drone().state["active"]:
			d.visible = val
	
func reset() -> void:
	_request_reset = true
	
func _ready():
	_protocol = BCProtocol.new()
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
	_draw_my_connections(drones3D)
	
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
		func(x): return x.get_drone().state["active"]
	)
	var closest_to_base = drones_near_base \
		.map(func(x): return _base_detection.position.distance_squared_to(x.get_drone().state["position"])) \
		.min()
	
	# TODO : CORRECT BUG (2 drones launched) IF MOVEMENT TIME IS TOO LOW !!!!!
	if drones_near_base.is_empty() or closest_to_base > 9*D*D:
		await _deploy_new_drone().finished
		
	# simulates all drones
	var drones : Array[Drone]
	drones.assign(drones3D.map(func(x): return x.get_drone()))
	_drone_manager.simulate(drones, _protocol)
	
	# move search drone
	if _search_drone:
		var offset : Vector2 = _search_target_pos - Vector2(_search_drone.position.x, _search_drone.position.z)
		var dist = offset.length()
		offset = offset.normalized() * clamp(dist, 0, D)
		_search_drone.get_drone().state["position"] += Vector3(offset.x, 0, offset.y)
	
	# Update visualisations
	for d in drones3D:
		d.update()
		
	# Move and wait for all movement to finish
	var tweens = drones3D.map(func(x): return x.move(movement_time))
	for t in tweens:
		await t.finished
		
	# Hide inactive drone if necessary
	for d in drones3D:
		if not d.get_drone().state["active"]:
			if d.visible != not _hide_inactive:
				d.visible = not _hide_inactive
		
	_simulating = false # Release lock
	
func _draw_all_connections(drones3D : Array[Drone3D]) -> void:
	var points : Array[Vector3] = []
	
	var n := drones3D.size()
	for i in range(n):
		if not drones3D[i].get_drone().state["active"]:
				continue
		for j in range(i+1, n):
			if not drones3D[j].get_drone().state["active"]:
				continue
			if drones3D[i].position.distance_squared_to(drones3D[j].position) <= 49*D*D:
				points.append(drones3D[i].position)
				points.append(drones3D[j].position)
	
	for d in _base_detection.get_overlapping_bodies():
		if d.get_drone().state["active"]:
			points.append(_base_detection.position)
			points.append(d.position)
	
	# Generate graph mesh
	if not points.is_empty():
		_lines.create_graph(points, Color.CYAN)
				
func _draw_my_connections(drones3D : Array[Drone3D]) -> void:
	var points : Array[Vector3] = []
	
	for d in drones3D:
		if not d.get_drone().state["active"]:
			continue
		var others : Array = d.get_neighbours() \
		.filter(func(x): return x.id < d.id and x.get_drone().state["active"])
		if others.is_empty():
			continue
		var max = others[0]
		for o in others:
			if o.id > max.id:
				max = o
		points.append(d.position)
		points.append(max.position)
	
	var base_n = _base_detection.get_overlapping_bodies().filter(func(x): return x.get_drone().state["active"])
	if not base_n.is_empty():
		var max = base_n[0]
		for d in base_n:
			if d.id > max.id:
				max = d
		points.append(_base_detection.position)
		points.append(max.position)
	
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
	var d := _drone_scene.instantiate()
	d.D = D
	d.show_radius = show_radius
	d.id = _next_id
	var target_pos = _base_detection.position
	
	# deploy search team
	if _next_id == 0:
		_search_drone = d
		_search_target_pos = Vector2(target_pos.x, target_pos.z)
		
	_next_id += 1
	d.position = _base.position
	_drones.add_child(d)
	d.get_drone().state["position"] = target_pos
	return d.move(movement_time)
	
func set_search_target(pos : Vector2) -> void:
	if _search_drone:
		_search_target_pos = pos
		_target_vis.position = Vector3(pos.x, _base.position.y, pos.y)
	
			
			
	

