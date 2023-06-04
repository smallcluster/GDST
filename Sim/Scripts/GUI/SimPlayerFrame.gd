extends VBoxContainer

@onready var label := $FrameHeader/FrameLabel
@onready var rect := $FrameRect

var n := 0 : get = get_number, set = set_number
var selected := false : get = is_selected, set = set_selected

var states : Array[Dictionary]
var target : Vector2


func get_number() -> int:
	return n

func set_number(_n : int) -> void:
	if not is_inside_tree():
		await ready
	n = _n
	label.text = str(n)
	
func get_pos() -> float:
	return position.x + rect.position.x+rect.size.x/2.0
	
func is_selected() -> bool:
	return selected

func set_selected(val : bool) -> void:
	selected = val
	if selected:
		$FrameRect.color = Color.WHITE
	else:
		$FrameRect.color = Color(0.04, 0.04, 0.04);
