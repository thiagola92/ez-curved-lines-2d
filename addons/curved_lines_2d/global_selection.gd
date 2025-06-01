@tool
extends Node

signal key_frame_capabilities_changed(val)

var animation_player : AnimationPlayer
var animation_player_editor : Control
var animation_under_edit_button : OptionButton
var animation_postion_spinbox : SpinBox

func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		return
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	animation_player_editor = EditorInterface.get_base_control().find_child("*AnimationPlayerEditor*", true, false)
	if is_instance_valid(animation_player_editor):
		animation_under_edit_button = animation_player_editor.find_child("*OptionButton*", true, false)
		animation_postion_spinbox = animation_player_editor.find_child("*SpinBox*", true, false)
		animation_player_editor.visibility_changed.connect(key_frame_capabilities_changed.emit)
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


func batch_insert_key_frames(svs : ScalableVectorShape2D):
	if not is_instance_valid(animation_player):
		return
	if not is_instance_valid(animation_under_edit_button):
		return

	var track_position : float = 0.0
	if is_instance_valid(animation_postion_spinbox):
		track_position = animation_postion_spinbox.value

	var selected_anim_id := animation_under_edit_button.get_selected_id()
	var selected_anim_name := ""
	if selected_anim_id < 0:
		return
	else:
		selected_anim_name = GlobalSelection.animation_under_edit_button.get_item_text(selected_anim_id)

	if not animation_player.has_animation(selected_anim_name):
		printerr("Could not find animation %s in in %s" % [selected_anim_name, str(animation_player)])
		return

	var root_node := animation_player.get_node(animation_player.root_node)
	if not is_instance_valid(root_node):
		printerr("Could not find root node for %s by path: %s" % [str(animation_player), animation_player.root_node])
		return

	var path_to_node = root_node.get_path_to(svs)
	if path_to_node.is_empty():
		printerr("Could not find a path from AnimationPlayer's root node (%s) to this node (%s)" % [animation_player.root_node, str(svs)])
		return

	var animation := animation_player.get_animation(selected_anim_name)
	var undo_redo := EditorInterface.get_editor_undo_redo()
	undo_redo.create_action("Batch insert curve keyframes for %s on animation %s" % [str(svs), selected_anim_name])
	for p_idx in range(svs.curve.point_count):
		var point_position_path = NodePath("%s:curve:point_%d/position" % [path_to_node, p_idx])
		var add_result = add_anim_track_if_absent(animation, point_position_path)
		if add_result[1]:
			undo_redo.add_do_method(self, 'add_anim_track_if_absent', animation, point_position_path)
			undo_redo.add_undo_method(self, 'remove_anim_track_by_path', animation, point_position_path)

		# FIXME: do undo/redo via dedicated method on this singletonautoload
		var t_idx = add_result[0]
		var k_idx = animation.track_insert_key(t_idx, track_position, svs.curve.get_point_position(p_idx))
		undo_redo.add_do_method(animation, 'track_insert_key', t_idx, track_position, svs.curve.get_point_position(p_idx))
		undo_redo.add_undo_method(animation, 'track_remove_key', t_idx, k_idx)

	undo_redo.commit_action(false)





func add_anim_track_if_absent(animation : Animation, point_position_path : NodePath) -> Array:
	var t_idx := animation.find_track(point_position_path, Animation.TrackType.TYPE_VALUE)
	if t_idx < 0:
		t_idx = animation.add_track(Animation.TrackType.TYPE_VALUE)
		animation.track_set_path(t_idx, point_position_path)
		return [t_idx, true]
	return [t_idx, false]


func remove_anim_track_by_path(animation : Animation, point_position_path : NodePath) -> void:
	var t_idx := animation.find_track(point_position_path, Animation.TrackType.TYPE_VALUE)
	if t_idx > -1:
		animation.remove_track(t_idx)
