@tool
extends PopupPanel

signal value_changed(data : ScalableArc)

var rx_input : EditorSpinSlider
var ry_input : EditorSpinSlider
var rotation_input : EditorSpinSlider
var large_arc_checkbox : CheckBox
var sweep_checkbox : CheckBox

var start_point_idx : int = 0
var _dragging := false
var _drag_start := Vector2.ZERO

func _enter_tree() -> void:
	rx_input = _mk_input()
	ry_input = _mk_input()
	rotation_input = _mk_input(1.0)
	large_arc_checkbox = find_child("LargeArcCheckBox")
	sweep_checkbox = find_child("SweepCheckBox")
	find_child("RxInputContainer").add_child(rx_input)
	find_child("RyInputContainer").add_child(ry_input)
	find_child("RotationInputContainer").add_child(rotation_input)
	if not rx_input.value_changed.is_connected(_on_value_changed):
		rx_input.value_changed.connect(_on_value_changed)
	if not ry_input.value_changed.is_connected(_on_value_changed):
		ry_input.value_changed.connect(_on_value_changed)
	if not rotation_input.value_changed.is_connected(_on_value_changed):
		rotation_input.value_changed.connect(_on_value_changed)

func _on_button_pressed() -> void:
	hide()


func _on_value_changed(_v : Variant = null):
	value_changed.emit(ScalableArc.new(start_point_idx, Vector2(rx_input.value, ry_input.value),
			rotation_input.value, large_arc_checkbox.button_pressed, sweep_checkbox.button_pressed))


func popup_with_value(arc : ScalableArc):
	start_point_idx = arc.start_point
	rx_input.set_value_no_signal(arc.radius.x)
	ry_input.set_value_no_signal(arc.radius.y)
	rotation_input.set_value_no_signal(arc.rotation_deg)
	_on_value_changed()
	popup_centered()


func _mk_input(step := 0.001) -> EditorSpinSlider:
	var num_input := EditorSpinSlider.new()
	num_input.suffix = "px"
	num_input.hide_slider = true
	num_input.value = 0.0
	num_input.editing_integer = false
	num_input.allow_lesser = true
	num_input.allow_greater = true
	num_input.step = 0.001
	return num_input


func _on_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if not _dragging:
				_dragging = true
				_drag_start = EditorInterface.get_base_control().get_local_mouse_position()
		else:
			_dragging = false
	if event is InputEventMouseMotion and _dragging:
		position += Vector2i(EditorInterface.get_base_control().get_local_mouse_position() - _drag_start)
		_drag_start = EditorInterface.get_base_control().get_local_mouse_position()
