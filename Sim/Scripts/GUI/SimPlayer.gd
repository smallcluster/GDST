extends Control
class_name SimPlayer

@onready var _pointer := $MainPanel/Control
@onready var _frames_container := $MainPanel/ScrollContainer/VisibleFrames
@onready var _scroll_container := $MainPanel/ScrollContainer
@onready var _pointer_line := $MainPanel/Control/ColorRect2
@onready var _frame_scene = preload("res://Sim/GUI/SimPlayer/SimPlayerFrame.tscn")

signal load_frame(states, target)

var _next_n := 0
var _frame_added := false
var _selected_frame := 0
var _mouse_playback := false
var _prev_selected_frame := 0

func set_updating(val : bool) -> void:
	$MainPanel.visible = not val
	$WaningPanel.visible = val
	
func _process(delta):
	
	if _frame_added and $MainPanel.visible:
		_scroll_container.scroll_horizontal = _scroll_container.get_h_scroll_bar().max_value
		_frame_added = false
	
	var frames = _frames_container.get_children()
	
	if frames.is_empty():
		return 
		
	if _mouse_playback and visible and $MainPanel.visible: 
		for i in range(frames.size()):
			var f = frames[i]
			var mouse = get_local_mouse_position()
			mouse.x += _scroll_container.scroll_horizontal
			if f.get_rect().has_point(mouse):
				_selected_frame = i
				break
	
	_pointer.position.x = frames[_selected_frame].get_pos() - _scroll_container.scroll_horizontal
	
	_pointer_line.size.y = _scroll_container.size.y-32
	
	
	# request simulation reload
	if _prev_selected_frame != _selected_frame:
		frames[_prev_selected_frame].selected = false
		_prev_selected_frame = _selected_frame
		var f = frames[_selected_frame]
		
		emit_signal("load_frame", f.states, f.target)
	
	if $MainPanel.visible:	
		frames[_selected_frame].selected = true
		
		
func add_frame(states : Array[Dictionary], target : Vector2) -> void:
	var f = create_frame(_next_n, states, target)
	_frames_container.add_child(f)
	_frames_container.get_children()[_prev_selected_frame].selected = false
	_selected_frame = _next_n
	_prev_selected_frame = _next_n
	_frame_added = true
	$WaningPanel/TopBar2/Label.text = "Time line is updating (frame: "+str(_next_n)+")"
	_next_n += 1

func create_frame(n : int, states : Array[Dictionary], target : Vector2):
	var frame = _frame_scene.instantiate()
	frame.n = n
	frame.states = states
	frame.target = target
	return frame
	
func _input(event):
	if not $MainPanel.visible:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT :
			if event.pressed:
				if _scroll_container.get_h_scroll_bar().get_global_rect().has_point(event.global_position):
					_mouse_playback = false
				elif _scroll_container.get_global_rect().has_point(event.global_position):
					_mouse_playback = true
				else:
					_mouse_playback = false
			else:
				if _pointer.position.x < 0 and _mouse_playback:
					_scroll_container.scroll_horizontal -= get_rect().size.x - _pointer.position.x
				elif _pointer.position.x > get_rect().size.x and _mouse_playback:
					_scroll_container.scroll_horizontal += _pointer.position.x
				_mouse_playback = false
			
func get_current_frame():
	return _frames_container.get_children()[_selected_frame]
		
func clear() -> void:
	for f in _frames_container.get_children():
		f.queue_free()
	_next_n = 0
	_selected_frame = 0
	_prev_selected_frame = 0
	
