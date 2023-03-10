extends SubViewport

signal perspective_cam

@onready var _drone_manager : DroneManager3D = $"3DDroneManager"
@onready var _cam : Camera3D = $Camera3D
@onready var _dir_light : DirectionalLight3D = $DirectionalLight3D
@onready var _floor = $Floor
var _clicked := false

func _process(delta):
	_floor.position.x = _cam.global_position.x
	_floor.position.z = _cam.global_position.z
	
# -- GUI EVENTS --
func show_radius(button_pressed):
	_drone_manager.show_radius = button_pressed

func top_down_view(button_pressed):
	if button_pressed:
		_cam.global_position.y = 6
		_cam.switch_to_orthogonal()
	else:
		_cam.switch_to_perspective()

func disable_shadows(button_pressed):
	_dir_light.shadow_enabled = not button_pressed
	
func move_time_value_changed(value):
	_drone_manager.movement_time = value
	
func _move_search_target(position2D) -> void:
	var dropPlane  = Plane(Vector3(0, 1, 0), 0)
	var position3D = dropPlane.intersects_ray(
		_cam.project_ray_origin(position2D),
		_cam.project_ray_normal(position2D))
	if position3D:
		var target = Vector2(position3D.x, position3D.z)
		_drone_manager.set_search_target(target)
	
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_clicked = event.pressed
			if event.pressed:
				_move_search_target(event.position)
				
	if event is InputEventMouseMotion  and _clicked:
		_move_search_target(event.position)
		
func reset_view():
	_cam.switch_to_perspective()
	_cam.position = Vector3(0, 6, 3)
	_cam.rotation_degrees = Vector3(-60, 0, 0)
	
func reset_simulation():
	_drone_manager.reset()
	
func hide_inactive_drones(val : bool) -> void:
	_drone_manager.hide_inactive(val)
	

func _on_camera_3d_perspective_cam():
	emit_signal("perspective_cam")# Replace with function body.
