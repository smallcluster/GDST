@tool
extends CharacterBody3D
class_name Drone3D

# PUBLIC ATTRIBUTES
@export var D : float = 0.3 : set = _set_D
@export var id : int = 0 : set = _set_id
@export var show_radius : bool = false : set = _set_show_radius
@export var warn : bool = false : set = _set_warn
@export var not_main : bool = false : set = _set_not_main
@export var active : bool = true : set = _set_active

# PRIVATE ATTRIBUTES
@onready var _drone : Drone
@onready var _detection_shape := $Detection/CollisionShape3D
@onready var _detection := $Detection
	
func get_drone() -> Drone :
	return _drone
	
func update() -> void:
	var state := _drone.state
	warn = state["light"]
	not_main = state["not_main"]
	# update active last as it disable warn & not_main
	active = state["active"]
	
func set_pos(pos : Vector3) -> void:
	if not is_inside_tree(): await ready
	position = pos
	_drone.state["position"] = pos
	
func move(speed : float = 0.05) -> Tween:
	var TW = create_tween()
	TW.tween_property(self, "position", _drone.state["position"], speed)
	return TW
	
func get_neighbours() -> Array:
	return _detection.get_overlapping_bodies().filter(func(x): return x.id != id)
	
# -- PRIVATE METHODS --	
func _ready():
	# setup detection radius and visualisations
	_update_detection_radius(D)
	# Set up drone object
	var state = {
		"id" : id,
		"light" : warn,
		"active" : active,
		"position" : position,
		"not_main" : not_main
	}
	
	var get_neighbours_func := func(): return _detection.get_overlapping_bodies() \
	.map(func(x): return x.get_drone()) \
	.filter(func(x): return x.state["id"] != _drone.state["id"])
	
	_drone = Drone.new(state, get_neighbours_func)

func _process(delta):
	pass
	# Render drone status as billboards
#	var cam = get_viewport().get_camera_3d()
#	if cam:
#		var inds := $Indicators
#		var camera_pos = cam.global_transform.origin
#		camera_pos.y = 0
#		inds.look_at(camera_pos, Vector3(0, 1, 0))
		

# -- SETTERS --
func _set_D(val : float) -> void:
	if not is_inside_tree(): await ready
	D = val
	_update_detection_radius(D)
		
func _set_warn(val : bool) -> void:
	if not is_inside_tree(): await ready
	warn = val
	_drone.state["light"] = warn
	_update_visuals()
	
func _set_not_main(val : bool) -> void:
	if not is_inside_tree(): await ready
	not_main = val
	_drone.state["not_main"] = not_main
	_update_visuals()
	
func _set_active(val : bool) -> void:
	if not is_inside_tree(): await ready
	active = val
	_drone.state["active"] = active
	_update_visuals()
		
func _set_id(val : int) -> void:
	if not is_inside_tree(): await ready
	id = val
	$LabelID.text = str(val)
	_drone.state["id"] = id
	
func _set_show_radius(val : bool) -> void:
	if not is_inside_tree(): await ready
	show_radius = val
	$Visualization.visible = val and active

# -- HELPERS --
func _update_visuals() -> void:
	$Indicators/Death.visible = not active
	$Visualization.visible = show_radius and active
	$Indicators/Warning.visible = warn and active
	$Indicators/Branch.visible = not_main and active
	# Place status correctly
	var w = 0.256
	var ind = $Indicators.get_children().filter(func(x): return x.visible)
	var n = ind.size()
	var dx = n*w / 4 if n > 1 else 0
	for i in range(n):
		var sprite = ind[i]
		sprite.position = Vector3(i*w-dx, 0, 0)

func _update_detection_radius(D : float) -> void:
	var Dmax := 7 * D
	var Dc := 2 * D
	var Dp := Dmax - D
	_set_circles(Dmax, Dp, Dc, D)
	_detection_shape.shape = SphereShape3D.new()
	_detection_shape.shape.radius = Dmax
	
func _set_circles(Dmax : float, Dp : float, Dc : float, D : float) -> void:
	var circles_root = $Visualization
	for c in circles_root.get_children():
		c.queue_free()
	circles_root.add_child(MeshCreator.create_circle(Dmax, Color.BLUE))
	circles_root.add_child(MeshCreator.create_circle(Dp, Color.GREEN))
	circles_root.add_child(MeshCreator.create_circle(Dc, Color.ORANGE))
	circles_root.add_child(MeshCreator.create_circle(D, Color.RED))
	
	
	
	
