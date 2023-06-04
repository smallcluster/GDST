extends CanvasLayer

@export var mainView : SubViewport
@export var fps_label : Label
@export var max_height_label : Label
@export var protocol_choice : MenuButton
@export var graph_choice : MenuButton
@export var scene_tree : Tree
@export var stats_panel : PanelContainer
@export var play_button : Button
@export var view_switch : Button
@export var vision_switch : Button
@export var sim_player : SimPlayer
@export var test_tree : Tree
@export var test_creation_name : LineEdit

@onready var _fail_popup = $FailWindow
@onready var _tools = get_node("/root/Tools")

var _play_simulation := true
var _scene_tree_root : TreeItem
var _test_tree_root : TreeItem
var _drone_tree_index : Dictionary = {}
var _max_height := 0
var _top_down := false
var _show_vision := false




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
		var p : Protocol = ProtocolFactory.build(index)
		mainView.set_protocol(p)
		
		# Keep current frame
		var frame = sim_player.get_current_frame()
		var states : Array[Dictionary]
		states.assign(frame.states.map(func(x): return p.migrate_state(x)))
		var target = frame.target
		
		reset()
		sim_player.clear()
		
		# Create new frame
		sim_player.add_frame(states, target)
		mainView.load_frame(states, target)
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
	
	list_tests()
	
	# To load tests
	test_tree.connect("button_clicked", func(item, column, id, mouse_button_index):
		load_test(_get_tests_dir_path()+"/"+item.get_text(0)+".json")
	)
	
	
	
func list_tests():
	# List test files
	test_tree.disconnect("button_clicked", func(item, column, id, mouse_button_index):pass)
	test_tree.clear()
	
	_test_tree_root = test_tree.create_item()
	_test_tree_root.set_text(0, "Tests")
	
	var img = Image.load_from_file("res://Sim/GUI/Icons/load_test.svg")
	img.resize(24, 24)
	var tex = ImageTexture.create_from_image(img)
	
	var dir := DirAccess.open(_get_tests_dir_path())
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with("json"):
				var t := test_tree.create_item(_test_tree_root)
				t.set_text(0, file_name.substr(0, len(file_name)-5))
				t.add_button(1, tex)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		var t := test_tree.create_item(_test_tree_root)
		t.set_text(0, "No tests found")
	
	
func _get_tests_dir_path():
	var line_edit : LineEdit = $GUI/VBoxContainer/HSplitContainer/HSplitContainer/Panel/Tests/VBoxContainer/HBoxContainer/TestFolderPath
	var dir_path = line_edit.placeholder_text if  line_edit.text == "" else line_edit.text
	return dir_path

func load_test(path : String):
	var j = JSON.parse_string(FileAccess.get_file_as_string(path))
	# TODO: check if file is well formed
	if j == null:
		list_tests()
		return
	
	# Protocol infos
	var protocol_name = j["protocol"]
	
	var protocol = ProtocolFactory.build(ProtocolFactory.get_names().find(protocol_name))
	
	var states : Array[Dictionary] = []
	var expression = Expression.new()
	
	var target = Vector2.ZERO
	
	for js in j["states"]:
		var s = js.duplicate(true)
		
		# parse position
		var pos = []
		for x in js["position"]:
			if x is String:
				expression.parse(x, ["D"])
				pos.append(expression.execute([protocol.D]))
			else:
				pos.append(x)
		
		s["position"] = mainView.get_base_pos() + Vector3(pos[0],pos[1],pos[2])
		
		if s["id"] == 0:
			var tmp = s["position"]
			target = Vector2(tmp.x, tmp.z)
			
		
		states.append(protocol.migrate_state(s))
	
	if j.has("target"):
		var pos = []
		for x in j["target"]:
			if x is String:
				expression.parse(x, ["D"])
				pos.append(expression.execute([protocol.D]))
			else:
				pos.append(x)
		target = Vector2(pos[0], pos[1])
	
	# Switch to new protocol
	protocol_choice.text = protocol_name
	mainView.set_protocol(protocol)
	
	reset()
	sim_player.clear()
	# Create new frame
	sim_player.add_frame(states, target)
	mainView.load_frame(states, target)
	
	
	
	
func _process(delta):
	fps_label.text = str(Engine.get_frames_per_second()) + " FPS"

func _on_move_time_value_changed(value):
	mainView.move_time_value_changed(value)
	$GUI/VBoxContainer/HSplitContainer/OptionsPanel/VBoxContainer/MoveTimeLabel.text = "Movement time: "+str(round(value*1000))+"ms"

func _on_perspective_cam():
	var items = $GUI/VBoxContainer/MenuBarPanel/MenuBar/View
	var index = items.get_item_index(0)
	items.set_item_checked(index, false)
	_top_down = false
	view_switch.icon = load("res://Sim/GUI/Icons/cube.svg")
	view_switch.text = "3d"
	
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

func _on_view_id_pressed(id):
	var items : PopupMenu = $GUI/VBoxContainer/MenuBarPanel/MenuBar/View
	var index = items.get_item_index(id)
	var checked := false
	if items.is_item_checkable(index):
		checked = not items.is_item_checked(index)
		items.set_item_checked(index, checked)
		
	if id == 1 :
		mainView.hide_inactive_drones(checked)
	# Statistics
	elif id == 5:
		stats_panel.visible = checked
	elif id == 3:
		$GUI/VBoxContainer/HSplitContainer/HSplitContainer/Panel.visible = checked
	elif id == 4:
		sim_player.visible = checked

func _on_kill_inactive_pressed():
	mainView.kill_inactive()


func _on_play_button_pressed():
	# No play if error !
	if not _fail_popup.visible:
		_play_simulation = not _play_simulation
		mainView.run_simulation(_play_simulation)
		_update_play_button()
	
func _update_play_button():
	if _play_simulation:
		play_button.icon = load("res://Sim/GUI/Icons/pause.svg")
	else:
		play_button.icon = load("res://Sim/GUI/Icons/play.svg")
	


func _on_step_button_pressed():
	# No steping if error !
	if not _fail_popup.visible:
		mainView.run_one_simulation_step()
		_play_simulation = false
		_update_play_button()


func _on_reset_button_pressed():
	reset()
	sim_player.clear()
	
func reset():
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
	_fail_popup.visible = false
	
	
func _on_main_view_add_drone(id):
	_register_drone(id)
	
func _register_drone(id):
	var d := scene_tree.create_item(_scene_tree_root)
	d.set_text(0, "drone "+str(id))
	d.collapsed = true
	_drone_tree_index[id] = d.get_index()
	_scene_tree_root.set_text(0, "Drones ("+str(_scene_tree_root.get_child_count())+")")
	
func _update_registered_drone(state):
	
	if _max_height < state["position"].y:
		_max_height = state["position"].y
		max_height_label.text = "Max height: "+str(_max_height)+"m"
	if _max_height < state["position"].y:
		_max_height = state["position"].y
		max_height_label.text = "Max height: "+str(_max_height)+"m"
		
	
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
	
	

func _on_main_view_remove_drone(id):
	_scene_tree_root.remove_child(_scene_tree_root.get_child(_drone_tree_index[id]))
	_drone_tree_index.erase(id)
	var i = 0
	for k in _drone_tree_index:
		_drone_tree_index[k] = i
		i += 1
	_scene_tree_root.set_text(0, "Drones ("+str(_scene_tree_root.get_child_count())+")")
	


func _on_main_view_update_drone_state(state):
	_update_registered_drone(state)

func _on_view_switch_pressed():
	_top_down = not _top_down
	mainView.top_down_view(_top_down)
	if _top_down:
		view_switch.icon = load("res://Sim/GUI/Icons/square.svg")
		view_switch.text = "2d"
	else:
		view_switch.icon = load("res://Sim/GUI/Icons/cube.svg")
		view_switch.text = "3d"


func _on_main_view_exec_fail(exec):
	_play_simulation = false
	_update_play_button()
	
	# create pup up !
	_fail_popup.popup_centered()
	_fail_popup.set_data(exec.msg, exec.state)
	
	
func _on_main_view_new_frame(states, target):
	sim_player.add_frame(states, target)


func _on_sim_player_load_frame(states, target):
	reset()
	mainView.load_frame(states, target)
	
	
func _on_refresh_tests_pressed():
	list_tests()

func _on_test_folder_path_text_changed(new_text):
	list_tests()

func _on_test_folder_path_text_submitted(new_text):
	list_tests()


func _on_dist_arg_changed(new_text):
	var in1 = $GUI/VBoxContainer/HSplitContainer/HSplitContainer/Panel/Inspector/VBoxContainer/HBoxContainer/LineEdit 
	var in2 = $GUI/VBoxContainer/HSplitContainer/HSplitContainer/Panel/Inspector/VBoxContainer/HBoxContainer/LineEdit2
	var out = $GUI/VBoxContainer/HSplitContainer/HSplitContainer/Panel/Inspector/VBoxContainer/HBoxContainer2/Label4
	
	if in1.text.is_valid_int() and in2.text.is_valid_int():
		var id1 = in1.text.to_int()
		var id2 = in2.text.to_int()
		if id1 in _drone_tree_index and id2 in _drone_tree_index:
			var item1 := _scene_tree_root.get_child(_drone_tree_index[id1])
			var item2 := _scene_tree_root.get_child(_drone_tree_index[id2])
			
			var p1 = []
			for c in item1.get_children():
				if c.get_text(0) == "position":
					for x in c.get_children():
						p1.append(x.get_text(1).to_float())
					break
			var p2 = []
			for c in item2.get_children():
				if c.get_text(0) == "position":
					for x in c.get_children():
						p2.append(x.get_text(1).to_float())
					break
			var d = (p1[0]-p2[0])*(p1[0]-p2[0]) + (p1[2]-p2[2])*(p1[2]-p2[2])
			out.text = str(d)					
					
		else:
			out.text = "null"
	else:
		out.text = "null"
		

func _on_save_test_pressed():
	var pos_format_check : CheckBox = $GUI/VBoxContainer/HSplitContainer/HSplitContainer/Panel/Tests/VBoxContainer/TestSavingContainer/RelativePos
	var frame = sim_player.get_current_frame()
	var t = frame.target
	var dict = {
		"protocol" : protocol_choice.text,
		"states" : [],
		"target" : [t.x, t.y]
	}
	for s in frame.states:
		var fs = {}
		for k in s:
			# skip this 'KILL' internal state
			if k == "KILL": 
				continue
			if k == "position": # format position
				var p = s[k] - mainView.get_base_pos()
			
				if pos_format_check.button_pressed:
					fs[k] = ["%f * D" % (p.x / 0.3), "%f * D" % (p.y / 0.3), "%f * D" % (p.z / 0.3)]
				else:
					fs[k] = [p.x, p.y, p.z]
			else:
				fs[k] = s[k]
				
		dict["states"].append(fs)

	var txt = test_creation_name.text if test_creation_name.text != "" else test_creation_name.placeholder_text
	
	var file = FileAccess.open(_get_tests_dir_path()+"/"+txt+".json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(dict))
		file.close()
		list_tests()
	
	
func _on_vison_switch_pressed():
	_show_vision = not _show_vision
	mainView.show_vision(_show_vision)
	if _show_vision:
		vision_switch.icon = load("res://Sim/GUI/Icons/eye-on.svg")
	else:
		vision_switch.icon = load("res://Sim/GUI/Icons/eye-off.svg")

func _on_reset_view_pressed():
	mainView.reset_view()
	

func _set_tool(choice):
	_tools.current = choice
	
	var tool_text : Label = $"GUI/VBoxContainer/HSplitContainer/HSplitContainer/VSplitContainer/3DView/ToolsPanel/VBoxContainer/SelectedToolLabel"
	
	var tool_target_button : Button = $"GUI/VBoxContainer/HSplitContainer/HSplitContainer/VSplitContainer/3DView/ToolsPanel/VBoxContainer/HBoxContainer/MoveTarget"
	var tool_pan_button : Button = $"GUI/VBoxContainer/HSplitContainer/HSplitContainer/VSplitContainer/3DView/ToolsPanel/VBoxContainer/HBoxContainer/PanView"
	var tool_zoom_button : Button = $"GUI/VBoxContainer/HSplitContainer/HSplitContainer/VSplitContainer/3DView/ToolsPanel/VBoxContainer/HBoxContainer/ZoomView"
	var tool_rotate_button : Button = $"GUI/VBoxContainer/HSplitContainer/HSplitContainer/VSplitContainer/3DView/ToolsPanel/VBoxContainer/HBoxContainer/RotateView"
	
	tool_target_button.set_pressed_no_signal(false)
	tool_pan_button.set_pressed_no_signal(false)
	tool_zoom_button.set_pressed_no_signal(false)
	tool_rotate_button.set_pressed_no_signal(false)
	
	if choice == _tools.ToolChoice.MOVE_TARGET:
		tool_target_button.set_pressed_no_signal(true)
		tool_text.text = "Move search team"
	elif choice == _tools.ToolChoice.PAN_VIEW:
		tool_pan_button.set_pressed_no_signal(true)
		tool_text.text = "Pan view"
	elif choice == _tools.ToolChoice.ZOOM_VIEW:
		tool_zoom_button.set_pressed_no_signal(true)
		tool_text.text = "Zoom view"
	elif choice == _tools.ToolChoice.ROTATE_VIEW:
		tool_rotate_button.set_pressed_no_signal(true)
		tool_text.text = "Rotate view"

func _on_move_target_pressed():
	_set_tool(_tools.ToolChoice.MOVE_TARGET)
func _on_pan_view_pressed():
	_set_tool(_tools.ToolChoice.PAN_VIEW)
func _on_zoom_view_pressed():
	_set_tool(_tools.ToolChoice.ZOOM_VIEW)
func _on_rotate_view_pressed():
	_set_tool(_tools.ToolChoice.ROTATE_VIEW)
