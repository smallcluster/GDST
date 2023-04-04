extends RigidBody3D
class_name Drone3D

# PUBLIC ATTRIBUTES

var drone : Drone

# PRIVATE ATTRIBUTES
@onready var _detection_shape := $Detection/CollisionShape3D
@onready var _detection := $Detection
var _show_vision : bool = false
var _initial_state : Dictionary

func update(time : float = 0.05) -> Tween:
	update_visuals()
	return _move(time)
	
func set_show_vision(val : bool) -> void:
	_show_vision = val
	update_visuals()

func update_visuals() -> void:
	if not is_inside_tree(): await ready
	# show vision meshes
	$Visualization.visible = _show_vision and drone.state["active"]
	
	# id
	$LabelID.text = str(drone.state["id"])
	
	# Change color
	var mesh = $Mesh
	if not drone.state["active"] :
		mesh.set_instance_shader_parameter("color", Color.LIGHT_GRAY)
	elif drone.state.has("light") and drone.state["light"]:
		mesh.set_instance_shader_parameter("color", Color.RED)
	elif drone.state.has("border") and drone.state["border"]:
		mesh.set_instance_shader_parameter("color", Color.MAGENTA)
	else:
		mesh.set_instance_shader_parameter("color", Color(0.05, 0.05, 0.05))

func set_vision_shape(collision_shape : CollisionShape3D) -> void:
	if not is_inside_tree() : await ready
	_detection_shape.position = collision_shape.position
	_detection_shape.shape = collision_shape.shape
		
func set_vision_meshes(meshes : Array[MeshInstance3D]) -> void:
	var root = $Visualization
	for c in root.get_children():
		c.queue_free()
		
	for m in meshes:
		root.add_child(m)
	
func get_neighbours() -> Array:
	return _detection.get_overlapping_bodies().filter(func(x): return x.drone.state["id"] != drone.state["id"])
	
func init(state) -> Drone3D:
	_initial_state = state
	return self
	
# -- PRIVATE METHODS --	
func _ready():
	# setup drone object
	var get_neighbours_func := func(): return (_detection.get_overlapping_bodies() if drone.state["active"] else [])  \
	.map(func(x): return x.drone) \
	.filter(func(x): return x.state["id"] != drone.state["id"])
	drone = Drone.new(_initial_state, get_neighbours_func)
	
func _move(time : float = 0.05) -> Tween:
	var TW = create_tween()
	TW.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	TW.tween_property(self, "position", drone.state["position"], time)
	TW.tween_callback(func(): position = drone.state["position"])
	return TW
	
	
	
	
	
