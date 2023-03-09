extends SubViewport

@export var _main_cam : Node3D = null

@onready var _pivot = $CamPivot

func _process(delta):
	if _main_cam:
		_pivot.rotation = _main_cam.rotation
		
