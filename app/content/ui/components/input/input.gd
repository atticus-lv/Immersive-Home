@tool
extends StaticBody3D
class_name Input3D

var text_handler = preload ("res://content/ui/components/input/text_handler.gd").new()

@onready var caret: MeshInstance3D = $Label/Caret
@onready var mesh_box: MeshInstance3D = $Box
@onready var collision: CollisionShape3D = $Collision
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var label: Label3D = $Label

@export_range(0.1, 2, 0.01, "suffix:m") var width: float = 0.15:
	set(value):
		width = value
		text_handler.width = value
		if !is_inside_tree(): return

		mesh_box.mesh.size.x = width
		collision.shape.size.x = width
		label.position.x = -width / 2 + 0.002
	
@export var text: String:
	set(value):
		text = value
		if !is_inside_tree(): return

		var focused = Engine.is_editor_hint() == false&&EventSystem.is_focused(self) == false
		text_handler.set_text(text, focused)
		label.text = text_handler.get_display_text()

@export var disabled: bool = false:
	set(value):
		disabled = value
		if !is_inside_tree(): return
			
		if disabled:
			label.modulate = Color(0.7, 0.7, 0.7)
			add_to_group("ui_focus_skip")
			animation.stop()
			caret.hide()
		else:
			label.modulate = Color(1, 1, 1)
			remove_from_group("ui_focus_skip")

var keyboard_input: bool = false

var input_plane = Plane(Vector3.UP, Vector3.ZERO)

func _ready():
	Update.props(self, ["text", "disabled", "width"])

	text_handler.label = label

	if Engine.is_editor_hint():
		return

	EventSystem.on_key_down.connect(func(event):
		if EventSystem.is_focused(self) == false||disabled:
			return

		text=EventKey.key_to_string(event.key, event.shift_pressed, text.substr(0, text_handler.caret_position)) + text.substr(text_handler.caret_position, text.length())
		caret.position.x=text_handler.get_caret_position()
		label.text=text_handler.get_display_text()
	)

func _input(event):
	if event is InputEventKey&&EventSystem.is_focused(self)&&event.pressed:
		if event.keycode == KEY_F1:
			keyboard_input = !keyboard_input
			return

		if disabled:
			return

		if keyboard_input:
			text = EventKey.key_to_string(event.keycode, event.shift_pressed, text.substr(0, text_handler.caret_position)) + text.substr(text_handler.caret_position, text.length())
			caret.position.x = text_handler.get_caret_position()
		
func _process(_delta):
	if Engine.is_editor_hint():
		return

	if get_tree().debug_collisions_hint&&OS.get_name() != "Android":
		_draw_debug_text_gaps()
	
func _on_press_down(event):
	if disabled:
		return

	var pos_x = label.to_local(event.ray.get_collision_point()).x
	text_handler.update_caret_position(pos_x)

func _on_press_move(event):
	if disabled:
		return

	var ray_pos = event.ray.global_position
	var ray_dir = -event.ray.global_transform.basis.z

	var local_pos = label.to_local(ray_pos)
	var local_dir = label.global_transform.basis.inverse() * ray_dir

	var intersection_point = input_plane.intersects_ray(local_pos, local_dir)

	if intersection_point == null:
			return

	var pos_x = intersection_point.x
	text_handler.update_caret_position(pos_x)

	caret.position.x = text_handler.get_caret_position()
	label.text = text_handler.get_display_text()

func _on_focus_in(_event):
	if disabled:
		return

	caret.position.x = text_handler.get_caret_position()
	label.text = text_handler.get_display_text()
	caret.show()
	animation.play("blink")

func update_caret_position(event):
	var ray_pos = event.ray.global_position
	var ray_dir = -event.ray.global_transform.basis.z

	var local_pos = label.to_local(ray_pos)
	var local_dir = label.global_transform.basis.inverse() * ray_dir

	var intersection_point = input_plane.intersects_ray(local_pos, local_dir)

	if intersection_point == null:
			return

	var pos_x = intersection_point.x
	text_handler.update_caret_position(pos_x)

	caret.position.x = text_handler.get_caret_position()

func _on_focus_out(_event):
	if disabled:
		return

	animation.stop()
	caret.hide()

func _draw_debug_text_gaps():
	if text_handler.gap_offsets == null:
		return

	for i in range(text_handler.gap_offsets.size()):
		var offset = text_handler.gap_offsets[i] - text_handler.gap_offsets[text_handler.char_offset]
		DebugDraw3D.draw_line(
			label.to_global(Vector3(offset, -0.01, 0)),
			label.to_global(Vector3(offset, 0.01, 0)),
			Color(1, 0, 0) if i != text_handler.overflow_index else Color(0, 1, 0)
		)
