extends Window

@onready var msgbox : RichTextLabel = $Panel/TabContainer/Message/MsgBox
@onready var tree : Tree = $Panel/TabContainer/Inspector/VBoxContainer/Tree

func set_data(msg : String, state : Dictionary):
	# Message
	msgbox.text = msg
	
	# State inspector
	tree.clear()
	var root = tree.create_item()
	root.set_text(0, "state")
	for k in state:
		var param := tree.create_item(root)
		param.set_text(0, k)
		var data = state[k]
		# ADD X Y Z components
		if data is Vector3:
			var x := tree.create_item(param)
			x.set_text(0, "x")
			x.set_text(1, str(data.x))
			var y := tree.create_item(param)
			y.set_text(0, "y")
			y.set_text(1, str(data.y))
			var z := tree.create_item(param)
			z.set_text(0, "z")
			z.set_text(1, str(data.z))
			param.collapsed = true
		else:
			param.set_text(1, str(state[k]))
	
	visible = true
	
	
func _on_close_requested():
	visible = false
