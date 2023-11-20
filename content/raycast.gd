extends Node3D

@onready var _controller := XRHelpers.get_xr_controller(self)
@export var ray: RayCast3D
@export var timespan_click = 200.0

# Called when the node enters the scene tree for the first time.
func _ready():
	_controller.button_pressed.connect(_on_button_pressed)
	_controller.button_released.connect(_on_button_released)

var _last_collided: Object = null
var _is_pressed := false
var _is_grabbed := false
var _time_pressed := 0.0
var _moved := false
var _click_point := Vector3.ZERO

func _physics_process(delta):
	_handle_enter_leave()
	_handle_move()

func _handle_move():
	var time_passed = Time.get_ticks_msec() - _time_pressed
	if time_passed <= timespan_click || (_is_pressed == false && _is_grabbed == false):
		return

	_moved = true

	if _is_pressed:
		_call_fn(_last_collided, "_on_press_move")
		
	if _is_grabbed:
		_call_fn(_last_collided, "_on_grab_move")

func _handle_enter_leave():
	var collider = ray.get_collider()

	if collider == _last_collided || _is_grabbed || _is_pressed:
		return

	_call_fn(collider, "_on_ray_enter")
	_call_fn(_last_collided, "_on_ray_leave")

	_last_collided = collider

func _on_button_pressed(button):
	var collider = ray.get_collider()

	if collider == null:
		return

	match button:
		"trigger_click":
			_is_pressed = true
			_time_pressed = Time.get_ticks_msec()
			_click_point = ray.get_collision_point()
			_call_fn(collider, "_on_press_down")
		"grip_click":
			_is_grabbed = true
			_click_point = ray.get_collision_point()
			_call_fn(collider, "_on_grab_down")

func _on_button_released(button):
	if _last_collided == null:
		return

	match button:
		"trigger_click":
			if _is_pressed:
				if _moved == false:
					_call_fn(_last_collided, "_on_click")
				_call_fn(_last_collided, "_on_press_up")
				_is_pressed = false
				_last_collided = null
				_moved = false
		"grip_click":
			if _is_grabbed:
				_call_fn(_last_collided, "_on_grab_up")
				_is_grabbed = false
				_last_collided = null
				_moved = false

func _call_fn(collider: Variant, fn_name: String, node: Node3D = null, event = null):
	if collider == null:
		return

	if node == null:
		node = collider
		event = {
			"controller": _controller,
			"ray": ray,
			"target": collider,
		}

	if node.has_method(fn_name):
		var result = node.call(fn_name, event)

		if result != null && result is Dictionary:
			result.merge(event, true)
			event = result

		if result != null && result is bool && result == false:
			# Stop the event from bubbling up
			return

	for child in node.get_children():
		if child is Function && child.has_method(fn_name):
			child.call(fn_name, event)
			

	var parent = node.get_parent()

	if parent != null && parent is Node3D:
		_call_fn(collider, fn_name, parent, event)
	else:
		# in case the top has been reached
		_call_global_fn(fn_name, event)

func _call_global_fn(fn_name: String, event = null):
	Events.get(fn_name.substr(1)).emit(event)