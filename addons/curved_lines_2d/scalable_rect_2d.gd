@tool
extends ScalableVectorShape2D

class_name ScalableRect2D

signal dimensions_changed()

const R_TO_CP = 0.5523

@export_range(1.0, 10_000.0) var width : float:
	set(w):
		width = w
		dimensions_changed.emit()

@export_range(1.0, 10_000.0) var height : float:
	set(h):
		height = h
		dimensions_changed.emit()

@export_range(0.0, 5_000.0) var rx : float:
	set(_rx):
		rx = _rx
		dimensions_changed.emit()

@export_range(0.0, 5_000.0) var ry : float:
	set(_ry):
		ry = _ry
		dimensions_changed.emit()


func _enter_tree() -> void:
	super._enter_tree()
	if not dimensions_changed.is_connected(_on_dimensions_changed):
		dimensions_changed.connect(_on_dimensions_changed)
	_on_dimensions_changed()


func _on_dimensions_changed():
	curve.clear_points()
	if rx == 0 and ry == 0:
		curve.add_point(Vector2.ZERO)
		curve.add_point(Vector2(width, 0))
		curve.add_point(Vector2(width, height))
		curve.add_point(Vector2(0, height))
		curve.add_point(Vector2.ZERO)
	else:
		curve.add_point(Vector2(width - rx, 0), Vector2.ZERO, Vector2(rx * R_TO_CP, 0))
		curve.add_point(Vector2(width, ry), Vector2(0, -ry * R_TO_CP))
		curve.add_point(Vector2(width, height - ry), Vector2.ZERO, Vector2(0, ry * R_TO_CP))
		curve.add_point(Vector2(width - rx, height), Vector2(rx * R_TO_CP, 0))
		curve.add_point(Vector2(rx, height), Vector2.ZERO, Vector2(-rx * R_TO_CP, 0))
		curve.add_point(Vector2(0, height - ry), Vector2(0, ry * R_TO_CP))
		curve.add_point(Vector2(0, ry), Vector2.ZERO, Vector2(0, -ry *  R_TO_CP))
		curve.add_point(Vector2(rx, 0), Vector2(-rx * R_TO_CP, 0))
		curve.add_point(Vector2(width - rx, 0), Vector2.ZERO, Vector2(rx * R_TO_CP, 0))
	path_changed.emit()


func get_curve_handles() -> Array:
	var point_pos := Vector2(width, height) + get_bounding_rect().position
	var rx_handle := -Vector2(rx, 0)
	var ry_handle := -Vector2(0, ry)
	return [{
		"is_rect": true,
		"point_position": to_global(point_pos),
		"mirrored": true,
		"in": rx_handle,
		"out": ry_handle,
		"in_position": to_global(point_pos + rx_handle),
		"out_position": to_global(point_pos + ry_handle),
		"is_closed": ""
	}]
