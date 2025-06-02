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
	if BatchKeyFrameAdder.is_capable():
		batch_insert_button.disabled = false
	else:
		batch_insert_button.disabled = true


func _on_batch_insert_button_pressed() -> void:
	BatchKeyFrameAdder.batch_insert_key_frames(scalable_vector_shape_2d)
