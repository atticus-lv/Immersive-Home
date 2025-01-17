extends Node3D

const ConstructRoomMesh = preload ("res://lib/utils/mesh/construct_room_mesh.gd")

@onready var wall_corners = $Ceiling/WallCorners
@onready var wall_edges = $Ceiling/WallEdges
@onready var wall_mesh: MeshInstance3D = $WallMesh
@onready var ceiling_mesh: MeshInstance3D = $CeilingMesh
@onready var wall_collision = $WallCollision/CollisionShape3D

@onready var room_floor = $Floor
@onready var room_ceiling = $Ceiling

@onready var state_machine = $StateMachine

var editable: bool = false:
	set(value):
		editable = value
		
		if !is_inside_tree(): return
		
		if editable:
			state_machine.change_to("Edit")
		else:
			state_machine.change_to("View")

func _ready():
	Update.props(self, ["editable"])

func has_point(point: Vector3) -> bool:
	return get_aabb().has_point(point)

func get_aabb():
	var room_store = Store.house.get_room(name)

	if room_store == null:
		return AABB()

	var corners = room_store.corners

	if corners.size() == 0:
		return AABB()

	var min_pos = Vector3(corners[0].x, 0, corners[0].y)
	var max_pos = min_pos

	for corner in corners:
		min_pos.x = min(min_pos.x, corner.x)
		min_pos.z = min(min_pos.z, corner.y)

		max_pos.x = max(max_pos.x, corner.x)
		max_pos.z = max(max_pos.z, corner.y)

	min_pos.y = 0
	max_pos.y = room_store.height

	return AABB(to_global(min_pos), to_global(max_pos) - to_global(min_pos))

static func generate_wall_mesh(room_store: Dictionary):
	var corners = room_store.corners
	var height = room_store.height

	return ConstructRoomMesh.generate_wall_mesh(corners, height)

static func generate_ceiling_mesh(room_store: Dictionary):
	var corners = room_store.corners

	return ConstructRoomMesh.generate_ceiling_mesh(corners)
