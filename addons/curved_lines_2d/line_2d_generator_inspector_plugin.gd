@tool
extends EditorInspectorPlugin

class_name  Line2DGeneratorInspectorPlugin

const GROUP_NAME_CURVE_SETTINGS := "Curve settings"


func _can_handle(obj) -> bool:
	return obj is DrawablePath2D or obj is ScalableVectorShape2D


func _parse_begin(object: Object) -> void:
	if object is DrawablePath2D:
		var warning_label := Label.new()
		warning_label.text = "⚠️ DrawablePath2D is Deprecated"
		add_custom_control(warning_label)
		var button : Button = Button.new()
		button.text = "Convert to ScalableVectorShape2D"
		add_custom_control(button)
		button.pressed.connect(func(): _on_convert_button_pressed(object))


func _parse_group(object: Object, group: String) -> void:
	if group == GROUP_NAME_CURVE_SETTINGS and object is ScalableVectorShape2D:
		var key_frame_form = load("res://addons/curved_lines_2d/batch_insert_curve_point_key_frames_inspector_form.tscn").instantiate()
		key_frame_form.scalable_vector_shape_2d = object
		add_custom_control(key_frame_form)


func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if name == "line" and (object is  ScalableVectorShape2D):
		var assign_stroke_inspector_form = load("res://addons/curved_lines_2d/assign_stroke_inspector_form.tscn").instantiate()
		assign_stroke_inspector_form.scalable_vector_shape_2d = object
		add_custom_control(assign_stroke_inspector_form)
	elif name == "polygon" and (object  is ScalableVectorShape2D):
		var assign_fill_inspector_form = load("res://addons/curved_lines_2d/assign_fill_inspector_form.tscn").instantiate()
		assign_fill_inspector_form.scalable_vector_shape_2d = object
		add_custom_control(assign_fill_inspector_form)
	elif name == "collision_polygon" and (object is ScalableVectorShape2D):
		var assign_collision_inspector_form = load("res://addons/curved_lines_2d/assign_collision_inspector_form.tscn").instantiate()
		assign_collision_inspector_form.scalable_vector_shape_2d = object
		add_custom_control(assign_collision_inspector_form)
	return false


func _on_convert_button_pressed(orig : DrawablePath2D):
	var replacement := ScalableVectorShape2D.new()
	replacement.transform = orig.transform
	replacement.tolerance_degrees = orig.tolerance_degrees
	replacement.max_stages = orig.max_stages
	replacement.lock_assigned_shapes = orig.lock_assigned_shapes
	replacement.update_curve_at_runtime = orig.update_curve_at_runtime
	if orig.curve:
		replacement.curve = orig.curve
	if is_instance_valid(orig.line):
		replacement.line = orig.line
	if is_instance_valid(orig.polygon):
		replacement.polygon = orig.polygon
	if is_instance_valid(orig.collision_polygon):
		replacement.collision_polygon = orig.collision_polygon
	orig.replace_by(replacement, true)
	replacement.name = "ScalableVectorShape2D" if orig.name == "DrawablePath2D" else orig.name
	EditorInterface.call_deferred('edit_node', replacement)
