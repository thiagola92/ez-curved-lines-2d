@tool
extends Control

class_name ScalableVectorShapeEditTab

signal shape_created(curve : Curve2D, scene_root : Node2D, node_name : String,
			stroke_width : int, stroke_color : Color, fill_color : Color)

var stroke_width_input : EditorSpinSlider
var stroke_color_button : ColorPickerButton
var fill_color_button : ColorPickerButton

var rect_width_input : EditorSpinSlider
var rect_height_input : EditorSpinSlider
var rect_rx_input : EditorSpinSlider
var rect_ry_input : EditorSpinSlider

var ellipse_rx_input : EditorSpinSlider
var ellipse_ry_input : EditorSpinSlider

var warning_dialog : AcceptDialog = null

func _enter_tree() -> void:
	rect_width_input = _make_number_input("Width", 100, 2, 1000, "")
	rect_height_input = _make_number_input("Height", 100, 2, 1000, "")
	rect_rx_input = _make_number_input("Corner Radius X", 0, 0, 500, "")
	rect_ry_input = _make_number_input("Corner Radius Y", 0, 0, 500, "")
	stroke_color_button = find_child("StrokePickerButton")
	fill_color_button = find_child("FillPickerButton")
	stroke_width_input = _make_number_input("Stroke Width", 10.0, 0.0, 100.0, "", 0.01)
	find_child("WidthSliderContainer").add_child(rect_width_input)
	find_child("HeightSliderContainer").add_child(rect_height_input)
	find_child("XRadiusSliderContainer").add_child(rect_rx_input)
	find_child("YRadiusSliderContainer").add_child(rect_ry_input)
	find_child("StrokeWidthContainer").add_child(stroke_width_input)
	ellipse_rx_input = _make_number_input("Horizontal Radius (RX)", 50, 1, 500, "")
	ellipse_ry_input = _make_number_input("Vertical Radius (RY)", 50, 1, 500, "")
	find_child("EllipseXRadiusSliderContainer").add_child(ellipse_rx_input)
	find_child("EllipseYRadiusSliderContainer").add_child(ellipse_ry_input)


func _make_number_input(lbl : String, value : float, min_value : float, max_value : float, suffix : String, step := 1.0) -> EditorSpinSlider:
	var x_slider := EditorSpinSlider.new()
	x_slider.value = value
	x_slider.min_value = min_value
	x_slider.max_value = max_value
	x_slider.suffix = suffix
	x_slider.label = lbl
	x_slider.step = step
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
		curve.add_point(Vector2.ZERO)
	else:
		curve.add_point(Vector2(rect_width_input.value - rect_rx_input.value, 0), Vector2.ZERO, Vector2(rect_rx_input.value * SvgImporterDock.R_TO_CP, 0))
		curve.add_point(Vector2(rect_width_input.value, rect_ry_input.value), Vector2(0, -rect_ry_input.value * SvgImporterDock.R_TO_CP))
		curve.add_point(Vector2(rect_width_input.value, rect_height_input.value - rect_ry_input.value), Vector2.ZERO, Vector2(0, rect_ry_input.value * SvgImporterDock.R_TO_CP))
		curve.add_point(Vector2(rect_width_input.value - rect_rx_input.value, rect_height_input.value), Vector2(rect_rx_input.value * SvgImporterDock.R_TO_CP, 0))
		curve.add_point(Vector2(rect_rx_input.value, rect_height_input.value), Vector2.ZERO, Vector2(-rect_rx_input.value * SvgImporterDock.R_TO_CP, 0))
		curve.add_point(Vector2(0, rect_height_input.value - rect_ry_input.value), Vector2(0, rect_ry_input.value * SvgImporterDock.R_TO_CP))
		curve.add_point(Vector2(0, rect_ry_input.value), Vector2.ZERO, Vector2(0, -rect_ry_input.value *  SvgImporterDock.R_TO_CP))
		curve.add_point(Vector2(rect_rx_input.value, 0), Vector2(-rect_rx_input.value * SvgImporterDock.R_TO_CP, 0))
		curve.add_point(Vector2(rect_width_input.value - rect_rx_input.value, 0), Vector2.ZERO, Vector2(rect_rx_input.value * SvgImporterDock.R_TO_CP, 0))
	shape_created.emit(curve, scene_root, "Rectangle", stroke_width_input.value, stroke_color_button.color, fill_color_button.color)


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
	shape_created.emit(curve, scene_root, node_name, stroke_width_input.value, stroke_color_button.color, fill_color_button.color)


func _on_enable_editing_checkbox_toggled(toggled_on: bool) -> void:
	ProjectSettings.set_setting(CurvedLines2D.SETTING_NAME_EDITING_ENABLED, toggled_on)
	ProjectSettings.save()


func _on_enable_hints_checkbox_toggled(toggled_on: bool) -> void:
	ProjectSettings.set_setting(CurvedLines2D.SETTING_NAME_HINTS_ENABLED, toggled_on)
	ProjectSettings.save()
