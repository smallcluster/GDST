extends CanvasLayer
@export var mainView : SubViewport
@export var fps_label : Label
@export var protocol_choice : MenuButton
@export var graph_choice : MenuButton

var _play_simulation := true


# -- GUI EVENTS --

func _ready():
	
	
	var popup = protocol_choice.get_popup()
	var names := ProtocolFactory.get_names()
	
	protocol_choice.text = names[0]
	for name in names:
		popup.add_item(name)
	
	popup.connect("id_pressed", func(id):
		var index = popup.get_item_index(id)
		var text = popup.get_item_text(index)
		protocol_choice.text = text
		mainView.set_protocol(index)
	)
	
	popup = graph_choice.get_popup()
	popup.add_item("Connexions")
	popup.add_item("Lower ids")
	
	popup.connect("id_pressed", func(id):
		var index = popup.get_item_index(id)
		var text = popup.get_item_text(index)
		graph_choice.text = text
		mainView.draw_directed_graph(index == 1)
	)
	
	
	
func _process(delta):
	fps_label.text = str(Engine.get_frames_per_second()) + " FPS"

func _on_move_time_value_changed(value):
	mainView.move_time_value_changed(value)
	$GUI/VBoxContainer/HSplitContainer/OptionsPanel/VBoxContainer/MoveTimeLabel.text = "Movement time: "+str(round(value*1000))+"ms"

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
		mainView.disable_shadows(not checked)
	# Antialiasing
	elif id == 2:
		if checked:
			mainView.msaa_3d = Viewport.MSAA_4X
			mainView.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		else:
			mainView.msaa_3d = Viewport.MSAA_DISABLED
			mainView.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
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
		mainView.top_down_view(checked)
	# Reset view
	elif id == 1:
		mainView.reset_view()
	# drone vision
	elif id == 4:
		mainView.show_vision(checked)
	# hide inactive drones
	elif id == 5 :
		mainView.hide_inactive_drones(checked)

func _on_kill_inactive_pressed():
	mainView.kill_inactive()


func _on_play_button_pressed():
	_play_simulation = not _play_simulation
	mainView.run_simulation(_play_simulation)
	_update_play_button()
	
func _update_play_button():
	var button := $"GUI/VBoxContainer/HSplitContainer/3DView/PlaybackPanel/HBoxContainer/PlayButton"
	if _play_simulation:
		button.icon = load("res://Sim/GUI/Icons/pause.svg")
	else:
		button.icon = load("res://Sim/GUI/Icons/play.svg")
	


func _on_step_button_pressed():
	mainView.run_one_simulation_step()
	_play_simulation = false
	_update_play_button()


func _on_reset_button_pressed():
	mainView.reset_simulation()
	mainView.run_simulation(false)
	_play_simulation = false
	_update_play_button()
	
