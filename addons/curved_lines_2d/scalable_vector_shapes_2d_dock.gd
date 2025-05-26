@tool
extends TabContainer

signal toggle_gui_editing(toggled_on : bool)
signal toggle_gui_hints(toggled_on : bool)

signal shape_created(curve : Curve2D, scene_root : Node2D, node_name : String,
			stroke_width : int, stroke_color : Color, fill_color : Color)


const IMPORT_TAB_NAME :=  "Import SVG File"
const EDIT_TAB_NAME := "Scalable Vector Shapes"

var warning_dialog : AcceptDialog
var edit_tab : ScalableVectorShapeEditTab

func _enter_tree() -> void:
	warning_dialog = AcceptDialog.new()
	EditorInterface.get_base_control().add_child(warning_dialog)
	find_child(IMPORT_TAB_NAME).warning_dialog = warning_dialog
	edit_tab = find_child(EDIT_TAB_NAME)
	edit_tab.warning_dialog = warning_dialog
	if not edit_tab.shape_created.is_connected(shape_created.emit):
		edit_tab.shape_created.connect(shape_created.emit)


func _on_enable_editing_checkbox_toggled(toggled_on: bool) -> void:
	toggle_gui_editing.emit(toggled_on)


func _on_enable_hints_checkbox_toggled(toggled_on: bool) -> void:
	toggle_gui_hints.emit(toggled_on)
