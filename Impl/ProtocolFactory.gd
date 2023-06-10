extends Node
class_name ProtocolFactory

static func get_names() -> Array[String]:
	return ["default", "PReturn", "PReturnO2", "PReturnO2_final"]

static func build(id : int):
	if id == 0:
		return PDefault.new()
	elif id == 1:
		return PReturn.new()
	elif id == 2:
		return PReturnO2.new()
	elif id == 3:
		return PReturnO2_final.new()
	else:
		assert(false, "Unknow protocol id: "+str(id))
