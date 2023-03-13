extends CanvasLayer
@export var mainView : SubViewport
@export var fps_label : Label
@export var link_expr : TextEdit
@export var protocol_choice : MenuButton


var _default_filter = func(s1, s2): return s2["id"] < s1["id"] and s1["active"] and s2["active"] and abs(s1["position"].y-s2["position"].y) < 0.1

# -- GUI EVENTS --

func _ready():
	var popup = protocol_choice.get_popup()
	popup.add_item("Kill Protocol")
	popup.add_item("Save Protocol")
	
	popup.connect("id_pressed", func(id):
		var index = popup.get_item_index(id)
		var text = popup.get_item_text(index)
		protocol_choice.text = text
		mainView.set_protocol(index)
	)
	
	mainView.set_link_pipeline(_default_filter, null)
	

func _process(delta):
	fps_label.text = str(Engine.get_frames_per_second()) + " FPS"

func _on_move_time_value_changed(value):
	mainView.move_time_value_changed(value)
	$GUI/VBoxContainer/HSplitContainer/OptionsPanel/VBoxContainer/MoveTimeLabel.text = "Movement time: "+str(round(value*1000))+"ms"
	
func _on_reset_pressed():
	mainView.reset_simulation()

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
		mainView.show_radius(checked)
	# hide inactive drones
	elif id == 5 :
		mainView.hide_inactive_drones(checked)


func _on_look_exp_text_changed():
	var err_color = Color.RED
	var ok_color =  Color.GREEN
	link_expr.modulate = ok_color
	
	var txt = link_expr.text
	var exp = txt.replace("\n", "").strip_edges()
	var check_reg = RegEx.new()
	check_reg.compile("^(max|min|rand|first|last)?\\ *{\\ *other\\.id\\ *(<=|!=|>=|<|>|==)\\ *id\\ *}$")
	
	# Use default impl
	if exp.is_empty():
		mainView.set_link_pipeline(_default_filter, null)
		return
	
	# Use parse error
	if not check_reg.search(exp):
		mainView.set_link_pipeline(null, null)
		link_expr.modulate = err_color
		return
	
	# Use parse values
	var reduction_reg = RegEx.new()
	reduction_reg.compile("(max|min|rand|first|last)")
	var filter_reg = RegEx.new()
	filter_reg.compile("(<=|!=|>=|<|>|==)")
	var reduction_res = reduction_reg.search(exp)
	var filter_res = filter_reg.search(exp)
	
	var reduction_pattern = reduction_res.get_string() if reduction_res else ""
	var filter_pattern = filter_res.get_string()
	
	# define filter function on id
	var filter : Callable
	if filter_pattern == "<":
		filter = func(s1, s2): return s2["id"] < s1["id"] and s1["active"] and s2["active"] and abs(s1["position"].y-s2["position"].y) < 0.1
	elif filter_pattern == ">":
		filter = func(s1, s2): return s2["id"] > s1["id"] and s1["active"] and s2["active"] and abs(s1["position"].y-s2["position"].y) < 0.1
	elif filter_pattern == "<=":
		filter = func(s1, s2): return s2["id"] <= s1["id"] and s1["active"] and s2["active"] and abs(s1["position"].y-s2["position"].y) < 0.1
	elif filter_pattern == ">=":
		filter = func(s1, s2): return s2["id"] >= s1["id"] and s1["active"] and s2["active"] and abs(s1["position"].y-s2["position"].y) < 0.1
	elif filter_pattern == "!=":
		filter = func(s1, s2): return s2["id"] != s1["id"] and s1["active"] and s2["active"] and abs(s1["position"].y-s2["position"].y) < 0.1
	elif filter_pattern == "==":
		filter = func(s1, s2): return s2["id"] == s1["id"] and s1["active"] and s2["active"] and abs(s1["position"].y-s2["position"].y) < 0.1
		
	# define reduction function on id
	var reduction = null
	if reduction_pattern == "max":
		reduction = func(acc, x): return acc if acc["id"] > x["id"] else x
	elif reduction_pattern == "min":
		reduction = func(acc, x): return acc if acc["id"] < x["id"] else x
	elif reduction_pattern == "rand":
		reduction = func(acc, x): return acc if randi_range(0, 1) else x
	elif reduction_pattern == "first":
		reduction = func(acc, x): return acc
	elif reduction_pattern == "last":
		reduction = func(acc, x): return x
	else:
		reduction = null
		
	mainView.set_link_pipeline(filter, reduction)


func _on_kill_inactive_pressed():
	mainView.kill_inactive()
