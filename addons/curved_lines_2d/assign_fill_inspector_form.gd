@tool
extends Control

class_name AssignFillInspectorForm

var scalable_vector_shape_2d : ScalableVectorShape2D
var create_button : Button
var select_button : Button
var title_button : Button
var collapse_icon : Texture2D
var expand_icon : Texture2D
var collapsible_siblings : Array[Node]
var color_button : ColorPickerButton

var remove_gradient_toggle_button : Button
var linear_gradient_toggle_button : Button
var radial_gradient_toggle_button : Button


func _enter_tree() -> void:
	if not is_instance_valid(scalable_vector_shape_2d):
		return
	collapse_icon = preload("res://addons/curved_lines_2d/Collapse.svg")
	expand_icon = preload("res://addons/curved_lines_2d/Expand.svg")
	create_button = find_child("CreateFillButton")
	select_button = find_child("GotoPolygon2DButton")
	title_button = find_child("TitleButton")
	color_button = find_child("ColorPickerButton")
	remove_gradient_toggle_button = find_child("RemoveGradientToggleButton")
	linear_gradient_toggle_button = find_child("LinearGradientToggleButton")
	radial_gradient_toggle_button = find_child("RadialGradientToggleButton")
	scalable_vector_shape_2d.assigned_node_changed.connect(_on_svs_assignment_changed)
	collapsible_siblings = get_children().filter(func(x): return x != title_button and not x is Label)
	_on_svs_assignment_changed()


func _on_svs_assignment_changed() -> void:
	if is_instance_valid(scalable_vector_shape_2d.polygon):
		create_button.get_parent().hide()
		select_button.get_parent().show()
		create_button.disabled = true
		select_button.disabled = false
		color_button.color = scalable_vector_shape_2d.polygon.color
		radial_gradient_toggle_button.disabled = false
		linear_gradient_toggle_button.disabled = false
		remove_gradient_toggle_button.disabled = false
		if scalable_vector_shape_2d.polygon.texture is GradientTexture2D:
			if scalable_vector_shape_2d.polygon.texture.fill == GradientTexture2D.FILL_RADIAL:
				radial_gradient_toggle_button.button_pressed = true
			else:
				linear_gradient_toggle_button.button_pressed = true
		elif scalable_vector_shape_2d.polygon.texture:
			print("TODO: determine what to do when a non-gradient texture is toggled")
		else:
			remove_gradient_toggle_button.button_pressed = true
	else:
		create_button.get_parent().show()
		select_button.get_parent().hide()
		create_button.disabled = false
		select_button.disabled = true
		color_button.color = CurvedLines2D._get_default_fill_color()
		radial_gradient_toggle_button.disabled = true
		linear_gradient_toggle_button.disabled = true
		remove_gradient_toggle_button.disabled = true
		remove_gradient_toggle_button.button_pressed = true


func _on_color_picker_button_color_changed(color: Color) -> void:
	if not is_instance_valid(scalable_vector_shape_2d.polygon):
		return
	var undo_redo = EditorInterface.get_editor_undo_redo()
	undo_redo.create_action("Adjust Polygon2D color for %s" % str(scalable_vector_shape_2d))
	undo_redo.add_do_property(scalable_vector_shape_2d.polygon, 'color', color)
	undo_redo.add_undo_property(scalable_vector_shape_2d.polygon, 'color', scalable_vector_shape_2d.polygon.color)
	undo_redo.commit_action()


func _on_goto_polygon_2d_button_pressed() -> void:
	if not is_instance_valid(scalable_vector_shape_2d):
		return
	if not is_instance_valid(scalable_vector_shape_2d.polygon):
		return
	EditorInterface.call_deferred('edit_node', scalable_vector_shape_2d.polygon)


func _on_create_fill_button_pressed():
	if not is_instance_valid(scalable_vector_shape_2d):
		return
	if is_instance_valid(scalable_vector_shape_2d.polygon):
		return

	var polygon_2d := Polygon2D.new()
	var root := EditorInterface.get_edited_scene_root()
	var undo_redo = EditorInterface.get_editor_undo_redo()
	polygon_2d.color = color_button.color
	undo_redo.create_action("Add Polygon2D to %s " % str(scalable_vector_shape_2d))
	undo_redo.add_do_method(scalable_vector_shape_2d, 'add_child', polygon_2d, true)
	undo_redo.add_do_method(polygon_2d, 'set_owner', root)
	undo_redo.add_do_reference(polygon_2d)
	undo_redo.add_do_property(scalable_vector_shape_2d, 'polygon', polygon_2d)
	undo_redo.add_undo_method(scalable_vector_shape_2d, 'remove_child', polygon_2d)
	undo_redo.add_undo_property(scalable_vector_shape_2d, 'polygon', null)
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


func _on_remove_gradient_toggle_button_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		return
	if not is_instance_valid(scalable_vector_shape_2d):
		return
	if not is_instance_valid(scalable_vector_shape_2d.polygon):
		return

	# TODO use Undo/Redo here
	scalable_vector_shape_2d.polygon.texture = null


func _on_linear_gradient_toggle_button_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		return
	if not is_instance_valid(scalable_vector_shape_2d):
		return
	if not is_instance_valid(scalable_vector_shape_2d.polygon):
		return
	if (scalable_vector_shape_2d.polygon.texture is GradientTexture2D and
				scalable_vector_shape_2d.polygon.texture.fill == GradientTexture2D.FILL_LINEAR):
		return

	# TODO use Undo/Redo here & extract func
	var texture := GradientTexture2D.new()
	var box := scalable_vector_shape_2d.get_bounding_rect()
	texture.width = ceil(box.size.x)
	texture.height = ceil(box.size.y)
	texture.gradient = Gradient.new()
	scalable_vector_shape_2d.polygon.texture = texture
	scalable_vector_shape_2d.polygon.texture_offset = -box.position


func _on_radial_gradient_toggle_button_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		return
	if not is_instance_valid(scalable_vector_shape_2d):
		return
	if not is_instance_valid(scalable_vector_shape_2d.polygon):
		return
	if (scalable_vector_shape_2d.polygon.texture is GradientTexture2D and
				scalable_vector_shape_2d.polygon.texture.fill == GradientTexture2D.FILL_RADIAL):
		return

	# TODO use Undo/Redo here & extract func
	var texture := GradientTexture2D.new()
	var box := scalable_vector_shape_2d.get_bounding_rect()
	texture.width = ceil(box.size.x)
	texture.height = ceil(box.size.y)
	texture.gradient = Gradient.new()
	texture.fill = GradientTexture2D.FILL_RADIAL
	# TODO texture.fill_from = box.position / box.size align with box center
	scalable_vector_shape_2d.polygon.texture = texture
	scalable_vector_shape_2d.polygon.texture_offset = -box.position
