@tool
extends VBoxContainer

class_name ScalableVectorShapeEditTab

signal toggle_editing(flg : bool)
signal toggle_hints(flg : bool)
signal shape_added(shape : Node2D)

var rect_width_input : EditorSpinSlider
var rect_height_input : EditorSpinSlider
var rect_rx_input : EditorSpinSlider
var rect_ry_input : EditorSpinSlider
var rect_stroke_width_input : EditorSpinSlider
var rect_stroke_color_button : ColorPickerButton
var rect_fill_color_button : ColorPickerButton

var ellipse_rx_input : EditorSpinSlider
var ellipse_ry_input : EditorSpinSlider
var ellipse_stroke_width_input : EditorSpinSlider
var ellipse_stroke_color_button : ColorPickerButton
var ellipse_fill_color_button : ColorPickerButton
var warning_dialog : AcceptDialog = null

func _enter_tree() -> void:
	rect_width_input = _make_int_input("Width", 100, 2, 1000, "px")
	rect_height_input = _make_int_input("Height", 100, 2, 1000, "px")
	rect_rx_input = _make_int_input("Corner Radius X", 0, 0, 500, "px")
	rect_ry_input = _make_int_input("Corner Radius Y", 0, 0, 500, "px")
	rect_stroke_color_button = find_child("StrokePickerButton")
	rect_fill_color_button = find_child("FillPickerButton")
	rect_stroke_width_input = _make_int_input("Stroke Width", 1, 0, 100, "px")
	find_child("WidthSliderContainer").add_child(rect_width_input)
	find_child("HeightSliderContainer").add_child(rect_height_input)
	find_child("XRadiusSliderContainer").add_child(rect_rx_input)
	find_child("YRadiusSliderContainer").add_child(rect_ry_input)
	find_child("StrokeWidthContainer").add_child(rect_stroke_width_input)
	ellipse_rx_input = _make_int_input("Horizontal Radius (RX)", 50, 1, 500, "px")
	ellipse_ry_input = _make_int_input("Vertical Radius (RY)", 50, 1, 500, "px")
	ellipse_stroke_width_input = _make_int_input("Stroke Width", 1, 0, 100, "px")
	ellipse_stroke_color_button = find_child("EllipseStrokePickerButton")
	ellipse_fill_color_button = find_child("EllipseFillPickerButton")
	find_child("EllipseXRadiusSliderContainer").add_child(ellipse_rx_input)
	find_child("EllipseYRadiusSliderContainer").add_child(ellipse_ry_input)
	find_child("EllipseStrokeWidthContainer").add_child(ellipse_stroke_width_input)


func _make_int_input(lbl : String, value : int, min_value : int, max_value : int, suffix : String) -> EditorSpinSlider:
	var x_slider := EditorSpinSlider.new()
	x_slider.value = value
	x_slider.min_value = min_value
	x_slider.max_value = max_value
	x_slider.suffix = suffix
	x_slider.label = lbl
	return x_slider


func _on_create_rect_button_pressed() -> void:
	var scene_root := EditorInterface.get_edited_scene_root()
	if not is_instance_valid(scene_root):
		warning_dialog.dialog_text = "Can only create a shape in an open 2D scene"
		warning_dialog.popup_centered()
		return

	if not scene_root is Node2D:
		warning_dialog.dialog_text = "Can only create a shape in an open 2D scene"
		warning_dialog.popup_centered()
		return

	var curve := Curve2D.new()
	if rect_rx_input.value == 0 and rect_ry_input.value == 0:
		curve.add_point(Vector2.ZERO)
		curve.add_point(Vector2(rect_width_input.value, 0))
		curve.add_point(Vector2(rect_width_input.value, rect_height_input.value))
		curve.add_point(Vector2(0, rect_height_input.value))
	else:
		curve.add_point(Vector2(rect_width_input.value - rect_rx_input.value, 0), Vector2.ZERO, Vector2(rect_rx_input.value * SvgImporterDock.R_TO_CP, 0))
		curve.add_point(Vector2(rect_width_input.value, rect_ry_input.value), Vector2(0, -rect_ry_input.value * SvgImporterDock.R_TO_CP))
		curve.add_point(Vector2(rect_width_input.value, rect_height_input.value - rect_ry_input.value), Vector2.ZERO, Vector2(0, rect_ry_input.value * SvgImporterDock.R_TO_CP))
		curve.add_point(Vector2(rect_width_input.value - rect_rx_input.value, rect_height_input.value), Vector2(rect_rx_input.value * SvgImporterDock.R_TO_CP, 0))
		curve.add_point(Vector2(rect_rx_input.value, rect_height_input.value), Vector2.ZERO, Vector2(-rect_rx_input.value * SvgImporterDock.R_TO_CP, 0))
		curve.add_point(Vector2(0, rect_height_input.value - rect_ry_input.value), Vector2(0, rect_ry_input.value * SvgImporterDock.R_TO_CP))
		curve.add_point(Vector2(0, rect_ry_input.value), Vector2.ZERO, Vector2(0, -rect_ry_input.value *  SvgImporterDock.R_TO_CP))
		curve.add_point(Vector2(rect_rx_input.value, 0), Vector2(-rect_rx_input.value * SvgImporterDock.R_TO_CP, 0))
	_create_new_shape(curve, scene_root, "Rectangle", rect_stroke_width_input.value,
			rect_stroke_color_button.color, rect_fill_color_button.color)


func _on_create_circle_button_pressed() -> void:
	var scene_root := EditorInterface.get_edited_scene_root()
	if not is_instance_valid(scene_root):
		warning_dialog.dialog_text = "Can only create a Shape in an open 2D scene"
		return
	if not scene_root is Node2D:
		warning_dialog.dialog_text = "Can only create a Shape in an open 2D scene"
		warning_dialog.popup_centered()
		return

	var curve := Curve2D.new()
	curve.add_point(Vector2(ellipse_rx_input.value, 0), Vector2.ZERO, Vector2(0, ellipse_ry_input.value * SvgImporterDock.R_TO_CP))
	curve.add_point(Vector2(0, ellipse_ry_input.value), Vector2(ellipse_rx_input.value * SvgImporterDock.R_TO_CP, 0), Vector2(-ellipse_rx_input.value * SvgImporterDock.R_TO_CP, 0))
	curve.add_point(Vector2(-ellipse_rx_input.value, 0), Vector2(0, ellipse_ry_input.value * SvgImporterDock.R_TO_CP), Vector2(0, -ellipse_ry_input.value * SvgImporterDock.R_TO_CP))
	curve.add_point(Vector2(0, -ellipse_ry_input.value), Vector2(-ellipse_rx_input.value * SvgImporterDock.R_TO_CP, 0), Vector2(ellipse_rx_input.value * SvgImporterDock.R_TO_CP, 0))
	curve.add_point(Vector2(ellipse_rx_input.value, 0), Vector2(0, -ellipse_ry_input.value * SvgImporterDock.R_TO_CP))
	var node_name := "Circle" if ellipse_rx_input.value == ellipse_ry_input.value else "Ellipse"
	_create_new_shape(curve, scene_root, node_name, ellipse_stroke_width_input.value,
			ellipse_stroke_color_button.color, ellipse_fill_color_button.color)

func _get_viewport_center() -> Vector2:
	var tr := EditorInterface.get_editor_viewport_2d().global_canvas_transform
	var og := tr.get_origin()
	var sz := Vector2(EditorInterface.get_editor_viewport_2d().size)
	return (sz / 2) / tr.get_scale() - og / tr.get_scale()


func _create_new_shape(curve : Curve2D, scene_root : Node2D, node_name : String,
			stroke_width : int, stroke_color : Color, fill_color : Color) -> void:
	var undo_redo := EditorInterface.get_editor_undo_redo()
	var new_shape := ScalableVectorShape2D.new()

	new_shape.name = node_name
	new_shape.position = _get_viewport_center()
	new_shape.curve = curve

	undo_redo.create_action("Add a %s to the scene " % node_name)
	undo_redo.add_do_method(scene_root, 'add_child', new_shape, true)
	undo_redo.add_do_method(new_shape, 'set_owner', scene_root)
	undo_redo.add_do_reference(new_shape)
	undo_redo.add_undo_method(scene_root, 'remove_child', new_shape)


	var polygon := Polygon2D.new()
	polygon.name = "Fill"
	polygon.color = fill_color

	undo_redo.add_do_property(new_shape, 'polygon', polygon)
	undo_redo.add_do_method(new_shape, 'add_child', polygon, true)
	undo_redo.add_do_method(polygon, 'set_owner', scene_root)
	undo_redo.add_do_reference(polygon)
	undo_redo.add_undo_method(new_shape, 'remove_child', polygon)

	var line := Line2D.new()
	line.name = "Stroke"
	line.closed = true
	line.default_color = stroke_color
	line.width = stroke_width

	# undo/redo stuff
	undo_redo.add_do_property(new_shape, 'line', line)
	undo_redo.add_do_method(new_shape, 'add_child', line, true)
	undo_redo.add_do_method(line, 'set_owner', scene_root)
	undo_redo.add_do_reference(line)
	undo_redo.add_undo_method(new_shape, 'remove_child', line)
	undo_redo.commit_action()
	shape_added.emit(new_shape)


func _on_enable_editing_checkbox_toggled(toggled_on: bool) -> void:
	toggle_editing.emit(toggled_on)


func _on_enable_hints_checkbox_toggled(toggled_on: bool) -> void:
	toggle_hints.emit(toggled_on)
