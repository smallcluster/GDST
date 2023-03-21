@tool
extends RigidBody3D
class_name Drone3D

# PUBLIC ATTRIBUTES
@export var D : float = 0.3 : set = _set_D
@export var id : int = 0 : set = _set_id
@export var show_radius : bool = false : set = _set_show_radius
@export var warn : bool = false : set = _set_warn
@export var border : bool = false : set = _set_border
@export var active : bool = true : set = _set_active
@export var color : Color = Color(0.05, 0.05, 0.05): set = _set_color

@export var use_cylinder : bool = false : set = _set_use_cylinder
@export var cylinder_depth : float = 0.6 : set = _set_cylinder_depth

var drone : Drone

# PRIVATE ATTRIBUTES
@onready var _detection_shape := $Detection/CollisionShape3D
@onready var _detection := $Detection

var _initial_state : Dictionary
	
func update() -> void:
	var state := drone.state
	warn = state.has("light") and state["light"]
	border = state.has("border") and state["border"]
	active = state["active"]
	
func set_pos(pos : Vector3) -> void:
	if not is_inside_tree(): await ready
	position = pos
	drone.state["position"] = pos
	
func move(time : float = 0.05) -> Tween:
	var TW = create_tween()
	TW.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	TW.tween_property(self, "position", drone.state["position"], time)
	TW.tween_callback(func(): position = drone.state["position"])
	return TW
	
func get_neighbours() -> Array:
	return _detection.get_overlapping_bodies().filter(func(x): return x.id != id)
	
func init(id, state, radius) -> Drone3D:
	_initial_state = state
	self.id = id
	D = radius
	return self
	
# -- PRIVATE METHODS --	
func _ready():
	# setup drone object
	var get_neighbours_func := func(): return (_detection.get_overlapping_bodies() if drone.state["active"] else [])  \
	.map(func(x): return x.drone) \
	.filter(func(x): return x.state["id"] != drone.state["id"])
	drone = Drone.new(_initial_state, get_neighbours_func)
	
	
# -- SETTERS --
func _set_use_cylinder(val : bool) -> void:
	if not is_inside_tree(): await ready
	use_cylinder = val
	_update_vision_shape()
	
func _set_cylinder_depth(val: float) -> void:
	if not is_inside_tree(): await ready
	cylinder_depth = val
	_update_vision_shape()


func _set_D(val : float) -> void:
	if not is_inside_tree(): await ready
	D = val
	_update_vision_shape()
	
func _update_vision_shape() -> void:
	var Dmax := 7 * D
	var Dc := 2 * D
	var Dp := Dmax - D
	
	if use_cylinder:
		_set_cylinders(Dmax, Dp, Dc, D)
		_detection_shape.shape = CylinderShape3D.new()
		_detection_shape.shape.radius = Dmax
		_detection_shape.shape.height = cylinder_depth
		_detection_shape.position = Vector3(0,-cylinder_depth/2,0)
	else:
		_set_circles(Dmax, Dp, Dc, D)
		_detection_shape.shape = SphereShape3D.new()
		_detection_shape.shape.radius = Dmax
		_detection_shape.position = Vector3.ZERO
		
	
func _set_warn(val : bool) -> void:
	if not is_inside_tree(): await ready
	warn = val
	drone.state["light"] = warn
	_update_visuals()
	
func _set_border(val : bool) -> void:
	if not is_inside_tree(): await ready
	border = val
	drone.state["border"] = border
	_update_visuals()
	
func _set_active(val : bool) -> void:
	if not is_inside_tree(): await ready
	active = val
	drone.state["active"] = active
	_update_visuals()
		
func _set_id(val : int) -> void:
	if not is_inside_tree(): await ready
	id = val
	$LabelID.text = str(val)
	drone.state["id"] = id
	
func _set_show_radius(val : bool) -> void:
	if not is_inside_tree(): await ready
	show_radius = val
	$Visualization.visible = val and active
	
func _set_color(val : Color) -> void:
	if not is_inside_tree(): await ready
	color = val
	$Mesh.set_instance_shader_parameter("color", val)

# -- HELPERS --
func _update_visuals() -> void:
	$Visualization.visible = show_radius and active
	# Change color
	if not active:
		color = Color.LIGHT_GRAY
	elif warn:
		color = Color.RED
	elif border:
		color = Color.MAGENTA
	else:
		color = Color(0.05, 0.05, 0.05)
	
func _set_circles(Dmax : float, Dp : float, Dc : float, D : float) -> void:
	var vis_root = $Visualization
	for c in vis_root.get_children():
		c.queue_free()
	vis_root.add_child(MeshCreator.create_circle(Dmax, Color.BLUE))
	vis_root.add_child(MeshCreator.create_circle(Dp, Color.GREEN))
	vis_root.add_child(MeshCreator.create_circle(Dc, Color.ORANGE))
	vis_root.add_child(MeshCreator.create_circle(D, Color.RED))
	
func _set_cylinders(Dmax : float, Dp : float, Dc : float, D : float) -> void:
	var vis_root = $Visualization
	for c in vis_root.get_children():
		c.queue_free()
		
	vis_root.add_child(MeshCreator.create_cylinder(Dmax, cylinder_depth,Color.BLUE))
	vis_root.add_child(MeshCreator.create_cylinder(Dp, cylinder_depth, Color.GREEN))
	vis_root.add_child(MeshCreator.create_cylinder(Dc, cylinder_depth, Color.ORANGE))
	vis_root.add_child(MeshCreator.create_cylinder(D, cylinder_depth, Color.RED))
	#circles_root.add_child(MeshCreator.create_circle(sqrt(Dmax*Dmax+cylinder_depth*cylinder_depth), Color.WHITE))
	
	
	
	
