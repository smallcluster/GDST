@tool
extends Node3D
class_name Lines3D

func create_line(start : Vector3, end : Vector3, color : Color = Color.WHITE) -> MeshInstance3D :
	var mesh_inst := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	var mat := ORMMaterial3D.new()
	mesh_inst.mesh = mesh
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	mesh.surface_add_vertex(start)
	mesh.surface_add_vertex(end)
	mesh.surface_end()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	add_child(mesh_inst)
	return mesh_inst
	
func clear() -> void:
	var c := get_children()
	for l in c:
		l.queue_free()
