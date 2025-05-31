@tool
extends Node

signal key_frame_capabilities_changed(val)

var animation_player : AnimationPlayer
var animation_player_editor : Control
var animation_under_edit_button : OptionButton

func _enter_tree() -> void:
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	animation_player_editor = EditorInterface.get_base_control().find_child("*AnimationPlayerEditor*", true, false)
	if is_instance_valid(animation_player_editor):
		animation_player_editor.visibility_changed.connect(key_frame_capabilities_changed.emit)
		animation_under_edit_button = animation_player_editor.find_child("*OptionButton*", true, false)
		if is_instance_valid(animation_under_edit_button):
			animation_under_edit_button.item_selected.connect(func(_sid): key_frame_capabilities_changed.emit())


func _on_selection_changed():
	var candidate = EditorInterface.get_selection().get_selected_nodes().pop_back()
	if candidate is AnimationPlayer and is_instance_valid(candidate):
		animation_player = candidate
		key_frame_capabilities_changed.emit()
		(animation_player as Node).tree_exiting.connect(
				func(): key_frame_capabilities_changed.emit())

	if not is_instance_valid(animation_player):
		key_frame_capabilities_changed.emit()


func mock_insert_key_frames(svs : ScalableVectorShape2D):
	if not is_instance_valid(animation_player):
		return
	if not is_instance_valid(animation_under_edit_button):
		return

	var selected_anim_id := animation_under_edit_button.get_selected_id()
	var selected_anim_name := ""
	if selected_anim_id < 0:
		return
	else:
		selected_anim_name = GlobalSelection.animation_under_edit_button.get_item_text(selected_anim_id)

	print(selected_anim_name, " will receive keys from:  ", svs)
