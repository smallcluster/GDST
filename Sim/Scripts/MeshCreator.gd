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
	
static func create_graph(points : Array[Vector3], color : Color = Color.WHITE, directed : bool = true, size : float = 0.3) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	var mat := ORMMaterial3D.new()
	mesh_inst.mesh = mesh
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	
	for i in range(0, points.size(), 2):
		# line
		var start := points[i]
		var end := points[i+1]
		mesh.surface_add_vertex(start)
		mesh.surface_add_vertex(end)
		
		if not directed:
			continue
			
		# piramid 
		var dir = (end - start).normalized()
		var h = size
		var r = size/4
		var tip = (end + start) / 2 + dir * (h/2)
		
		var right = dir.cross(Vector3.UP).normalized() if dir.dot(Vector3.UP) != 1 else dir.cross(Vector3.BACK).normalized()
		var top = right.cross(dir).normalized()
		
		var base = tip - dir * h
		
		# rectangle
		mesh.surface_add_vertex(base+right*r)
		mesh.surface_add_vertex(base+top*r)
		
		mesh.surface_add_vertex(base+top*r)
		mesh.surface_add_vertex(base-right*r)
		
		mesh.surface_add_vertex(base-right*r)
		mesh.surface_add_vertex(base-top*r)
		
		mesh.surface_add_vertex(base-top*r)
		mesh.surface_add_vertex(base+right*r)
		
		# pic
		mesh.surface_add_vertex(tip)
		mesh.surface_add_vertex(base+right*r)
		mesh.surface_add_vertex(tip)
		mesh.surface_add_vertex(base-right*r)
		mesh.surface_add_vertex(tip)
		mesh.surface_add_vertex(base+top*r)
		mesh.surface_add_vertex(tip)
		mesh.surface_add_vertex(base-top*r)
		
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
	
static func create_cylinder(radius : float, height : float, color : Color, resolution : int = 32) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	var mat := ORMMaterial3D.new()
	mesh_inst.mesh = mesh
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	
	var cursor := Vector3(radius, 0 , 0)
	var rot := (360.0 * PI) / (resolution * 180.0)
	var dy := Vector3(0,-height,0)
	
	for i in range(resolution):
		var rotated_cursor := cursor.rotated(Vector3(0, 1, 0), rot)
		# Top
		mesh.surface_add_vertex(cursor)
		mesh.surface_add_vertex(rotated_cursor)
		# Bottom
		mesh.surface_add_vertex(cursor+dy)
		mesh.surface_add_vertex(rotated_cursor+dy)
		
		cursor = rotated_cursor
		
	# sides
	mesh.surface_add_vertex(Vector3(radius, 0, 0))
	mesh.surface_add_vertex(Vector3(radius, -height, 0))
	
	mesh.surface_add_vertex(Vector3(-radius, 0, 0))
	mesh.surface_add_vertex(Vector3(-radius, -height, 0))
	
	mesh.surface_add_vertex(Vector3(0, 0, radius))
	mesh.surface_add_vertex(Vector3(0, -height, radius))
	
	mesh.surface_add_vertex(Vector3(0, 0, -radius))
	mesh.surface_add_vertex(Vector3(0, -height, -radius))
		
	mesh.surface_end()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.disable_receive_shadows = true
	mat.no_depth_test = true
	mat.render_priority = 10
	return mesh_inst
