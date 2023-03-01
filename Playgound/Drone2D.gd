@tool
extends Node2D
class_name Drone2D

# state
var id : int = 0
@export var light : bool = false
@export var active : bool = true

# Parametters
var D : float = 30
var Dmax : float
var Dp : float
var Dc : float

# Godot Specific
@onready var vision : Area2D = $Vision
@onready var vision_disc : CollisionShape2D = $Vision/CollisionShape2D
@onready var label_id = $LabelId

# Called when the node enters the scene tree for the first time.
func _ready():
	label_id.text = str(id)
	Dmax = 7*D
	Dc = 2*D
	Dp = Dmax-D
	vision_disc.shape = CircleShape2D.new()
	vision_disc.shape.radius = Dmax
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	queue_redraw()
	
func _draw():
	if active:
		if light:
			draw_circle(Vector2.ZERO, D/3, Color.ORANGE)
		else:
			draw_circle(Vector2.ZERO, D/3, Color.BLACK)
		draw_arc(Vector2.ZERO, D, 0, 2*PI, 32, Color(1,0,0,0.2))
		draw_arc(Vector2.ZERO, Dc, 0, 2*PI, 32, Color(1,0.5,0,0.2))
		draw_arc(Vector2.ZERO, Dp, 0, 2*PI, 32, Color(0,1,0,0.2))
		draw_arc(Vector2.ZERO, Dmax, 0, 2*PI, 32, Color(1,0,0,0.2))
	else:
		draw_circle(Vector2.ZERO, D/2, Color(0.5,0.5,0.5, 0.25))

# Conditionnal link
	if not active:
		return

	var drones = vision.get_overlapping_bodies()
	drones = drones.filter(func(x): return x.active)
	
	
# l'odre décroissant local conserve la connection
	drones = drones.filter(func(x): return x.id < id)

	if drones.is_empty():
		return

	# max id only
	var max = drones[0]
	for d in drones:
		if d.id > max.id:
			max = d
	draw_line(Vector2.ZERO, max.position-position, Color.CYAN, 2)
	
# ⚠️ prendre le plus petit rend la topologie du graphe instable mais c'est une solution

# ⚠️ l'odre croissant local ne conserve pas la connection
#	drones = vision.get_overlapping_bodies()
#	drones = drones.filter(func(x): return x.active)
#	drones = drones.filter(func(x): return x.id != id)
#
#	if drones.is_empty():
#		return
#
#	# max id only
#	var m = drones[0]
#	for d in drones:
#		if d.id > m.id:
#			m = d
#	draw_line(Vector2.ZERO, m.position-position, Color.MAGENTA, 4)
	


func look() -> Array[Observation]:
	if not active:
		return []
	
	var drones = vision.get_overlapping_bodies()
	drones = drones.filter(func(x): return x.active)
	drones = drones.filter(func(x): return x.id < id)
	var obs : Array[Observation] = []
	for d in drones:
		obs.append(Observation.new(d.id, d.light, d.position))
	return obs
	
func compute(obs : Array[Observation]) -> Vector2:
	
	if not active:
		return position
		
	# reset light value
	light = false
	
	# alone ? => stay
	if obs.is_empty():
		return position
	
	# Collision ? => EXPLODE
	for o in obs:
		if position.distance_squared_to(o.pos) <= D*D:
			active = false
			return position
			
	# Choose a target that isn't dangerous
	var candidates : Array[Observation] = obs.filter(func(x): return not x.light)
	# All dangerous :(
	if candidates.is_empty():
		candidates = obs 

	# Closest one 
	var new_pos = candidates[0].pos
	for c in candidates:
		if position.distance_squared_to(c.pos) <= position.distance_squared_to(new_pos):
			new_pos = c.pos
	
	# Min id		
#	var new_pos = candidates[0].pos
#	var min = candidates[0].id
#	for c in candidates:
#		if min < c.id:
#			new_pos = c.pos
#			min = c.id
			
	# Danger ? => stay
	if new_pos.distance_squared_to(position) <= Dc*Dc:
		light = true
		return position
		
	# All good ? => move to target only if it is in Dp zone
	if new_pos.distance_squared_to(position) > Dp*Dp:
		var vd = (new_pos - position)
		return position + vd.normalized() * clamp(vd.length(), 0, D)
	return position
	
func move(pos : Vector2, delta) -> void:
	if not active:
		return
	position += (pos-position) * delta
