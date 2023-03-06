@tool
extends Node3D

@onready var _drone : Drone3DImpl = $Drone

@onready var _detection_shape := $Detection/CollisionShape3D

# IN METTER
@export var D : float = 0.45 : set = set_D

func get_drone() -> Drone :
	return _drone
	
func set_D(val : float) -> void:
	D = val
	update_radius()

func update_radius() -> void:
	var Dmax := 7 * D
	var Dc := 2 * D
	var Dp := Dmax - D
	
	var max_radius = $Visualization/MaxRadius
	var follow_radius = $Visualization/FollowRadius
	var warning_radius = $Visualization/WarningRadius
	var collision_radius = $Visualization/CollisionRadius
	
	max_radius.scale = Vector3(Dmax, Dmax, Dmax)*2
	follow_radius.scale = Vector3(Dp, Dp, Dp)*2
	warning_radius.scale = Vector3(Dc, Dc, Dc)*2
	collision_radius.scale = Vector3(D, D, D)*2
	
	_detection_shape.shape = SphereShape3D.new()
	_detection_shape.shape.radius = Dmax
