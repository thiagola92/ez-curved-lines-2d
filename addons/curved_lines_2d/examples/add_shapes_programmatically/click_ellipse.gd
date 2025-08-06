extends Node2D

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		add_ellipse(event.position)


func add_ellipse(at_pos: Vector2):
	var ellipse = ScalableVectorShape2D.new()
	# make sure it will rerender in game
	ellipse.update_curve_at_runtime = true
	ellipse.shape_type = ScalableVectorShape2D.ShapeType.ELLIPSE
	ellipse.position = at_pos
	ellipse.size = Vector2(80, 40)
	ellipse.rx = 40
	ellipse.ry = 20
	# assign a Line2D as stroke
	ellipse.line = Line2D.new()
	ellipse.line.default_color = Color.BLACK
	ellipse.add_child(ellipse.line)
	# assign a Polygon2D as fill
	ellipse.polygon = Polygon2D.new()
	ellipse.polygon.color = Color.WHITE
	ellipse.add_child(ellipse.polygon)

	ellipse.collision_object = StaticBody2D.new()
	ellipse.add_child(ellipse.collision_object)

	add_child(ellipse)
