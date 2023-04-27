extends CanvasLayer
@export var mainView : SubViewport
@export var fps_label : Label
@export var max_height_label : Label
@export var protocol_choice : MenuButton
@export var graph_choice : MenuButton
@export var scene_tree : Tree
@export var stats_panel : PanelContainer

var _play_simulation := true
var _scene_tree_root : TreeItem
var _drone_tree_index : Dictionary = {}
var _max_height := 0


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
	
	_scene_tree_root = scene_tree.create_item()
	_scene_tree_root.set_text(0, "Drones")


	
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
		stats_panel.visible = checked

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
	var button := $"GUI/VBoxContainer/HSplitContainer/HSplitContainer/3DView/PlaybackPanel/HBoxContainer/PlayButton"
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
	# Clear drone list
	_drone_tree_index.clear()
	scene_tree.clear()
	_scene_tree_root = scene_tree.create_item()
	_scene_tree_root.set_text(0, "Drones")
	_max_height = 0
	
	
func _on_main_view_add_drone(id):
	var d := scene_tree.create_item(_scene_tree_root)
	d.set_text(0, "drone "+str(id))
	d.collapsed = true
	_drone_tree_index[id] = d.get_index()
	_scene_tree_root.set_text(0, "Drones ("+str(_scene_tree_root.get_child_count())+")")
	

func _on_main_view_remove_drone(id):
	_scene_tree_root.remove_child(_scene_tree_root.get_child(_drone_tree_index[id]))
	_drone_tree_index.erase(id)
	var i = 0
	for k in _drone_tree_index:
		_drone_tree_index[k] = i
		i += 1
	_scene_tree_root.set_text(0, "Drones ("+str(_scene_tree_root.get_child_count())+")")
	


func _on_main_view_update_drone_state(state):
	
	if _max_height < state["position"].y:
		_max_height = state["position"].y
		max_height_label.text = "Largest height: "+str(_max_height)+"m"
	
	var item := _scene_tree_root.get_child(_drone_tree_index[state["id"]])

	var labels := item.get_children().map(func(x): return x.get_text(0))
	
	# REMOVE / UPDATE EXISTING DATA
	for c in item.get_children():
		var label : String = c.get_text(0)
		if not state.has(label):
			item.remove_child(c)
			continue
		var data = state[label]
		# UPDATE X Y Z components
		if data is Vector3:
			var position_updated = false
			for i in range(c.get_child_count()):
				var updateTxt = str(data[i])
				var comp =  c.get_child(i)
				var compTxt = comp.get_text(1)
				if updateTxt != compTxt:
					comp.set_text(1, updateTxt)
					comp.set_custom_color(1, Color.RED)
					comp.set_custom_color(0, Color.RED)
					position_updated = true
				else:
					comp.clear_custom_color(0)
					comp.clear_custom_color(1)
					
			if position_updated:
				c.set_custom_color(1, Color.RED)
				c.set_custom_color(0, Color.RED)
			else:
				c.clear_custom_color(0)
				c.clear_custom_color(1)
		else:
			var value : String = str(state[label])
			if value != c.get_text(1):
				c.set_text(1, value)
				c.set_custom_color(1, Color.RED)
				c.set_custom_color(0, Color.RED)
			else:
				c.clear_custom_color(0)
				c.clear_custom_color(1)
			
	# ADD DATA
	for k in state:
		if k not in labels:
			var sub_item := scene_tree.create_item(item)
			sub_item.set_text(0, k)
			var data = state[k]
			# ADD X Y Z components
			if data is Vector3:
				var x := scene_tree.create_item(sub_item)
				x.set_text(0, "x")
				x.set_text(1, str(data.x))
				var y := scene_tree.create_item(sub_item)
				y.set_text(0, "y")
				y.set_text(1, str(data.y))
				var z := scene_tree.create_item(sub_item)
				z.set_text(0, "z")
				z.set_text(1, str(data.z))
				sub_item.collapsed = true
			else:
				sub_item.set_text(1, str(state[k]))
	
