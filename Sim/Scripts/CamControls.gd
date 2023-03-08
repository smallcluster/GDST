extends Node3D

var speed := 5

func _process(delta):
	
	var dir = Vector3(0,0,0)
	
	if Input.is_action_pressed("cam_forwards"):
		dir.z -= 1
	if Input.is_action_pressed("cam_backwards"):
		dir.z += 1
	if Input.is_action_pressed("cam_right"):
		dir.x += 1
	if Input.is_action_pressed("cam_left"):
		dir.x -= 1
	if Input.is_action_pressed("cam_up"):
		dir.y += 1
	if Input.is_action_pressed("cam_down"):
		dir.y -= 1
		
	
	position += dir.normalized() * speed * delta
