extends Camera3D

var speed := 5

signal orthogonal_cam
signal perspective_cam

var _rotating := false
var _panning := false
var _zooming := false
var _zoom := 10.0
var _is_orthogonal := false
var _prev_mouse := Vector2(0,0)
var _mouse := Vector2(0,0)
var _rotation_pivot = null
var _zoom_target = null

@onready var _tools = get_node("/root/Tools")

func _input(event):
	
	if event is InputEventMouse:
		_prev_mouse = _mouse
		_mouse = event.position
	
	# stop panning
	if event is InputEventKey:
		if event.keycode == KEY_SHIFT and _tools.current != _tools.ToolChoice.PAN_VIEW:
			if not event.pressed:
				_panning = false
		
		
	if event is InputEventMouseButton:
		
		# Tool controls
		if event.button_index == MOUSE_BUTTON_LEFT:
			if _tools.current == _tools.ToolChoice.PAN_VIEW:
				_panning = true and event.pressed
				_rotating = false
				_zooming = false
			elif _tools.current == _tools.ToolChoice.ROTATE_VIEW:
				_panning = false
				_rotating = true and event.pressed
				_zooming = false
				_rotation_pivot = _mouse_to_floor(_mouse)
			elif _tools.current == _tools.ToolChoice.ZOOM_VIEW:
				_panning = false
				_rotating = false
				_zooming = true and event.pressed
				_zoom_target = _mouse_to_floor(_mouse)
			
		# Alternative controls
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if Input.is_key_pressed(KEY_SHIFT):
				_panning = true and event.pressed
			_rotating = event.pressed and not _panning
			if _rotating:
				_rotation_pivot = _mouse_to_floor(_mouse)
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var dir = -1 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else 1
			if _is_orthogonal:
				var old_pos = _mouse_to_floor(_mouse)
				_zoom += -dir*_zoom*0.05
				set_orthogonal(_zoom, 0.05, 100)
				var new_pos = _mouse_to_floor(_mouse)
				var offset = new_pos-old_pos
				global_translate(-offset)
			else:
				var pivot = _mouse_to_floor(_mouse)
				if pivot:
					var offset = pivot - position
					global_translate(dir*offset*0.05)
			
	if event is InputEventMouseMotion:
		
		if _rotating and _rotation_pivot != null:
			if _is_orthogonal:
				switch_to_perspective()
			var offset = position - _rotation_pivot
			var angle_y = -(_mouse.x-_prev_mouse.x)*0.01
			var angle_x = -(_mouse.y-_prev_mouse.y)*0.01
			
			if rad_to_deg(rotation.x + angle_x)  <= -90:
				angle_x = deg_to_rad(-89) - rotation.x
			elif rad_to_deg(rotation.x + angle_x)  >= -5:
				angle_x = deg_to_rad(-5) - rotation.x
				
			offset = offset.rotated(global_transform.basis.x, angle_x)
			offset = offset.rotated(Vector3(0,1,0), angle_y)
			position = _rotation_pivot + offset
			rotate_y(angle_y)
			rotate(global_transform.basis.x, angle_x)
			
		elif _zooming and _zoom_target != null:
			var dir = event.relative.y*0.1
			
			if _is_orthogonal:
				_zoom += -dir*_zoom*0.05
				set_orthogonal(_zoom, 0.05, 100)
				var offset = _zoom_target - position
				offset.y = 0
				global_translate(dir*offset*0.05)
			else:
				var offset = _zoom_target - position
				global_translate(dir*offset*0.05)
			
		elif _panning:
			var old_pos = _mouse_to_floor(_prev_mouse)
			var new_pos = _mouse_to_floor(_mouse)
			if old_pos and new_pos:
				var offset = new_pos - old_pos
				global_translate(-offset)

func _mouse_to_floor(mouse : Vector2):
	var dropPlane  = Plane(Vector3(0, 1, 0), 0)
	return dropPlane.intersects_ray(
				project_ray_origin(mouse),
				project_ray_normal(mouse))
	
func switch_to_orthogonal() -> void:
	_is_orthogonal = true
	rotation = Vector3(-PI/2, 0, 0)
	_zoom = global_position.y * 2
	set_orthogonal(_zoom, 0.05, 100)
	emit_signal("orthogonal_cam")
		
func switch_to_perspective() -> void:
	_is_orthogonal = false
	global_position.y = _zoom/2
	set_perspective(90, 0.05, 100)
	emit_signal("perspective_cam")
	
