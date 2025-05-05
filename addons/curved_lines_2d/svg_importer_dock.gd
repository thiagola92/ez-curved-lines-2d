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
	var root_node := EditorInterface.get_edited_scene_root()
	var current_node := root_node
	
	if not root_node is Node2D:
		printerr("Scene root must be Node 2D")
		return 

	for c in root_node.get_children():
		c.queue_free()

	if xml_data.open(file_path) != OK:
		return
	while xml_data.read() == OK:
		if not xml_data.get_node_type() in [XMLParser.NODE_ELEMENT, XMLParser.NODE_ELEMENT_END]:
			continue
		elif xml_data.get_node_name() == "g":
			if xml_data.get_node_type() == XMLParser.NODE_ELEMENT:
				process_group(xml_data, current_node, root_node)
			elif xml_data.get_node_type() == XMLParser.NODE_ELEMENT_END:
				if current_node == root_node:
					printerr("Hierarchy error, current not is already scene root")
					break
				current_node = current_node.get_parent()
		elif xml_data.get_node_name() == "rect":
			process_svg_rectangle(xml_data, current_node, root_node)
		elif xml_data.get_node_name() == "polygon":
			process_svg_polygon(xml_data, current_node, root_node)
		elif xml_data.get_node_name() == "path":
			process_svg_path(xml_data, current_node, root_node)


func process_group(element:XMLParser, current_node, root_node) -> void:
	var new_group = Node2D.new()
	new_group.name = element.get_named_attribute_value("id")
	new_group.transform = get_svg_transform(element)
	current_node.add_child(new_group)
	new_group.set_owner(root_node)
	new_group.set_meta("_edit_group_", true)
	current_node = new_group
	print("group " + new_group.name + " created")


func process_svg_rectangle(element:XMLParser, current_node, root_node) -> void:
	var new_rect = ColorRect.new()
	new_rect.name = element.get_named_attribute_value("id")
	current_node.add_child(new_rect)
	new_rect.set_owner(root_node)
	
	#transform
	var x = float(element.get_named_attribute_value("x"))
	var y = float(element.get_named_attribute_value("y"))
	var width = float(element.get_named_attribute_value("width"))
	var height = float(element.get_named_attribute_value("height"))
	var transform = get_svg_transform(element)
	new_rect.position = Vector2((x), (y))
	new_rect.size = Vector2(width, height)
	new_rect.position = transform * new_rect.position
	new_rect.size.x *= transform[0][0] 
	new_rect.size.y *= transform[1][1]
	
	#style
	var style = get_svg_style(element)
	if style.has("fill"):
		new_rect.color = Color(style["fill"])
	if style.has("fill-opacity"):
		new_rect.color.a = float(style["fill-opacity"])
		
	print("-rect ", new_rect.name, " created")


func process_svg_polygon(element:XMLParser, current_node, root_node) -> void:
	var points : PackedVector2Array
	var points_split = element.get_named_attribute_value("points").split(" ", false)
	for i in points_split:
		var values = i.split_floats(",", false)
		points.append(Vector2(values[0], values[1]))
	points.append(points[0])

	#create closed line
	var new_line = Line2D.new()
	new_line.name = element.get_named_attribute_value("id")
	new_line.transform = get_svg_transform(element)
	current_node.add_child(new_line)
	new_line.set_owner(root_node)
	new_line.points = points
	
	#style
	var style = get_svg_style(element)
	if style.has("fill"):
		new_line.default_color = Color(style["fill"])
	if style.has("stroke-width"):
		new_line.width = float(style["stroke-width"])

	print("-line ", new_line.name, " created")


func process_svg_path(element:XMLParser, current_node, root_node) -> void:
	#prepare element string
	var element_string = element.get_named_attribute_value("d")
	element_string = element_string.replacen(",", " ")
	
	#split element string into multiple arrays
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
	
	#convert into Line2Ds
	var string_array_count = -1
	for string_array in string_arrays:
		var cursor = Vector2.ZERO
		#var points : PackedVector2Array
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
				#simpify Bezier curves with straight line
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
						cursor = Vector2(float(string_array[i+5]), float(string_array[i+6]))
						curve.add_point(cursor)
						i += 6
				"s":
					while string_array.size() > i + 4 and string_array[i+1].is_valid_float():
						cursor += Vector2(float(string_array[i+3]), float(string_array[i+4]))
						curve.add_point(cursor)
						i += 4
				"S":
					while string_array.size() > i + 4 and string_array[i+1].is_valid_float():
						cursor = Vector2(float(string_array[i+3]), float(string_array[i+4]))
						curve.add_point(cursor)
						i += 4
		
		if curve.get_point_count() > 1:
			create_path2d(	element.get_named_attribute_value("id") + "_" + str(string_array_count), 
							current_node, 
							curve, 
							get_svg_transform(element), 
							get_svg_style(element),
							root_node)
		
		#if string_array[string_array.size()-1].to_upper() == "Z": #closed polygon
			#create_polygon2d(	element.get_named_attribute_value("id") + "_" + str(string_array_count), 
								#current_node, 
								#points, 
								#get_svg_transform(element), 
								#get_svg_style(element),
								#root_node)
		#else:
			#create_line2d(	element.get_named_attribute_value("id") + "_" + str(string_array_count), 
							#current_node, 
							#points, 
							#get_svg_transform(element), 
							#get_svg_style(element),
							#root_node)


func create_path2d(	name:String, 
					parent:Node, 
					curve:Curve2D, 
					transform:Transform2D, 
					style:Dictionary,
					root_node:Node2D) -> void:
	var new_path = DrawablePath2D.new()
	new_path.name = name
	new_path.transform = transform
	new_path.curve = curve
	new_path.self_modulate = Color.TRANSPARENT
	parent.add_child(new_path)
	new_path.set_owner(root_node)
	
	if style.has("stroke"):
		var line := Line2D.new()
		new_path.add_child(line)
		line.set_owner(root_node)
		if style["stroke"] != "none" and not style["stroke"].begins_with("url"):
			line.default_color = Color(style["stroke"])
		if style.has("stroke-width"):
			line.width = float(style['stroke-width'])
		new_path.line = line
	if style.has("fill"):
		var polygon := Polygon2D.new()
		new_path.add_child(polygon)
		polygon.set_owner(root_node)
		if style["fill"] != "none" and not style["fill"].begins_with("url"):
			polygon.color = Color(style["fill"])
		new_path.polygon = polygon


func create_line2d(	name:String, 
					parent:Node, 
					points:PackedVector2Array, 
					transform:Transform2D, 
					style:Dictionary,
					root_node:Node2D) -> void:
	var new_line = Line2D.new()
	new_line.name = name
	new_line.transform = transform
	parent.add_child(new_line)
	new_line.set_owner(root_node)
	new_line.points = points
	
	#style
	if style.has("stroke"):
		new_line.default_color = Color(style["stroke"])
	if style.has("stroke-width"):
		new_line.width = float(style["stroke-width"])


func create_polygon2d(	name:String, 
						parent:Node, 
						points:PackedVector2Array, 
						transform:Transform2D, 
						style:Dictionary,
						root_node : Node2D) -> void:
	var new_poly
	#style
	if style.has("fill") and style["fill"] != "none":
		#create base
		new_poly = Polygon2D.new()
		new_poly.name = name
		parent.add_child(new_poly)
		new_poly.set_owner(root_node)
		new_poly.transform = transform
		new_poly.polygon = points
		new_poly.color = Color(style["fill"])
	
	if style.has("stroke") and style["stroke"] != "none":
		#create outline
		var new_outline = Line2D.new()
		new_outline.name = name + "_stroke"
		if new_poly:
			new_poly.add_child(new_outline)
		else:
			parent.add_child(new_outline)
			new_outline.transform = transform
		new_outline.set_owner(root_node)
		points.append(points[0])
		new_outline.points = points
		
		new_outline.default_color = Color(style["stroke"])
		if style.has("stroke-width"):
			new_outline.width = float(style["stroke-width"])


static func get_svg_transform(element:XMLParser) -> Transform2D:
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

	return style.data
