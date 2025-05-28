@tool
extends Control

class_name AssignFillInspectorForm

var scalable_vector_shape_2d : ScalableVectorShape2D
var create_button : Button
var select_button : Button
var title_button : Button
var collapse_icon : Texture2D
var expand_icon : Texture2D
var collapsible_siblings : Array[Node]
var color_button : ColorPickerButton

func _enter_tree() -> void:
	if not is_instance_valid(scalable_vector_shape_2d):
		return
	collapse_icon = preload("res://addons/curved_lines_2d/Collapse.svg")
	expand_icon = preload("res://addons/curved_lines_2d/Expand.svg")
	create_button = find_child("CreateFillButton")
	select_button = find_child("GotoPolygon2DButton")
	title_button = find_child("TitleButton")
	color_button = find_child("ColorPickerButton")
	scalable_vector_shape_2d.assigned_node_changed.connect(_on_svs_assignment_changed)
	collapsible_siblings = get_children().filter(func(x): return x != title_button and not x is Label)
	_on_svs_assignment_changed()


func _on_svs_assignment_changed() -> void:
	if is_instance_valid(scalable_vector_shape_2d.polygon):
		create_button.get_parent().hide()
		select_button.get_parent().show()
		create_button.disabled = true
		select_button.disabled = false
		color_button.color = scalable_vector_shape_2d.polygon.color
	else:
		create_button.get_parent().show()
		select_button.get_parent().hide()
		create_button.disabled = false
		select_button.disabled = true
		color_button.color = CurvedLines2D._get_default_fill_color()


func _on_color_picker_button_color_changed(color: Color) -> void:
	if not is_instance_valid(scalable_vector_shape_2d.polygon):
		return
	var undo_redo = EditorInterface.get_editor_undo_redo()
	undo_redo.create_action("Adjust Polygon2D color for %s" % str(scalable_vector_shape_2d))
	undo_redo.add_do_property(scalable_vector_shape_2d.polygon, 'color', color)
	undo_redo.add_undo_property(scalable_vector_shape_2d.polygon, 'color', scalable_vector_shape_2d.polygon.color)
	undo_redo.commit_action()


func _on_goto_polygon_2d_button_pressed() -> void:
	if not is_instance_valid(scalable_vector_shape_2d):
		return
	if not is_instance_valid(scalable_vector_shape_2d.polygon):
		return
	EditorInterface.call_deferred('edit_node', scalable_vector_shape_2d.polygon)


func _on_create_fill_button_pressed():
	if not is_instance_valid(scalable_vector_shape_2d):
		return
	if is_instance_valid(scalable_vector_shape_2d.polygon):
		return

	var polygon_2d := Polygon2D.new()
	var root := EditorInterface.get_edited_scene_root()
	var undo_redo = EditorInterface.get_editor_undo_redo()
	polygon_2d.color = color_button.color
	undo_redo.create_action("Add Polygon2D to %s " % str(scalable_vector_shape_2d))
	undo_redo.add_do_method(scalable_vector_shape_2d, 'add_child', polygon_2d, true)
	undo_redo.add_do_method(polygon_2d, 'set_owner', root)
	undo_redo.add_do_reference(polygon_2d)
	undo_redo.add_do_property(scalable_vector_shape_2d, 'polygon', polygon_2d)
	undo_redo.add_undo_method(scalable_vector_shape_2d, 'remove_child', polygon_2d)
	undo_redo.add_undo_property(scalable_vector_shape_2d, 'polygon', null)
	undo_redo.commit_action()


func _on_title_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		title_button.icon = collapse_icon
		for n in collapsible_siblings:
			n.show()
	else:
		title_button.icon = expand_icon
		for n in collapsible_siblings:
			n.hide()
