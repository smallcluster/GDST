extends DroneManager

@onready var _drones = $Drones
@onready var _lines : Lines3D = $Lines3D as Lines3D
@onready var _base = $Base

var _base_height := 3.0

func _process(delta):
	# UPDATE
	var drones3D : Array[Drone3D] = _drones.get_children() as Array[Drone3D]
	var drones : Array[Drone] = drones3D.map(func(x): return x.get_drone())
	simulate(drones)
	
	# Move and wait for all movement to finish
	var tweens : Array[Tween] = drones3D.map(func(x): return x.move())
	for t in tweens:
		await t.finished
	
	# DRAWING
	_lines.clear() # clear previous lines
	_draw_all_connections(drones)
	
func _draw_all_connections(drones : Array[Drone]) -> void:
	for s in drones:
		var neighbours = s.get_neighbours()
		for d in neighbours:
			_lines.create_line(s.state["position"], d.state["position"])
	
	

