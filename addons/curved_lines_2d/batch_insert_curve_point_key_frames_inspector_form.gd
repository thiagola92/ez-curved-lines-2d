@tool
extends Control

var batch_insert_button : Button
var scalable_vector_shape_2d : ScalableVectorShape2D

func _enter_tree() -> void:
	GlobalSelection.key_frame_capabilities_changed.connect(
		_on_key_frame_capabilities_changed)
	batch_insert_button = find_child("BatchInsertButton")
	_on_key_frame_capabilities_changed()


func _on_key_frame_capabilities_changed() -> void:
	batch_insert_button.disabled = true
	print("--- determining whether to enable button ---")

	if not is_instance_valid(GlobalSelection.animation_player_editor):
		return
	if not is_instance_valid(GlobalSelection.animation_under_edit_button):
		return

	var selected_anim_id := GlobalSelection.animation_under_edit_button.get_selected_id()
	var selected_anim_name := ""
	if selected_anim_id < 0:
		print("no animation currently selected")
		return
	else:
		selected_anim_name = GlobalSelection.animation_under_edit_button.get_item_text(selected_anim_id)
		print("selected animation: ", selected_anim_name)

	if is_instance_valid(GlobalSelection.animation_player):
		print("found valid animation player ", GlobalSelection.animation_player)
		print("animation name '%s' is %s in this animation player" % [
			selected_anim_name,
				"present" if GlobalSelection.animation_player.has_animation(selected_anim_name) else
				"not present"
		])
	else:
		print("no valid animation player found")
		return

	if not GlobalSelection.animation_player_editor.visible:
		print("animation player editor is not currently visible")
		return
	batch_insert_button.disabled = false
	print("yes, you may be enabled\n")


func _on_batch_insert_button_pressed() -> void:
	GlobalSelection.mock_insert_key_frames(scalable_vector_shape_2d)
