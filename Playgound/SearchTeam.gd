extends Drone2D

var target_pos : Vector2

var move_to_mouse : bool = false

func _ready():
	super._ready()
	target_pos = position

func _draw():
	draw_circle(Vector2.ZERO, D/3, Color.DARK_BLUE)
	draw_line(Vector2.ZERO, target_pos-position, Color.DARK_BLUE)
	draw_arc(target_pos-position, D/3, 0, 2*PI, 32, Color.DARK_BLUE)

func look() -> Array[Observation]:
	return []
	
func compute(obs : Array[Observation]) -> Vector2:
	
	if move_to_mouse:
		target_pos = get_global_mouse_position()
		
	var vd = (target_pos - position)
	return position + vd.normalized() * clamp(vd.length(), 0, D)
	
func move(pos : Vector2, delta) -> void:
	position += (pos-position) * delta


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			move_to_mouse = event.pressed
