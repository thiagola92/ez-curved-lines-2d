class_name ScalableArc
extends Resource

@export var start_point : int = 0:
	set(sp):
		start_point = sp
		emit_changed()


@export var radius : Vector2 = Vector2.ZERO:
	set(r):
		radius = r
		emit_changed()


@export var rotation_deg : float = 0.0:
	set(r):
		rotation_deg = r
		emit_changed()


@export var sweep_flag : bool = true:
	set(f):
		sweep_flag = f
		emit_changed()


@export var large_arc_flag : bool = false:
	set(f):
		large_arc_flag = f
		emit_changed()


func _init() -> void:
	start_point = 0
	radius = Vector2.ZERO
	rotation_deg = 0.0
	sweep_flag = true
	large_arc_flag = false
