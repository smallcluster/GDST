extends VBoxContainer

@onready var label := $FrameHeader/FrameLabel
@onready var rect := $FrameRect

var n := 0 : get = get_number, set = set_number

var states : Array[Dictionary]
var target : Vector2

signal selected(n)

func get_number() -> int:
	return n

func set_number(_n : int) -> void:
	if not is_inside_tree():
		await ready
	n = _n
	label.text = str(n)
	
func get_pos() -> float:
	return position.x + rect.position.x+rect.size.x/2.0
