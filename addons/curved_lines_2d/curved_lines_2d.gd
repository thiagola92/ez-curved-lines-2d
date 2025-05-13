@tool
extends EditorPlugin

var plugin
var svg_importer_dock
var select_mode_button : Button

func _enter_tree():
	svg_importer_dock = preload("res://addons/curved_lines_2d/svg_importer_dock.tscn").instantiate()
	plugin = preload("res://addons/curved_lines_2d/line_2d_generator_inspector_plugin.gd").new()
	add_inspector_plugin(plugin)
	add_custom_type(
		"DrawablePath2D",
		"Path2D",
		preload("res://addons/curved_lines_2d/drawable_path_2d.gd"),
		preload("res://addons/curved_lines_2d/DrawablePath2D.svg")
	)
	add_custom_type(
		"ScalableVectorShape2D", 
		"Node2D", 
		preload("res://addons/curved_lines_2d/scalable_vector_shape_2d.gd"),
		preload("res://addons/curved_lines_2d/DrawablePath2D.svg")
	)
	svg_importer_dock.undo_redo = get_undo_redo()
	add_control_to_bottom_panel(svg_importer_dock as Control, "EZ SVG Importer")
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)


func _on_selection_changed():
	var scene_root := EditorInterface.get_edited_scene_root()
	if is_instance_valid(scene_root):
		for n in scene_root.find_children("*", "ScalableVectorShape2D"):
			n.queue_redraw()
		if (not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) 
				and EditorInterface.get_selection().get_selected_nodes().is_empty()):
			EditorInterface.edit_node(scene_root)


func _handles(object: Object) -> bool:
	return object is Node2D


func find_scalable_vector_shape_2d_nodes_at(pos : Vector2) -> Array[Node]:
	if is_instance_valid(EditorInterface.get_edited_scene_root()):
		return (EditorInterface.get_edited_scene_root()
					.find_children("*", "ScalableVectorShape2D")
					.filter(func(x : ScalableVectorShape2D): return x.has_point(pos)))
	return []


func _is_change_pivot_button_active() -> bool:
	var results = (
			EditorInterface.get_editor_viewport_2d().find_parent("*CanvasItemEditor*")
					.find_children("*Button*", "", true, false)
	)
	if results.size() >= 6:
		return results[5].button_pressed
	return false


func _get_select_mode_button() -> Button:
	if is_instance_valid(select_mode_button):
		return select_mode_button
	else:
		select_mode_button = (
			EditorInterface.get_editor_viewport_2d().find_parent("*CanvasItemEditor*")
					.find_child("*Button*", true, false)
		)
		return select_mode_button


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if not _is_change_pivot_button_active() and not _get_select_mode_button().button_pressed:
		return false

	if not is_instance_valid(EditorInterface.get_edited_scene_root()):
		return false

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos := EditorInterface.get_editor_viewport_2d().get_mouse_position()
		if _is_change_pivot_button_active():
			var current_selection := EditorInterface.get_selection().get_selected_nodes().pop_back()
			if is_instance_valid(current_selection) and current_selection is ScalableVectorShape2D:
				current_selection.set_origin(mouse_pos)
		else:
			var results := find_scalable_vector_shape_2d_nodes_at(mouse_pos)
			var refined_result := results.rfind_custom(func(x): return x.has_fine_point(mouse_pos))
			if refined_result > -1 and results[refined_result]:
				EditorInterface.edit_node(results[refined_result])
				return true
			var result = results.pop_back()
			if is_instance_valid(result):
				EditorInterface.edit_node(result)
				return true
		return false



	if event is InputEventMouseMotion:
		var mouse_pos := EditorInterface.get_editor_viewport_2d().get_mouse_position()
		for result in EditorInterface.get_edited_scene_root().find_children("*", "ScalableVectorShape2D"):
			result.remove_meta("_select_hint_")
			result.queue_redraw()

		for result in find_scalable_vector_shape_2d_nodes_at(mouse_pos):
			result.set_meta("_select_hint_", true)
			result.queue_redraw()
	return false


func _exit_tree():
	remove_inspector_plugin(plugin)
	remove_custom_type("DrawablePath2D")
	remove_custom_type("ScalableVectorShape2D")
	remove_control_from_bottom_panel(svg_importer_dock)
	svg_importer_dock.free()
