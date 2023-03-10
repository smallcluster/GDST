@tool
extends Node3D
class_name Lines3D

func create_line(start : Vector3, end : Vector3, color : Color = Color.WHITE) -> void :
	var mesh_inst := MeshCreator.create_line(start, end, color)
	add_child(mesh_inst)
	
func create_graph(points : Array[Vector3], color : Color = Color.WHITE) -> void:
	var mesh_int := MeshCreator.create_graph(points, color)
	add_child(mesh_int)
	
func clear() -> void:
	var c := get_children()
	for l in c:
		l.queue_free()
