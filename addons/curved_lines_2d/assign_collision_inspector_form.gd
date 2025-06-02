@tool
extends Control

class_name AssignCollisionInspectorForm

var scalable_vector_shape_2d : ScalableVectorShape2D
var create_button : Button
var select_button : Button
var title_button : Button
var collapse_icon : Texture2D
var expand_icon : Texture2D
var collapsible_siblings : Array[Node]

func _enter_tree() -> void:
	if not is_instance_valid(scalable_vector_shape_2d):
		return
	collapse_icon = preload("res://addons/curved_lines_2d/Collapse.svg")
	expand_icon = preload("res://addons/curved_lines_2d/Expand.svg")
	create_button = find_child("CreateCollisionButton")
	select_button = find_child("GotoCollisionButton")
	title_button = find_child("TitleButton")
	if 'assigned_node_changed' in scalable_vector_shape_2d:
		scalable_vector_shape_2d.assigned_node_changed.connect(_on_svs_assignment_changed)
	collapsible_siblings = get_children().filter(func(x): return x != title_button and not x is Label)
	_on_svs_assignment_changed()


func _on_svs_assignment_changed() -> void:
	if is_instance_valid(scalable_vector_shape_2d.collision_polygon):
		create_button.get_parent().hide()
		select_button.get_parent().show()
		create_button.disabled = true
		select_button.disabled = false
	else:
		create_button.get_parent().show()
		select_button.get_parent().hide()
		create_button.disabled = false
		select_button.disabled = true


func _on_goto_collision_button_pressed() -> void:
	if not is_instance_valid(scalable_vector_shape_2d):
		return
	if not is_instance_valid(scalable_vector_shape_2d.collision_polygon):
		return
	EditorInterface.call_deferred('edit_node', scalable_vector_shape_2d.collision_polygon)


func _on_create_collision_button_pressed():
	if not is_instance_valid(scalable_vector_shape_2d):
		return
	if is_instance_valid(scalable_vector_shape_2d.collision_polygon):
		return

	var collision_polygon_2d := CollisionPolygon2D.new()
	var root := EditorInterface.get_edited_scene_root()
	var undo_redo = EditorInterface.get_editor_undo_redo()
	undo_redo.create_action("Add CollisionPolygon2D to %s " % str(scalable_vector_shape_2d))
	undo_redo.add_do_method(scalable_vector_shape_2d, 'add_child', collision_polygon_2d, true)
	undo_redo.add_do_method(collision_polygon_2d, 'set_owner', root)
	undo_redo.add_do_reference(collision_polygon_2d)
	undo_redo.add_do_property(scalable_vector_shape_2d, 'collision_polygon', collision_polygon_2d)
	undo_redo.add_undo_method(scalable_vector_shape_2d, 'remove_child', collision_polygon_2d)
	undo_redo.add_undo_property(scalable_vector_shape_2d, 'collision_polygon', null)
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

