@tool
extends CharacterBody3D
class_name Drone3D

@onready var _drone : Drone3DImpl = $Drone as Drone3DImpl

@onready var _detection_shape := $Detection/CollisionShape3D

# IN METTER
@export var D : float = 0.45 : set = set_D
@export var id : int = 0 : set = _set_id
@export var show_radius : bool : set = _set_show_radius
@export var warn : bool = false : set = _set_warn
@export var not_main : bool = false : set = _set_not_main
@export var dead : bool = false : set = _set_dead


func get_drone() -> Drone :
	return _drone
	
func set_D(val : float) -> void:
	if not is_inside_tree(): await ready
	D = val
	update_radius()

func update_radius() -> void:
	var Dmax := 7 * D
	var Dc := 2 * D
	var Dp := Dmax - D
	
	_detection_shape.shape = SphereShape3D.new()
	_detection_shape.shape.radius = Dmax
	
	_set_circles(Dmax, Dp, Dc, D)
	
func kill() -> void:
	$Visualization.visible = false
	for i in $Indicators.get_children():
		i.visible = false
	var pos = Vector3(0,0.297, 0)
	var spr = $Indicators/Death
	spr.position = Vector3.ZERO
	spr.visible = true
	
func revive() -> void:
	$Visualization.visible = show_radius
	for i in $Indicators.get_children():
		i.visible = false
	
func set_light_status(warning : bool, not_main : bool) -> void:
	var w = 0.256
	$Indicators/Warning.visible = warning
	$Indicators/Branch.visible = not_main
	var ind = $Indicators.get_children().filter(func(x): return x.visible)
	var n = ind.size()
	print(n)
	var dx = n*w / 4 if n > 1 else 0
	for i in range(n):
		var sprite = ind[i]
		sprite.position = Vector3(i*w-dx, 0, 0)
		
	
func _set_warn(val : bool) -> void:
	if not is_inside_tree(): await ready
	warn = val
	if val:
		dead = false
	set_light_status(warn, not_main)
	
func _set_not_main(val : bool) -> void:
	if not is_inside_tree(): await ready
	not_main = val
	if val:
		dead = false
	set_light_status(warn, not_main)
	
func _set_dead(val : bool) -> void:
	if not is_inside_tree(): await ready
	dead = val
	if val:
		warn = false
		not_main = false
		kill()
	else:
		revive()
		
func _set_id(val : int) -> void:
	if not is_inside_tree(): await ready
	id = val
	$LabelID.text = str(val)
	
func _set_show_radius(val : bool) -> void:
	if not is_inside_tree(): await ready
	show_radius = val
	$Visualization.visible = val and not dead
	

func _ready():
	var Dmax := 7 * D
	var Dc := 2 * D
	var Dp := Dmax - D
	_set_circles(Dmax, Dp, Dc, D)
			
func _process(delta):
	var cam = get_viewport().get_camera_3d()
	if cam:
		var camera_pos = cam.global_transform.origin
		#camera_pos.y = 0
		$Indicators.look_at(camera_pos, Vector3(0, 1, 0))
		
		
func move() -> Tween:
	var TW = create_tween()
	TW.tween_property(self, "position", _drone.state["position"], 1)
	return TW
	
	
func _create_cirle_mesh(radius : float, color : Color, resolution : int = 32) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	var mat := ORMMaterial3D.new()
	mesh_inst.mesh = mesh
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	
	var cursor := Vector3(0, radius, 0)
	var rot := (360.0 * PI) / (resolution * 180.0)
	for i in range(resolution):
		mesh.surface_add_vertex(cursor)
		cursor = cursor.rotated(Vector3(0, 0, 1), rot)
		mesh.surface_add_vertex(cursor)
	mesh.surface_end()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.disable_receive_shadows = true
	mat.no_depth_test = true
	mat.render_priority = 10
	return mesh_inst
	
func _set_circles(Dmax : float, Dp : float, Dc : float, D : float) -> void:
	# Create cirlces
	var circles_root = $Visualization
	for c in circles_root.get_children():
		c.queue_free()
	circles_root.add_child(_create_cirle_mesh(Dmax, Color.BLUE))
	circles_root.add_child(_create_cirle_mesh(Dp, Color.GREEN))
	circles_root.add_child(_create_cirle_mesh(Dc, Color.ORANGE))
	circles_root.add_child(_create_cirle_mesh(D, Color.RED))
	
	
	
	
