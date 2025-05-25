@tool
extends Control

var scalable_vector_shape_2d : ScalableVectorShape2D
var create_button : Button
var remove_button : Button

func _enter_tree() -> void:
	if not is_instance_valid(scalable_vector_shape_2d):
		return

	create_button = find_child("CreateStrokeButton")
	remove_button = find_child("RemoveStrokeButton")
	scalable_vector_shape_2d.assigned_node_changed.connect(_on_svs_assignment_changed)
	_on_svs_assignment_changed()


func _on_svs_assignment_changed() -> void:
	if is_instance_valid(scalable_vector_shape_2d.line):
		create_button.disabled = true
		remove_button.disabled = false
	else:
		create_button.disabled = false
		remove_button.disabled = true


func _on_create_stroke_button_pressed():
	if not is_instance_valid(scalable_vector_shape_2d):
		return
	if is_instance_valid(scalable_vector_shape_2d.line):
		return

	var line_2d := Line2D.new()
	var root := EditorInterface.get_edited_scene_root()
	var undo_redo = EditorInterface.get_editor_undo_redo()
	undo_redo.create_action("Add Line2D to %s " % str(scalable_vector_shape_2d))
	undo_redo.add_do_method(scalable_vector_shape_2d, 'add_child', line_2d, true)
	undo_redo.add_do_method(line_2d, 'set_owner', root)
	undo_redo.add_do_reference(line_2d)
	undo_redo.add_do_property(scalable_vector_shape_2d, 'line', line_2d)
	undo_redo.add_undo_method(scalable_vector_shape_2d, 'remove_child', line_2d)
	undo_redo.add_undo_property(scalable_vector_shape_2d, 'line', null)
	undo_redo.commit_action()
