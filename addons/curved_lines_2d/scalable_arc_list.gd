class_name ScalableArcList
extends Resource

@export var arcs : Array[ScalableArc] = []:
	set(_arcs):
		arcs = _arcs
		for i in arcs.size():
			if arcs[i] == null:
				arcs[i] = ScalableArc.new()
		emit_changed()


func _init(a : Array[ScalableArc] = []) -> void:
	arcs = a
	if not changed.is_connected(_on_changed):
		changed.connect(_on_changed)
	_on_changed()


func _on_changed():
	for a : ScalableArc in arcs:
		if a and not a.changed.is_connected(_item_changed):
			a.changed.connect(_item_changed)


func _item_changed():
	emit_changed()


func remove_arc_for_point(p_idx : int) -> void:
	arcs = arcs.filter(func(a): return a.start_point != p_idx)
	emit_changed()


func add_arc(arc : ScalableArc) -> void:
	arcs.append(arc)
	_on_changed()
	emit_changed()


func get_arc_for_point(p_idx : int) -> ScalableArc:
	var idx = arcs.find_custom(func(a : ScalableArc): return a.start_point == p_idx)
	if idx > -1:
		return arcs[idx]
	else:
		return null


func handle_point_added_at_index(new_idx) -> void:
	for a : ScalableArc in arcs:
		if a.start_point >= new_idx:
			a.start_point += 1


func handle_point_removed_at_index(removed_idx) -> void:
	for a : ScalableArc in arcs:
		if a.start_point >= removed_idx:
			a.start_point -= 1
