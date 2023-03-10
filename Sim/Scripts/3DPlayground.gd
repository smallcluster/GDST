extends CanvasLayer
@export var _mainView : SubViewport
@onready var _fps_label : Label = $"GUI/VBoxContainer/HSplitContainer/3DView/StatsPanel/VBoxContainer/FpsLabel"

# -- GUI EVENTS --

func _process(delta):
	_fps_label.text = str(Engine.get_frames_per_second()) + " FPS"

	
func _on_move_time_value_changed(value):
	_mainView.move_time_value_changed(value)
	
func _on_reset_pressed():
	_mainView.reset_simulation()

func _on_perspective_cam():
	var items = $GUI/VBoxContainer/MenuBarPanel/MenuBar/View
	var index = items.get_item_index(0)
	items.set_item_checked(index, false)
	
func _on_preferences_id_pressed(id):
	var items : PopupMenu = $GUI/VBoxContainer/MenuBarPanel/MenuBar/Preferences
	var index = items.get_item_index(id)
	
	var checked := false
	if items.is_item_checkable(index):
		checked = not items.is_item_checked(index)
		items.set_item_checked(index, checked)
	
	# Shadows
	if id == 1:
		_mainView.disable_shadows(not checked)
	# Antialiasing
	elif id == 2:
		if checked:
			_mainView.msaa_3d = Viewport.MSAA_4X
			_mainView.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		else:
			_mainView.msaa_3d = Viewport.MSAA_DISABLED
			_mainView.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	# Statistics
	elif id == 3:
		$"GUI/VBoxContainer/HSplitContainer/3DView/StatsPanel".visible = checked

func _on_view_id_pressed(id):
	var items : PopupMenu = $GUI/VBoxContainer/MenuBarPanel/MenuBar/View
	var index = items.get_item_index(id)
	var checked := false
	if items.is_item_checkable(index):
		checked = not items.is_item_checked(index)
		items.set_item_checked(index, checked)
	
	# Top down
	if id == 0:
		_mainView.top_down_view(checked)
	# Reset view
	elif id == 1:
		_mainView.reset_view()
	# drone vision
	elif id == 4:
		_mainView.show_radius(checked)
	# hide inactive drones
	elif id == 5 :
		_mainView.hide_inactive_drones(checked)
