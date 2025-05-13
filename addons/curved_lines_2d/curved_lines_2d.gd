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
	svg_importer_dock.undo_redo = get_undo_redo()
	add_control_to_bottom_panel(svg_importer_dock as Control, "EZ SVG Importer")


func _handles(object: Object) -> bool:
	return object is Node2D


func find_drawable_path_2d_nodes_at(pos : Vector2) -> Array[Node]:
	return (EditorInterface.get_edited_scene_root()
				.find_children("*", "DrawablePath2D")
				.filter(func(x : DrawablePath2D): return x.has_point(pos)))


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
	if not _get_select_mode_button().button_pressed:
		return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos := EditorInterface.get_editor_viewport_2d().get_mouse_position()
		var result := find_drawable_path_2d_nodes_at(mouse_pos).pop_back()
		if is_instance_valid(result):
			EditorInterface.edit_node(result)
			return true


	if event is InputEventMouseMotion:
		var mouse_pos := EditorInterface.get_editor_viewport_2d().get_mouse_position()
		for result in EditorInterface.get_edited_scene_root().find_children("*", "DrawablePath2D"):
			result.remove_meta("_select_hint_")
			result.queue_redraw()

		var result := find_drawable_path_2d_nodes_at(mouse_pos).pop_back()
		if is_instance_valid(result):
			result.set_meta("_select_hint_", true)
			result.queue_redraw()
	return false


func _exit_tree():
	remove_inspector_plugin(plugin)
	remove_custom_type("DrawablePath2D")
	remove_control_from_bottom_panel(svg_importer_dock)
	svg_importer_dock.free()
