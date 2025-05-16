@tool
extends VBoxContainer

class_name ScalableVectorShapeEditTab

signal toggle_editing(flg : bool)
signal toggle_hints(flg : bool)

func _on_enable_editing_checkbox_toggled(toggled_on: bool) -> void:
	toggle_editing.emit(toggled_on)


func _on_enable_hints_checkbox_toggled(toggled_on: bool) -> void:
	toggle_hints.emit(toggled_on)
