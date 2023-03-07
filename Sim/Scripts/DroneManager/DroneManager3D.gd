@tool
extends Node3D


@export var D := 0.45 : set = set_D
@export var show_radius := false : set = _set_show_radius

@onready var _drones = $Drones
@onready var _lines : Lines3D = $Lines3D as Lines3D
@onready var _base = $Base
var _simulating := false # Act as a lock
var _base_height := 3.0
var _drone_manager : DroneManager
var _protocol : BCProtocol
var _next_id := 0

func set_D(val : float) -> void:
	D = val
	_protocol.D = D
	for d in _drones.get_children():
		d.D = D
	_update_radius()
	
func _ready():
	_protocol = BCProtocol.new()
	_drone_manager = DroneManager.new()
	set_D(D)
	
func _process(delta):
	if Engine.is_editor_hint():
		return
	# UPDATE
	var drones3D : Array[Drone3D]
	drones3D.assign(_drones.get_children())
	_simulation_loop(drones3D)
	# DRAWING
	_lines.clear() # clear previous lines
	_draw_all_connections(drones3D)
	
func _simulation_loop(drones3D : Array[Drone3D]) -> void:
	if _simulating:
		return
	_simulating = true # Place lock
	var drones : Array[Drone]
	drones.assign(drones3D.map(func(x): return x.get_drone()))
	_drone_manager.simulate(drones, _protocol)
	# Update visualisations
	for d in drones3D:
		d.update()
	# Move and wait for all movement to finish
	var tweens = drones3D.map(func(x): return x.move())
	for t in tweens:
		await t.finished
	_simulating = false # Release lock
	
func _draw_all_connections(drones3D : Array[Drone3D]) -> void:
	var n := drones3D.size()
	for i in range(n):
		for j in range(i, n):
			_lines.create_line(drones3D[i].position, drones3D[j].position)
			
func _update_radius() -> void:
	if not is_inside_tree(): await ready
	var col := $Base/Detection/CollisionShape3D
	col.shape = SphereShape3D.new()
	col.shape.radius = 7 * D
	var vis := $Base/Visualization
	for c in vis.get_children():
		c.queue_free()
	vis.add_child(MeshCreator.create_circle(7*D, Color.RED))
	vis.add_child(MeshCreator.create_circle(3*D, Color.GREEN))
	
func _set_show_radius(val : bool) -> void:
	show_radius = val
	$Base/Visualization.visible = show_radius
	for d in _drones.get_children():
		d.show_radius = show_radius
	
	

