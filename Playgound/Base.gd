extends Drone2D

var target_pos : Vector2
var Dl : int


signal deploy_drone

func _ready():
	super._ready()
	target_pos = position
	id = INF # id is always too large
	Dl = 3*D

func _draw():
	draw_circle(Vector2.ZERO, D/3, Color.DARK_MAGENTA)
	draw_line(Vector2.ZERO, target_pos-position, Color.DARK_MAGENTA)
	draw_arc(target_pos-position, D/3, 0, 2*PI, 32, Color.DARK_MAGENTA)

func look() -> Array[Observation]:
	var drones = vision.get_overlapping_bodies()
	drones = drones.filter(func(x): return x.active)
	var obs : Array[Observation] = []
	for d in drones:
		obs.append(Observation.new(d.id, d.light, d.position))
	return obs
	
func compute(obs : Array[Observation]) -> Vector2:
	# ask the manager to deploy a new drone
	if obs.all(func(x): position.distance_squared_to(x.pos) > Dl*Dl):
		emit_signal("deploy_drone")
		print("deployed")
	return position
	
func move(pos : Vector2, delta) -> void:
	return
	
