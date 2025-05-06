@tool
extends Control


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not typeof(data) == TYPE_DICTIONARY and "type" in data and data["type"] == "files":
		return false
	
	for file : String in data["files"]:
		if file.ends_with(".svg"):
			return true

	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if _can_drop_data(at_position, data):
		_load_svg(data["files"][0])


func _load_svg(file_path : String) -> void:
	var xml_data = XMLParser.new()
	var scene_root := EditorInterface.get_edited_scene_root()

	if not scene_root is Node2D:
		printerr("Scene root must be Node2D")
		return 
	if xml_data.open(file_path) != OK:
		return

	var svg_root := Node2D.new()
	svg_root.name = "SvgImport"
	scene_root.add_child(svg_root, true)
	svg_root.set_owner(scene_root)
	var current_node := svg_root
	var in_style_block := false
	while xml_data.read() == OK:
		if not xml_data.get_node_type() in [XMLParser.NODE_ELEMENT, XMLParser.NODE_ELEMENT_END]:
			if in_style_block:
				print(xml_data.get_node_name())
			continue
		elif xml_data.get_node_name() == "g":
			if xml_data.get_node_type() == XMLParser.NODE_ELEMENT:
				current_node = process_group(xml_data, current_node, scene_root)
			elif xml_data.get_node_type() == XMLParser.NODE_ELEMENT_END:
				if current_node == svg_root:
					printerr("Hierarchy error, current not is already scene root")
					break
				current_node = current_node.get_parent()
		elif xml_data.get_node_name() == "rect":
			process_svg_rectangle(xml_data, current_node, scene_root)
		elif xml_data.get_node_name() == "polygon" or xml_data.get_node_name() == "polyline":
			process_svg_polygon(xml_data, current_node, scene_root)
		elif xml_data.get_node_name() == "path":
			process_svg_path(xml_data, current_node, scene_root)
		elif xml_data.get_node_name() == "circle":
			process_svg_circle(xml_data, current_node, scene_root)
		elif xml_data.get_node_name() == "svg":
			if xml_data.has_attribute("viewBox") and xml_data.has_attribute("width") and xml_data.has_attribute("height"):
				var view_box := xml_data.get_named_attribute_value("viewBox").split_floats(" ")
				var width := float(xml_data.get_named_attribute_value("width"))
				var height := float(xml_data.get_named_attribute_value("height"))
				svg_root.scale.x = width / view_box[2]
				svg_root.scale.y = height / view_box[3]
				if xml_data.get_named_attribute_value("width").ends_with("mm"): # unit conversion to pixel
					svg_root.scale *= 3.78
				elif xml_data.get_named_attribute_value("width").ends_with("cm"):
					svg_root.scale *= 37.8
		elif xml_data.get_node_name() == "style":
			printerr("Only inline styles are supported")
		else:
			print(xml_data.get_node_name())


func process_group(element:XMLParser, current_node, scene_root) -> Node2D:
	var new_group = Node2D.new()
	new_group.name = element.get_named_attribute_value("id") if element.has_attribute("id") else "Group"
	new_group.transform = get_svg_transform(element)
	current_node.add_child(new_group, true)
	new_group.set_owner(scene_root)
	return new_group


func process_svg_circle(element:XMLParser, current_node : Node2D, scene_root : Node2D) -> void:
	var cx = float(element.get_named_attribute_value("cx"))
	var cy = float(element.get_named_attribute_value("cy"))
	var r = float(element.get_named_attribute_value("r"))
	var curve := Curve2D.new()
	var path_name = element.get_named_attribute_value("id") if element.has_attribute("id") else "Circle"
	curve.add_point(Vector2(r, 0), Vector2.ZERO, Vector2(0, r * 0.5523))
	curve.add_point(Vector2(0, r), Vector2(r * 0.5523, 0), Vector2(-r * 0.5523, 0))
	curve.add_point(Vector2(-r, 0), Vector2(0, r * 0.5523), Vector2(0, -r * 0.5523))
	curve.add_point(Vector2(0, -r),  Vector2(-r * 0.5523, 0), Vector2(r * 0.5523, 0))
	curve.add_point(Vector2(r, 0), Vector2(0, -r * 0.5523))
	create_path2d(path_name, current_node, curve, 
			get_svg_transform(element),
			get_svg_style(element), scene_root, true, Vector2(cx, cy))


func process_svg_rectangle(element:XMLParser, current_node, scene_root) -> void:
	print("TODO convert rect to DrawablePath2D")
	#var new_rect = ColorRect.new()
	#new_rect.name = element.get_named_attribute_value("id") if element.has_attribute("id") else "Rect"
	#current_node.add_child(new_rect, true)
	#new_rect.set_owner(scene_root)
	#
	##transform
	#var x = float(element.get_named_attribute_value("x"))
	#var y = float(element.get_named_attribute_value("y"))
	#var width = float(element.get_named_attribute_value("width"))
	#var height = float(element.get_named_attribute_value("height"))
	#var transform = get_svg_transform(element)
	#new_rect.position = Vector2((x), (y))
	#new_rect.size = Vector2(width, height)
	#new_rect.position = transform * new_rect.position
	#new_rect.size.x *= transform[0][0] 
	#new_rect.size.y *= transform[1][1]
	#
	##style
	#var style = get_svg_style(element)
	#if style.has("fill"):
		#new_rect.color = Color(style["fill"])
	#if style.has("fill-opacity"):
		#new_rect.color.a = float(style["fill-opacity"])
		#
	#print("-rect ", new_rect.name, " created")


func process_svg_polygon(element:XMLParser, current_node, scene_root) -> void:
		print("TODO convert polygon and polyline to DrawablePath2D")

	#var points : PackedVector2Array
	#var points_split = element.get_named_attribute_value("points").split(" ", false)
	#for i in points_split:
		#var values = i.split_floats(",", false)
		#points.append(Vector2(values[0], values[1]))
	#points.append(points[0])
#
	##create closed line
	#var new_line = Line2D.new()
	#new_line.name = element.get_named_attribute_value("id")  if element.has_attribute("id") else "Line"
	#new_line.transform = get_svg_transform(element)
	#current_node.add_child(new_line, true)
	#new_line.set_owner(scene_root)
	#new_line.points = points
	#
	##style
	#var style = get_svg_style(element)
	#if style.has("fill"):
		#new_line.default_color = Color(style["fill"])
	#if style.has("stroke-width"):
		#new_line.width = float(style["stroke-width"])
	#if style.is_empty():
		#new_line.width = 1.0
	#print("-line ", new_line.name, " created")


func process_svg_path(element:XMLParser, current_node, scene_root) -> void:
	# FIXME: better parsing, splits into sub arrays not necessary
	var element_string = element.get_named_attribute_value("d")
	element_string = element_string.replacen(",", " ")
	for symbol in ["m", "M", "v", "V", "h", "H", "l", "L", "c", "C", "s", "S", "a", "A", "q", "Q", "t", "T", "z", "Z"]:
		element_string = element_string.replace(symbol, " " + symbol + " ")

	var element_string_array = element_string.split(" ", false)
	var string_arrays = []
	var string_array_top : PackedStringArray
	for a in element_string_array:
		if a == "m" or a == "M":
			if string_array_top.size() > 0:
				string_arrays.append(string_array_top)
				string_array_top.resize(0)
		string_array_top.append(a)
	string_arrays.append(string_array_top)
	
	print(string_arrays.size())
	var string_array_count = -1
	for string_array in string_arrays:
		var cursor = Vector2.ZERO
		var curve = Curve2D.new()
		string_array_count += 1
		
		for i in string_array.size()-1:
			match string_array[i]:
				"m":
					while string_array.size() > i + 2 and string_array[i+1].is_valid_float():
						cursor += Vector2(float(string_array[i+1]), float(string_array[i+2]))
						curve.add_point(cursor)
						i += 2
				"M":
					while string_array.size() > i + 2 and string_array[i+1].is_valid_float():
						cursor = Vector2(float(string_array[i+1]), float(string_array[i+2]))
						curve.add_point(cursor)
						i += 2
				"v":
					while string_array[i+1].is_valid_float():
						cursor.y += float(string_array[i+1])
						curve.add_point(cursor)
						i += 1
				"V":
					while string_array[i+1].is_valid_float():
						cursor.y = float(string_array[i+1])
						curve.add_point(cursor)
						i += 1
				"h":
					while string_array[i+1].is_valid_float():
						cursor.x += float(string_array[i+1])
						curve.add_point(cursor)
						i += 1
				"H":
					while string_array[i+1].is_valid_float():
						cursor.x = float(string_array[i+1])
						curve.add_point(cursor)
						i += 1
				"l":
					while string_array.size() > i + 2 and string_array[i+1].is_valid_float():
						cursor += Vector2(float(string_array[i+1]), float(string_array[i+2]))
						curve.add_point(cursor)
						i += 2
				"L":
					while string_array.size() > i + 2 and string_array[i+1].is_valid_float():
						cursor = Vector2(float(string_array[i+1]), float(string_array[i+2]))
						curve.add_point(cursor)
						i += 2
				"c": 
					while string_array.size() > i + 6 and string_array[i+1].is_valid_float():
						var c_out := Vector2(float(string_array[i+1]), float(string_array[i+2]))
						var c_2 :=  Vector2(float(string_array[i+3]), float(string_array[i+4]))
						var c_in_absolute = cursor + c_2
						curve.set_point_out(curve.get_point_count() - 1, c_out)
						cursor += Vector2(float(string_array[i+5]), float(string_array[i+6]))
						var c_in = c_in_absolute - cursor
						curve.add_point(cursor)
						curve.set_point_in(curve.get_point_count() - 1, c_in)
						i += 6
				"C":
					while string_array.size() > i + 6 and string_array[i+1].is_valid_float():
						var c_out := Vector2(float(string_array[i+1]), float(string_array[i+2]))
						var prev_point := curve.get_point_position(curve.get_point_count() - 1)
						var c_in := Vector2(float(string_array[i+3]), float(string_array[i+4]))
						curve.set_point_out(curve.get_point_count() - 1, c_out - prev_point)
						cursor = Vector2(float(string_array[i+5]), float(string_array[i+6]))
						curve.add_point(cursor, c_in - cursor)
						i += 6
				"s":
					while string_array.size() > i + 4 and string_array[i+1].is_valid_float():
						var c_out := -curve.get_point_in(curve.get_point_count() - 1)
						var c_2 :=  Vector2(float(string_array[i+1]), float(string_array[i+2]))
						var c_in_absolute = cursor + c_2
						curve.set_point_out(curve.get_point_count() - 1, c_out)
						cursor += Vector2(float(string_array[i+3]), float(string_array[i+4]))
						var c_in = c_in_absolute - cursor
						curve.add_point(cursor)
						curve.set_point_in(curve.get_point_count() - 1, c_in)
						i += 4
				"S":
					while string_array.size() > i + 4 and string_array[i+1].is_valid_float():
						var c_out := -curve.get_point_in(curve.get_point_count() - 1)
						curve.set_point_out(curve.get_point_count() - 1, c_out)
						cursor = Vector2(float(string_array[i+3]), float(string_array[i+4]))
						var c_in := Vector2(float(string_array[i+1]), float(string_array[i+2]))
						curve.add_point(cursor, c_in - cursor)
						i += 4
				"A":
					while string_array.size() > i + 10 and string_array[i+1].is_valid_float():
						cursor = Vector2(float(string_array[i+9]), float(string_array[i+10]))
						curve.add_point(cursor)
						i += 10

		if curve.get_point_count() > 1:
			var id = element.get_named_attribute_value("id") if element.has_attribute("id") else "Path"
			create_path2d(id + "_" + str(string_array_count), 
								current_node, 
								curve, 
								get_svg_transform(element), 
								get_svg_style(element),
								scene_root,
								string_array[string_array.size()-1].to_upper() == "Z")


func create_path2d(path_name: String, 
					parent: Node, 
					curve: Curve2D, 
					transform: Transform2D, 
					style: Dictionary,
					scene_root: Node2D,
					is_closed := false,
					pos_override := Vector2.ZERO) -> void:
	var new_path = DrawablePath2D.new()
	new_path.name = path_name
	new_path.transform = transform
	new_path.position = pos_override * transform

	new_path.curve = curve
	new_path.self_modulate = Color.TRANSPARENT
	parent.add_child(new_path, true)
	new_path.set_owner(scene_root)
	
	if style.has("stroke") and style["stroke"] != "none": 
		var line := Line2D.new()
		line.name = "Stroke"
		new_path.add_child(line, true)
		line.set_owner(scene_root)
		if not style["stroke"].begins_with("url"):
			line.default_color = Color(style["stroke"])
		if style.has("stroke-width"):
			line.width = float(style['stroke-width'])
		new_path.line = line
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.closed = is_closed
	if style.has("fill") and style["fill"] != "none":
		var polygon := Polygon2D.new()
		polygon.name = "Fill"
		new_path.add_child(polygon, true)
		polygon.set_owner(scene_root)
		if not style["fill"].begins_with("url"):
			polygon.color = Color(style["fill"])
		new_path.polygon = polygon
	if style.is_empty():
		var line := Line2D.new()
		line.name = "Stroke"
		new_path.add_child(line, true)
		line.set_owner(scene_root)
		new_path.line = line
		line.width = 1.0
		line.closed = is_closed


func get_svg_transform(element:XMLParser) -> Transform2D:
	var transform = Transform2D.IDENTITY
	if element.has_attribute("transform"):
		var svg_transform = element.get_named_attribute_value("transform")
		#check transform method
		if svg_transform.begins_with("translate"):
			svg_transform = svg_transform.replace("translate", "").replacen("(", "").replacen(")", "")
			var transform_split = svg_transform.split_floats(",")
			transform[2] = Vector2(transform_split[0], transform_split[1])
		elif svg_transform.begins_with("matrix"):
			svg_transform = svg_transform.replace("matrix", "").replacen("(", "").replacen(")", "")
			var matrix = svg_transform.split_floats(",")
			for i in 3:
				transform[i] = Vector2(matrix[i*2], matrix[i*2+1])
	return transform


func get_svg_style(element:XMLParser) -> Dictionary:
	var style = {}
	if element.has_attribute("style"):
		var svg_style = element.get_named_attribute_value("style")
		svg_style = svg_style.replacen(":", "\":\"")
		svg_style = svg_style.replacen(";", "\",\"")
		svg_style = "{\"" + svg_style + "\"}"
		var json = JSON.new()
		var error = json.parse(svg_style)
		if error == OK:
			return json.data

	return style
