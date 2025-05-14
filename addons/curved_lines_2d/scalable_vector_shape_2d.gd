## A custom node that uses a Curve2D to control shapes like Line2D, Polygon2D with
## Original adapted code: https://www.hedberggames.com/blog/rendering-curves-in-godot
@tool
extends Node2D
class_name ScalableVectorShape2D

## Emitted when a new set of points was calculated for a connected Line2D, Polygon2D, or CollisionPolygon2D
signal path_changed(new_points : PackedVector2Array)

## This signal is used internally in editor-mode to tell the DrawablePath2D tool that
## the instance of assigned Line2D, Polygon2D, or CollisionPolygon2D has changed
signal assigned_node_changed()

## The Curve2D that dynamically triggers updates of the shapes assigned to this node
## Changes to this curve will also emit the path_changed signal with the updated points array
@export var curve: Curve2D = Curve2D.new()

## The Polygon2D controlled by this node's curve property
@export var polygon: Polygon2D:
	set(_poly):
		polygon = _poly
		assigned_node_changed.emit()

## The Line2D controlled by this node's curve property
@export var line: Line2D:
	set(_line):
		line = _line
		assigned_node_changed.emit()

## The CollisionPolygon2D controlled by this node's curve property
@export var collision_polygon: CollisionPolygon2D:
	set(_poly):
		collision_polygon = _poly
		assigned_node_changed.emit()

## Controls whether the path is treated as static (only update in editor) or dynamic (can be updated during runtime)
## If you set this to true, be alert for potential performance issues
@export var update_curve_at_runtime: bool = false

## Controls the paramaters used to divide up the line  in segments.
## These settings are prefilled with the default values.
@export_group("Tesselation settings")
## Controls how many subdivisions a curve segment may face before it is considered approximate enough. 
## Each subdivision splits the segment in half, so the default 5 stages may mean up to 32 subdivisions 
## per curve segment. Increase with care!
@export_range(1, 10) var max_stages : int = 5:
	set(_max_stages):
		max_stages = _max_stages
		assigned_node_changed.emit()
## Controls how many degrees the midpoint of a segment may deviate from the real curve, before the 
## segment has to be subdivided.
@export_range(0.0, 180.0) var tolerance_degrees := 4.0:
	set(_tolerance_degrees):
		tolerance_degrees = _tolerance_degrees
		assigned_node_changed.emit()

@export_group("Editor settings")
@export var shape_hint_color := Color.LIME_GREEN
@export var lock_assigned_shapes := true

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
		if not assigned_node_changed.is_connected(_on_assigned_node_changed):
			assigned_node_changed.connect(_on_assigned_node_changed)
	# handles update when reparenting
	if update_curve_at_runtime:
		if not curve.changed.is_connected(curve_changed):
			curve.changed.connect(curve_changed)


# Clean up signals (ie. when closing scene) to prevent error messages in the editor
func _exit_tree():
	if curve.changed.is_connected(curve_changed):
		curve.changed.disconnect(curve_changed)


func _on_assigned_node_changed():
	if is_instance_valid(line):
		if lock_assigned_shapes:
			line.set_meta("_edit_lock_", true)
			line.show_behind_parent = true
		curve_changed()
	if is_instance_valid(polygon):
		if lock_assigned_shapes:
			polygon.set_meta("_edit_lock_", true)
			polygon.show_behind_parent = true
		curve_changed()
	if is_instance_valid(collision_polygon):
		if lock_assigned_shapes:
			collision_polygon.set_meta("_edit_lock_", true)
			collision_polygon.show_behind_parent = true
		curve_changed()


## Redraw the line based on the new curve, using its tesselate method
func curve_changed():
	if (not is_instance_valid(line) and not is_instance_valid(polygon)
			and not is_instance_valid(collision_polygon) 
			and not path_changed.has_connections()):
		# guard against needlessly invoking expensive tesselate operation
		return

	var new_points := curve.tessellate(max_stages, tolerance_degrees)
	# Fixes cases start- and end-node are so close to each other that
	# polygons won't fill and closed lines won't cap nicely
	if new_points[0].distance_to(new_points[new_points.size()-1]) < 0.001:
		new_points.remove_at(new_points.size() - 1)
	if is_instance_valid(line):
		line.points = new_points
	if is_instance_valid(polygon):
		polygon.polygon = new_points
	if is_instance_valid(collision_polygon):
		collision_polygon.polygon = new_points
	path_changed.emit(new_points)
	# FIXME: replace with listener to signal in plugin
	#if Engine.is_editor_hint():
		#queue_redraw()


## Calculate and return the bounding rect in local space
func get_bounding_rect() -> Rect2:
	var points := curve.tessellate(max_stages, tolerance_degrees)
	if points.size() < 1:
		# Cannot calculate a center for 0 points 
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	var minx := INF
	var miny := INF
	var maxx := -INF
	var maxy := -INF
	for p : Vector2 in points:
		minx = p.x if p.x < minx else minx
		miny = p.y if p.y < miny else miny
		maxx = p.x if p.x > maxx else maxx
		maxy = p.y if p.y > maxy else maxy
	return Rect2(minx, miny, maxx - minx, maxy - miny)



func has_point(global_pos : Vector2) -> bool:
	return get_bounding_rect().grow(
		line.width / 2.0 if is_instance_valid(line) else 0
	).has_point(to_local(global_pos))


func has_fine_point(global_pos : Vector2) -> bool:
	if is_instance_valid(polygon) or is_instance_valid(collision_polygon):
		var poly_points := curve.tessellate(max_stages, tolerance_degrees)
		return Geometry2D.is_point_in_polygon(to_local(global_pos), poly_points)
	return false


func set_position_to_center() -> void:
	var c = get_bounding_rect().get_center()
	position += c
	for i in range(curve.get_point_count()):
		curve.set_point_position(i, curve.get_point_position(i) - c)


func set_origin(global_pos : Vector2) -> void:
	var local_pos = to_local(global_pos)
	for i in range(curve.get_point_count()):
		curve.set_point_position(i, curve.get_point_position(i) - local_pos)
	global_position = global_pos
	if is_instance_valid(polygon) and polygon.texture is GradientTexture2D:
		polygon.texture_offset = -get_bounding_rect().position



func get_bounding_box() -> Array[Vector2]:
	var rect = get_bounding_rect().grow(
		line.width / 2.0 if is_instance_valid(line) else 0
	)
	return [
		to_global(rect.position),
		to_global(Vector2(rect.position.x + rect.size.x, rect.position.y)),
		to_global(rect.position + rect.size),
		to_global(Vector2(rect.position.x, rect.position.y  + rect.size.y)),
		to_global(rect.position)
	]


func get_poly_points() -> Array:
	return Array(curve.tessellate(max_stages, tolerance_degrees)).map(to_global)
