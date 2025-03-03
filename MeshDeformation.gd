extends MeshInstance3D

# the distance the collision affects
@export var collision_radius := 5.0 

# the point of collision denoted with a marker
@onready var collision_marker: Node3D = $"../../Markers/CollisionMarker"

const MARKER = preload("res://Markers/marker.tscn")

## we store the original so that we can revert to it if we choose to
var original_mesh: Mesh

func _ready() -> void:
	original_mesh = mesh


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("deform_mesh"):
		deform_mesh()
	
	if Input.is_action_just_pressed("restore_mesh"):
		restore_mesh()


func deform_mesh():
	var box_array_mesh := ArrayMesh.new()
	
	# for each surface in the mesh we store its arrays in a new surface array
	var new_surface_array: Array = []
	for surf: int in mesh.get_surface_count():
		var surface_arrays: Array = mesh.surface_get_arrays(surf)
		new_surface_array.append(surface_arrays)
	
	# we scan through each vertex in the mesh and modify it by some amount
	# dependent on how far the vertex is, from the collision
	for surf: int in new_surface_array.size():
		# NOTE: the vertices index is always zero, normals is always 1
		var vertices: Array = new_surface_array[surf][0]
		# we scan through each vertex in each surface
		for vert in vertices.size():
			var individual_vertex: Vector3 = vertices[vert]
			var new_modified_vertex: Vector3 = process_vertex(individual_vertex)
			# we then store the modified vertex back in the new surface array
			new_surface_array[surf][0][vert] = new_modified_vertex
	
	# We should also recalculate normals here but I'm yet to figure out a formula
	# to do this, so for now the mesh's lighting will go wonky after substantial
	# deformation
	
	# we then reconstitute a modified mesh from the new surface array 
	for surf: int in new_surface_array.size():
		box_array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, new_surface_array[surf])
	
	# we add the original colors to this modified mesh
	for surf: int in mesh.get_surface_count():
		var mesh_material: Material = mesh.surface_get_material(surf)
		box_array_mesh.surface_set_material(surf, mesh_material)
	
	# lastly we assigned this array mesh that we created 
	mesh = box_array_mesh


func process_vertex(vertex: Vector3) -> Vector3:
	# the point where a collision occurs. it's important to make it local so that
	# we can compensate for meshes that have been translated from their origin
	var collision_point: Vector3 = to_local(collision_marker.global_position)
	
	# this indicates to us what direction the mesh should move from the collision point 
	var direction_from_collision: Vector3 = vertex - collision_point
	# a scalar to be used to calculate how far a vertex is from the collision point
	var distance_from_collision: float = direction_from_collision.length()
	
	# we clamp values such that if the vertices nearest to the collision are 
	# deformed more, up to the collision radius and then further away vertices 
	# are not affected 
	var inverted_distance_from_collision: float = clampf(1 - distance_from_collision / collision_radius, 0.0, 1.0)
	
	# the mesh deformation happens on a cubic curve
	var distance_away_squared: float = pow(inverted_distance_from_collision, 3)
	
	# we add the deformation factor to the original vertex
	return vertex + direction_from_collision.normalized() * distance_away_squared


func restore_mesh():
	mesh = original_mesh
