extends Node2D


var D = 30

@onready var drone_scene = load("res://Playgound/Drone2D.tscn")
var new_id = 1 # team drone is 0, base is infinite
@onready var base = $Base
@onready var team_scene = load("res://Playgound/SearchTeam.tscn")
@onready var panel = $ControlLayer/Control/PanelContainer
@onready var cam = $Camera2D

var team
var pan = false

func _ready():
	team = team_scene.instantiate()
	team.position = base.position
	team.id = 0
	$Drones.add_child(team)
	
func deploy_drone():
	var d = drone_scene.instantiate()
	d.position = base.position
	d.id = new_id
	d.D = D
	$Drones.add_child(d)
	new_id += 1

func update(delta):
	var drones = $Drones.get_children()
	var n = drones.size()
	var obs = []
	var pos = []
	
	# Deploy a new drone
	var alives = drones.filter(func(d): return d.active)
	if alives.all(func(d): return d.position.distance_squared_to(base.position) > 9*D*D):
		deploy_drone()
	
	### FSYNC update ###
	# LOOK
	for d in drones:
		obs.append(d.look())
			
	#print(obs)
	
	# COMPUTE
	for i in range(n):
		pos.append(drones[i].compute(obs[i]))
	# MOVE
	for i in range(n):
		drones[i].move(pos[i], delta)
		
func _process(delta):
	queue_redraw()

func _physics_process(delta):
	update(0.25)
	
	
func _draw():
	# draw base
	draw_circle(base.position, D/3, Color(1,0,1))
	draw_arc(base.position, 3*D, 0, 2*PI, 32, Color(1,0,1, 0.2))
	draw_arc(base.position, 7*D, 0, 2*PI, 32, Color(1,0,1, 0.2))
	
	# draw links from drones to drones
	var drones = $Drones.get_children()
	
#	for d1 in drones:
#		for d2 in drones:
#			if d1 == d2 or not d1.active or not d2.active :
#				continue
#			if d1.position.distance_squared_to(d2.position) <= d1.Dmax*d1.Dmax:
#				draw_line(d1.position, d2.position, Color.CYAN, 2, true)
	# draw links from drones to base			
	for d in drones:
		if d.active and d.position.distance_squared_to(base.position) <= d.Dmax*d.Dmax:
			draw_line(base.position, d.position, Color.CYAN, 2, true)
	
	
# Prevent the team from moving while in the control panel		
func _input(event):
	if event is InputEventMouseMotion:
		if panel.get_global_rect().has_point(event.global_position):
			team.set_process_input(false)
		else:
			team.set_process_input(true)
		
		if pan:
			cam.position -= event.relative
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			pan = event.pressed
		
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam.zoom -= Vector2(0.1,0.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam.zoom += Vector2(0.1,0.1)
