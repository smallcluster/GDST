class_name MeshCreator

static func create_line(start : Vector3, end : Vector3, color : Color = Color.WHITE) -> MeshInstance3D :
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
	return mesh_inst
	
static func create_graph(points : Array[Vector3], color : Color = Color.WHITE) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	var mat := ORMMaterial3D.new()
	mesh_inst.mesh = mesh
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	for p in points:
		mesh.surface_add_vertex(p)
	mesh.surface_end()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	return mesh_inst
	
	
static func create_circle(radius : float, color : Color, resolution : int = 32) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	var mat := ORMMaterial3D.new()
	mesh_inst.mesh = mesh
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	var cursor := Vector3(0, radius, 0)
	var rot := (360.0 * PI) / (resolution * 180.0)
	for i in range(resolution):
		mesh.surface_add_vertex(cursor)
		cursor = cursor.rotated(Vector3(0, 0, 1), rot)
		mesh.surface_add_vertex(cursor)
	mesh.surface_end()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.disable_receive_shadows = true
	mat.no_depth_test = true
	mat.render_priority = 10
	return mesh_inst
