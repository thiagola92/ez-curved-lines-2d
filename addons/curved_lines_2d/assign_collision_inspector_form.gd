@tool
extends Control

class_name AssignCollisionInspectorForm

var scalable_vector_shape_2d : ScalableVectorShape2D

func _enter_tree() -> void:
	if not is_instance_valid(scalable_vector_shape_2d):
		return
	if 'assigned_node_changed' in scalable_vector_shape_2d:
		scalable_vector_shape_2d.assigned_node_changed.connect(_on_svs_assignment_changed)
	_on_svs_assignment_changed()


func _on_svs_assignment_changed() -> void:
	if is_instance_valid(scalable_vector_shape_2d.collision_polygon):
		%GotoCollisionButton.get_parent().show()
		%GotoCollisionButton.disabled = false
	else:
		hide()


func _on_goto_collision_button_pressed() -> void:
	if not is_instance_valid(scalable_vector_shape_2d):
		return
	if not is_instance_valid(scalable_vector_shape_2d.collision_polygon):
		return
	EditorInterface.call_deferred('edit_node', scalable_vector_shape_2d.collision_polygon)
