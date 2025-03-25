# A custom node that extends Path2D so it can be drawn as a Line2D
@tool
extends Path2D
class_name  DrawablePath2D

signal line_changed()

## The Line2D controlled by this Path2D
@export var line: Line2D:
	set(_line):
		line = _line
		line_changed.emit()


## Controls whether the path is treated as static (only update in editor) or dynamic (can be updated during runtime)
## If you set this to true, be alert for potential performance issues
@export var update_curve_at_runtime: bool = false


# Wire up signals at runtime
func _ready():
	if update_curve_at_runtime:
		if not curve.changed.is_connected(curve_changed):
			curve.changed.connect(curve_changed)


# Wire up signals on enter tree for the editor
func _enter_tree():
	if Engine.is_editor_hint():
		if not curve.changed.is_connected(curve_changed):
			curve.changed.connect(curve_changed)
		if not line_changed.is_connected(curve_changed):
			line_changed.connect(curve_changed)


# Clean up signals (ie. when closing scene) to prevent error messages in the editor
func _exit_tree():
	if curve.changed.is_connected(curve_changed):
		curve.changed.disconnect(curve_changed)



# Redraw the line based on the new curve, using its tesselate method
func curve_changed():
	if is_instance_valid(line):
		line.points = curve.tessellate()
