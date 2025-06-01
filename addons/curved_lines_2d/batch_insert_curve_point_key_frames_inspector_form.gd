@tool
extends Control

var batch_insert_button : Button
var scalable_vector_shape_2d : ScalableVectorShape2D

func _enter_tree() -> void:
	if not BatchKeyFrameAdder.key_frame_capabilities_changed.is_connected(
			_on_key_frame_capabilities_changed
	):
		BatchKeyFrameAdder.key_frame_capabilities_changed.connect(
			_on_key_frame_capabilities_changed)
	batch_insert_button = find_child("BatchInsertButton")
	_on_key_frame_capabilities_changed()


func _on_key_frame_capabilities_changed() -> void:
	batch_insert_button.disabled = true
	if not is_instance_valid(BatchKeyFrameAdder.animation_player_editor):
		return
	if not is_instance_valid(BatchKeyFrameAdder.animation_under_edit_button):
		return
	if BatchKeyFrameAdder.animation_under_edit_button.get_selected_id() < 0:
		return
	if not is_instance_valid(BatchKeyFrameAdder.animation_player):
		return
	if not BatchKeyFrameAdder.animation_player_editor.visible:
		return
	batch_insert_button.disabled = false


func _on_batch_insert_button_pressed() -> void:
	BatchKeyFrameAdder.batch_insert_key_frames(scalable_vector_shape_2d)
