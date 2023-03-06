class_name Protocol

var _config : Dictionary = {}

func look(state : Dictionary, neighbours : Array[Drone]) -> Array[Dictionary]:
	return []

func compute(state : Dictionary, messages : Array[String], obs : Array[Dictionary]) -> ComputeResult:
	return ComputeResult.new(state, [])
	
func get_config() -> Dictionary:
	return _config.duplicate(true)
