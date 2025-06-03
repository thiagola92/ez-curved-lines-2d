@tool
extends ScalableVectorShape2D

class_name ScalableRect2D

signal dimensions_changed()

const R_TO_CP = 0.5523

@export var offset : Vector2 = Vector2(0.0, 0.0):
	set(ofs):
		offset = ofs
		dimensions_changed.emit()

@export var size : Vector2 = Vector2(100.0, 100.0):
	set(sz):
		if sz.x < rx * 2:
			sz.x = rx * 2
		if sz.x < 0:
			sz.x = 0.001
		if sz.y < ry * 2:
			sz.y = ry * 2
		if sz.y < 0:
			sz.y = 0.001
		size = sz
		dimensions_changed.emit()

@export var rx : float = 0.0:
	set(_rx):
		rx = _rx if _rx > 0 else 0
		dimensions_changed.emit()

@export var ry : float = 0.0:
	set(_ry):
		ry = _ry if _ry > 0 else 0
		dimensions_changed.emit()


func _enter_tree() -> void:
	super._enter_tree()
	if not dimensions_changed.is_connected(_on_dimensions_changed):
		dimensions_changed.connect(_on_dimensions_changed)
	_on_dimensions_changed()


func _on_dimensions_changed():
	curve.clear_points()
	var width = size.x
	var height = size.y
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
	var point_pos := size + get_bounding_rect().position
	var rx_handle := Vector2(rx, 0)
	var ry_handle := Vector2(0, ry)
	return [{
		"point_position": to_global(point_pos),
		"mirrored": true,
		"in": Vector2.ZERO,
		"out": Vector2.ZERO,
		"in_position": to_global(offset),
		"out_position": to_global(offset),
		"is_closed": ""
	}, {
		"point_position": to_global(offset),
		"mirrored": false,
		"in": rx_handle,
		"out": ry_handle,
		"in_position": to_global(offset + rx_handle),
		"out_position": to_global(offset + ry_handle),
		"is_closed": ""
	}]
