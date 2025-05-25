@tool
extends EditorInspectorPlugin

var assign_stroke_inspector_form : Control

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


func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if name == "line" and (object is DrawablePath2D or object is ScalableVectorShape2D):
		assign_stroke_inspector_form = preload("res://addons/curved_lines_2d/assign_stroke_inspector_form.tscn").instantiate()
		assign_stroke_inspector_form.scalable_vector_shape_2d = object
		add_custom_control(assign_stroke_inspector_form)
		return true
	elif name == "polygon" and (object is DrawablePath2D or object is ScalableVectorShape2D):
		var button : Button = Button.new()
		button.text = "Generate New Polygon2D"
		add_custom_control(button)
		button.pressed.connect(func(): _on_generate_polygon2d_button_pressed(object))
	elif name == "collision_polygon" and (object is DrawablePath2D or object is ScalableVectorShape2D):
		var button : Button = Button.new()
		button.text = "Generate New CollisionPolygon2D"
		add_custom_control(button)
		button.pressed.connect(func(): _on_generate_collision_polygon2d_button_pressed(object))
	return false


func _on_convert_button_pressed(orig : DrawablePath2D):
	var replacement := ScalableVectorShape2D.new()
	replacement.name = "ScalableVectorShape2D" if orig.name == "DrawablePath2D" else orig.name
	replacement.transform = orig.transform
	replacement.tolerance_degrees = orig.tolerance_degrees
	replacement.max_stages = orig.max_stages
	replacement.lock_assigned_shapes = orig.lock_assigned_shapes
	replacement.update_curve_at_runtime = orig.update_curve_at_runtime
	if orig.curve:
		replacement.curve = orig.curve
	if orig.line:
		replacement.line = orig.line
	if orig.polygon:
		replacement.polygon = orig.polygon
	if orig.collision_polygon:
		replacement.collision_polygon = orig.collision_polygon
	orig.replace_by(replacement, true)
	orig.queue_free()


func _on_generate_polygon2d_button_pressed(drawable_path_2d):
	var polygon_2d := Polygon2D.new()
	var root := EditorInterface.get_edited_scene_root()
	var undo_redo = EditorInterface.get_editor_undo_redo()
	undo_redo.create_action("Add Line2D to %s " % str(drawable_path_2d))
	undo_redo.add_do_method(drawable_path_2d, 'add_child', polygon_2d, true)
	undo_redo.add_do_method(polygon_2d, 'set_owner', root)
	undo_redo.add_do_reference(polygon_2d)
	undo_redo.add_do_property(drawable_path_2d, 'polygon', polygon_2d)
	undo_redo.add_undo_method(drawable_path_2d, 'remove_child', polygon_2d)
	undo_redo.add_undo_property(drawable_path_2d, 'polygon', null)
	undo_redo.commit_action()


func _on_generate_collision_polygon2d_button_pressed(drawable_path_2d):
	var collision_polygon_2d := CollisionPolygon2D.new()
	var root := EditorInterface.get_edited_scene_root()
	var undo_redo = EditorInterface.get_editor_undo_redo()
	undo_redo.create_action("Add Line2D to %s " % str(drawable_path_2d))
	undo_redo.add_do_method(drawable_path_2d, 'add_child', collision_polygon_2d, true)
	undo_redo.add_do_method(collision_polygon_2d, 'set_owner', root)
	undo_redo.add_do_reference(collision_polygon_2d)
	undo_redo.add_do_property(drawable_path_2d, 'collision_polygon', collision_polygon_2d)
	undo_redo.add_undo_method(drawable_path_2d, 'remove_child', collision_polygon_2d)
	undo_redo.add_undo_property(drawable_path_2d, 'collision_polygon', null)
	undo_redo.commit_action()
