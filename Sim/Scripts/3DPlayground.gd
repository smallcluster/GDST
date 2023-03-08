extends Node3D

@onready var _drone_manager : DroneManager3D = $"3DDroneManager"
@onready var _viewport : Control = $GUI/Control/HSplitContainer/Control
@onready var _cam : Camera3D = $Camera3D
@onready var _target_vis = $"3DDroneManager/SearchTeam"
@onready var _dir_light : DirectionalLight3D = $DirectionalLight3D

func _process(delta):
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var position2D = get_viewport().get_mouse_position()
		if _viewport.get_global_rect().has_point(position2D):
			var dropPlane  = Plane(Vector3(0, 1, 0), 0)
			var position3D = dropPlane.intersects_ray(
				_cam.project_ray_origin(position2D),
				_cam.project_ray_normal(position2D))
			
			var target = Vector2(position3D.x, position3D.z)
			_drone_manager.set_search_target(target)
			_target_vis.position = position3D
			

# -- GUI EVENTS --
func _on_show_radius_toggled(button_pressed):
	_drone_manager.show_radius = button_pressed


func _on_top_down_view_toggled(button_pressed):
	if button_pressed:
		_cam.rotation = Vector3(-PI/2, 0, 0)
		_cam.set_orthogonal(10, 0.05, 100)
	else:
		_cam.rotation = Vector3(-PI/3, 0, 0)
		_cam.set_perspective(90, 0.05, 100)


func _on_disable_shadows_toggled(button_pressed):
	_dir_light.shadow_enabled = not button_pressed
