@tool
extends Node2D
class_name Circle2D

@export var radius := 10.0:
	set(val):
		radius = val
		queue_redraw()

@export var stroke := Color.WHITE:
	set(val):
		stroke = val
		queue_redraw()

@export var fill := Color.BLACK:
	set(val):
		fill = val
		queue_redraw()

@export var stroke_width := 1.0:
	set(val):
		stroke_width = val
		queue_redraw()

@export var antialiased := false:
	set(val):
		antialiased = val
		queue_redraw()


func _draw() -> void:
	# TODO: draw order
	if fill != Color.TRANSPARENT:
		draw_circle(Vector2.ZERO, radius, fill, true, -1.0, antialiased)
	if stroke != Color.TRANSPARENT:
		draw_circle(Vector2.ZERO, radius, stroke, false, stroke_width, antialiased)
