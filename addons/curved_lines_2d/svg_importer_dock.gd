@tool
extends Control

# Fraction of a radius for a bezier control point
const R_TO_CP = 0.5523
const SUPPORTED_STYLES : Array[String] = ["opacity", "stroke", "stroke-width", "stroke-opacity", 
		"fill", "fill-opacity", "paint-order"]

enum LogLevel { DEBUG, INFO, WARN, ERROR }
var undo_redo : EditorUndoRedoManager = null
var log_scroll_container : ScrollContainer = null
var log_container : VBoxContainer = null
var error_label_settings : LabelSettings = null
var warning_label_settings : LabelSettings = null
var info_label_settings : LabelSettings = null
var debug_label_settings : LabelSettings = null


func _enter_tree() -> void:
	log_scroll_container = find_child("ScrollContainer")
	log_container = find_child("ImportLogContainer")
	error_label_settings = preload("res://addons/curved_lines_2d/error_label_settings.tres")
	warning_label_settings = preload("res://addons/curved_lines_2d/warn_label_settings.tres")
	info_label_settings = preload("res://addons/curved_lines_2d/info_label_settings.tres")
	debug_label_settings = preload("res://addons/curved_lines_2d/debug_label_settings.tres")
	log_scroll_container.get_v_scroll_bar().connect("changed", func(): log_scroll_container.scroll_vertical = log_scroll_container.get_v_scroll_bar().max_value )

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not typeof(data) == TYPE_DICTIONARY and "type" in data and data["type"] == "files":
		return false
	for file : String in data["files"]:
		if file.ends_with(".svg"):
			return true
	return false


func log_message(msg : String, log_level : LogLevel = LogLevel.INFO) -> void:
	var lbl := Label.new()
	match log_level:
		LogLevel.ERROR:
			lbl.label_settings = error_label_settings
		LogLevel.WARN:
			lbl.label_settings = warning_label_settings
		LogLevel.DEBUG:
			lbl.label_settings = debug_label_settings
		LogLevel.INFO,_:
			lbl.label_settings = info_label_settings
	lbl.text = msg
	log_container.add_child(lbl)


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if _can_drop_data(at_position, data):
		var svg_root = _load_svg(data["files"][0])
		

func _load_svg(file_path : String) -> Node2D:
	for child in log_container.get_children():
		child.queue_free()
	var xml_data = XMLParser.new()
	var scene_root := EditorInterface.get_edited_scene_root()

	if not scene_root is Node2D:
		log_message("ERROR: Can only import into 2D scene", LogLevel.ERROR)
		return null
	if xml_data.open(file_path) != OK:
		log_message("ERROR: Failed to open %s for reading" % file_path, LogLevel.ERROR)
		return null

	log_message("Importing SVG file: %s" % file_path, LogLevel.INFO)
	var svg_root := Node2D.new()
	svg_root.name = "SvgImport"
	scene_root.add_child(svg_root, true)
	svg_root.set_owner(scene_root)
	var current_node := svg_root
	var svg_linear_gradients : Array[Dictionary] = []

	while xml_data.read() == OK:
		if not xml_data.get_node_type() in [XMLParser.NODE_ELEMENT, XMLParser.NODE_ELEMENT_END]:
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
			process_svg_rectangle(xml_data, current_node, scene_root, svg_linear_gradients)
		elif xml_data.get_node_name() == "polygon":
			process_svg_polygon(xml_data, current_node, scene_root, true, svg_linear_gradients)
		elif xml_data.get_node_name() == "polyline":
			process_svg_polygon(xml_data, current_node, scene_root, false, svg_linear_gradients)
		elif xml_data.get_node_name() == "path":
			process_svg_path(xml_data, current_node, scene_root, svg_linear_gradients)
		elif xml_data.get_node_name() == "circle":
			process_svg_circle(xml_data, current_node, scene_root, svg_linear_gradients)
		elif xml_data.get_node_name() == "ellipse":
			process_svg_ellipse(xml_data, current_node, scene_root, svg_linear_gradients)
		elif xml_data.get_node_name() == "svg":
			if xml_data.has_attribute("viewBox") and xml_data.has_attribute("width") and xml_data.has_attribute("height"):
				var view_box := xml_data.get_named_attribute_value("viewBox").split_floats(" ")
				var width := float(xml_data.get_named_attribute_value("width"))
				var height := float(xml_data.get_named_attribute_value("height"))
				svg_root.scale.x = width / view_box[2]
				svg_root.scale.y = height / view_box[3]
				if xml_data.get_named_attribute_value("width").ends_with("mm"): # unit conversion to pixel
					log_message("⚠️ Units for this image are millimeters (mm), image scale set to 3.78")
					svg_root.scale *= 3.78
				elif xml_data.get_named_attribute_value("width").ends_with("cm"):
					log_message("⚠️ Units for this image are centimeters (cm), image scale set to 37.8")
					svg_root.scale *= 37.8
		elif xml_data.get_node_name() == "style" and xml_data.get_node_type() == XMLParser.NODE_ELEMENT:
			log_message("⚠️ Skipping <style> node, only inline style attribute and some presentation attributes are supported", LogLevel.WARN)
		elif xml_data.get_node_name() == "defs":
			pass
		elif xml_data.get_node_name() == "linearGradient":
			svg_linear_gradients.append(parse_linear_gradient(xml_data, svg_linear_gradients))
		elif xml_data.get_node_type() == XMLParser.NODE_ELEMENT:
			log_message("⚠️ Skipping  unsupported node: <%s>" % xml_data.get_node_name(), LogLevel.DEBUG)
	log_message("Parsed linear gradients: %s" % str(svg_linear_gradients), LogLevel.DEBUG)
	log_message("Import finished.\n\nThe SVG importer is in a very early stage of development.")
	
	var link_button := LinkButton.new()
	link_button.text = "Click here to report issues or improvement requests on github"
	link_button.uri = "https://github.com/Teaching-myself-Godot/ez-curved-lines-2d/issues"
	log_container.add_child(link_button)
	return svg_root


func get_gradient_by_href(href : String, gradients : Array[Dictionary]) -> Dictionary:
	var idx := gradients.find_custom(func(x): return "id" in x and "#" + x["id"] == href)
	if idx < 0:
		return {}
	return gradients[idx]


func parse_linear_gradient(xml_data : XMLParser, current_gradients : Array[Dictionary]) -> Dictionary:
	var new_gradient := {}
	for i in range(xml_data.get_attribute_count()):
		new_gradient[xml_data.get_attribute_name(i)] = xml_data.get_attribute_value(i)

	if not xml_data.is_empty():
		new_gradient["stops"] = []
		while xml_data.read() == OK:
			if xml_data.get_node_type() == XMLParser.NODE_ELEMENT and xml_data.get_node_name() == "stop":
				new_gradient["stops"].append({
					"style": get_svg_style(xml_data),
					"offset": float(xml_data.get_named_attribute_value_safe("offset")),
					"id": xml_data.get_named_attribute_value_safe("id")
				})
			elif xml_data.get_node_type() == XMLParser.NODE_ELEMENT_END and xml_data.get_node_name() == "linearGradient":
				break

	return new_gradient


func process_group(element:XMLParser, current_node : Node2D, scene_root : Node2D) -> Node2D:
	var new_group = Node2D.new()
	new_group.name = element.get_named_attribute_value("id") if element.has_attribute("id") else "Group"
	new_group.transform = get_svg_transform(element)
	current_node.add_child(new_group, true)
	new_group.set_owner(scene_root)
	return new_group


func process_svg_circle(element:XMLParser, current_node : Node2D, scene_root : Node2D,
		gradients : Array[Dictionary]) -> void:
	var cx = float(element.get_named_attribute_value("cx"))
	var cy = float(element.get_named_attribute_value("cy"))
	var r = float(element.get_named_attribute_value("r"))
	var path_name = element.get_named_attribute_value("id") if element.has_attribute("id") else "Circle"
	create_path_from_ellipse(element, path_name, r, r, Vector2(cx, cy), current_node, scene_root, gradients)


func process_svg_ellipse(element:XMLParser, current_node : Node2D, scene_root : Node2D,
		gradients : Array[Dictionary]) -> void:
	var cx = float(element.get_named_attribute_value("cx"))
	var cy = float(element.get_named_attribute_value("cy"))
	var rx = float(element.get_named_attribute_value("rx"))
	var ry = float(element.get_named_attribute_value("ry"))
	var path_name = element.get_named_attribute_value("id") if element.has_attribute("id") else "Ellipse"
	create_path_from_ellipse(element, path_name, rx, ry, Vector2(cx, cy), current_node, scene_root, gradients)


func create_path_from_ellipse(element:XMLParser, path_name : String, rx : float, ry: float, 
		pos : Vector2, current_node : Node2D, scene_root : Node2D,
		gradients : Array[Dictionary]) -> void:
	var curve := Curve2D.new()
	curve.add_point(Vector2(rx, 0), Vector2.ZERO, Vector2(0, ry * R_TO_CP))
	curve.add_point(Vector2(0, ry), Vector2(rx * R_TO_CP, 0), Vector2(-rx * R_TO_CP, 0))
	curve.add_point(Vector2(-rx, 0), Vector2(0, ry * R_TO_CP), Vector2(0, -ry * R_TO_CP))
	curve.add_point(Vector2(0, -ry), Vector2(-rx * R_TO_CP, 0), Vector2(rx * R_TO_CP, 0))
	curve.add_point(Vector2(rx, 0), Vector2(0, -ry * R_TO_CP))
	create_path2d(path_name, current_node, curve, 
			get_svg_transform(element),
			get_svg_style(element), scene_root, gradients, true, pos)


func process_svg_rectangle(element:XMLParser, current_node : Node2D, scene_root : Node2D,
		gradients : Array[Dictionary]) -> void:
	var curve := Curve2D.new()
	var x = float(element.get_named_attribute_value("x"))
	var y = float(element.get_named_attribute_value("y"))
	var ry = float(element.get_named_attribute_value("ry")) if element.has_attribute("ry") else 0
	var rx = float(element.get_named_attribute_value("rx")) if element.has_attribute("rx") else ry
	var width = float(element.get_named_attribute_value("width"))
	var height = float(element.get_named_attribute_value("height"))
	if rx == 0 and ry == 0:
		curve.add_point(Vector2.ZERO)
		curve.add_point(Vector2(width, 0))
		curve.add_point(Vector2(width, height))
		curve.add_point(Vector2(0, height))
	else:
		curve.add_point(Vector2(width - rx, 0), Vector2.ZERO, Vector2(rx * R_TO_CP, 0))
		curve.add_point(Vector2(width, ry), Vector2(0, -ry * R_TO_CP))
		curve.add_point(Vector2(width, height - ry), Vector2.ZERO, Vector2(0, ry * R_TO_CP))
		curve.add_point(Vector2(width - rx, height), Vector2(rx * R_TO_CP, 0))
		curve.add_point(Vector2(rx, height), Vector2.ZERO, Vector2(-rx * R_TO_CP, 0))
		curve.add_point(Vector2(0, height - ry), Vector2(0, ry * R_TO_CP))
		curve.add_point(Vector2(0, ry), Vector2.ZERO, Vector2(0, -ry * R_TO_CP))
		curve.add_point(Vector2(rx, 0), Vector2(-rx * R_TO_CP, 0))
	var path_name = element.get_named_attribute_value("id") if element.has_attribute("id") else "Rect"
	create_path2d(path_name, current_node, curve,
			get_svg_transform(element), get_svg_style(element), scene_root, gradients, true,
			Vector2(x, y))


func process_svg_polygon(element:XMLParser, current_node : Node2D, scene_root : Node2D, is_closed : bool,
		gradients : Array[Dictionary]) -> void:
	var points_split = element.get_named_attribute_value("points").split(" ", false)
	var curve = Curve2D.new()
	for p in points_split:
		var values = p.split_floats(",", false)
		curve.add_point(Vector2(values[0], values[1]))
	var path_name = (element.get_named_attribute_value("id") if element.has_attribute("id") else
			"Polygon" if is_closed else
			"Polyline"
	)
	create_path2d(path_name, current_node, curve,
			get_svg_transform(element), get_svg_style(element), scene_root, gradients, is_closed)


func process_svg_path(element:XMLParser, current_node : Node2D, scene_root : Node2D,
		gradients : Array[Dictionary]) -> void:
	# FIXME: better parsing, splits into sub arrays not necessary

	var str_path = parse_attribute_string(
				element.get_named_attribute_value("d")).replacen(",", " ")

	for symbol in ["m", "M", "v", "V", "h", "H", "l", "L", "c", "C", "s", "S", "a", "A", "q", "Q", "t", "T", "z", "Z"]:
		str_path = str_path.replace(symbol, " " + symbol + " ")

	var str_path_array = str_path.split(" ", false)
	var string_arrays = []
	var string_array_top : PackedStringArray
	for a in str_path_array:
		if a == "m" or a == "M":
			if string_array_top.size() > 0:
				string_arrays.append(string_array_top)
				string_array_top.resize(0)
		string_array_top.append(a)
	string_arrays.append(string_array_top)

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
				"q":
					log_message("WARNING: the 'q' (relative quadratic Bézier curveto) operation is not yet supported, shape for <path id=\"%s\"> will be incorrect" % 
							(element.get_named_attribute_value("id") if element.has_attribute("id") else "?"), LogLevel.WARN)
					while string_array.size() > i + 4 and string_array[i+4].is_valid_float():
						var prev_point := curve.get_point_position(curve.get_point_count() - 1)
						var quadratic_control_point = cursor + Vector2(float(string_array[i+1]), float(string_array[i+2]))
						log_message("previous point pos: " + str(prev_point), LogLevel.DEBUG)
						log_message("quadratic control point: " + str(quadratic_control_point), LogLevel.DEBUG)
						var c_out = (quadratic_control_point - prev_point) * (2.0/3.0)
						log_message("cubic control point out: " + str(c_out), LogLevel.DEBUG)
						cursor += Vector2(float(string_array[i+3]), float(string_array[i+4]))
						log_message("next point pos: " + str(cursor), LogLevel.DEBUG)
						var c_in = (quadratic_control_point - cursor) * (2.0/3.0)
						log_message("next control point in: " + str(c_in), LogLevel.DEBUG)
						curve.set_point_out(curve.get_point_count() - 1, c_out)
						curve.add_point(cursor, c_in)
						i += 4
				"Q":
					while string_array.size() > i + 4 and string_array[i+4].is_valid_float():
						var prev_point := curve.get_point_position(curve.get_point_count() - 1)
						var quadratic_control_point := Vector2(float(string_array[i+1]), float(string_array[i+2]))
						log_message("previous point pos: " + str(prev_point), LogLevel.DEBUG)
						log_message("quadratic control point: " + str(quadratic_control_point), LogLevel.DEBUG)
						var c_out = (quadratic_control_point - prev_point) * (2.0/3.0)
						log_message("cubic control point out: " + str(c_out), LogLevel.DEBUG)
						cursor = Vector2(float(string_array[i+3]), float(string_array[i+4]))
						log_message("next point pos: " + str(cursor), LogLevel.DEBUG)
						var c_in = (quadratic_control_point - cursor) * (2.0/3.0)
						log_message("next control point in: " + str(c_in), LogLevel.DEBUG)
						curve.set_point_out(curve.get_point_count() - 1, c_out)
						curve.add_point(cursor, c_in)
						i += 4
				"t":
					while string_array.size() > i + 2 and string_array[i+2].is_valid_float():
						var c_out := -curve.get_point_in(curve.get_point_count() - 1)
						var quadratic_control_point := curve.get_point_position(curve.get_point_count() - 1) + (c_out / (2.0/3.0))
						log_message("quadratic control point: " + str(quadratic_control_point), LogLevel.DEBUG)
						curve.set_point_out(curve.get_point_count() - 1, c_out)
						cursor += Vector2(float(string_array[i+1]), float(string_array[i+2]))
						var c_in = (quadratic_control_point - cursor) * (2.0/3.0)
						log_message("next control point in: " + str(c_in), LogLevel.DEBUG)
						curve.add_point(cursor, c_in)
						i += 2
				"T":
					while string_array.size() > i + 2 and string_array[i+2].is_valid_float():
						var c_out := -curve.get_point_in(curve.get_point_count() - 1)
						var quadratic_control_point := curve.get_point_position(curve.get_point_count() - 1) + (c_out / (2.0/3.0))
						log_message("quadratic control point: " + str(quadratic_control_point), LogLevel.DEBUG)
						curve.set_point_out(curve.get_point_count() - 1, c_out)
						cursor = Vector2(float(string_array[i+1]), float(string_array[i+2]))
						var c_in = (quadratic_control_point - cursor) * (2.0/3.0)
						log_message("next control point in: " + str(c_in), LogLevel.DEBUG)
						curve.add_point(cursor, c_in)
						i += 2
				"a":
					log_message("WARNING: the 'a' (relative arc) operation is not yet supported, shape for <path id=\"%s\"> will be incorrect" % 
							(element.get_named_attribute_value("id") if element.has_attribute("id") else "?"), LogLevel.WARN)
					while string_array.size() > i + 7 and string_array[i+1].is_valid_float():
						cursor += Vector2(float(string_array[i+6]), float(string_array[i+7]))
						log_message(str(cursor), LogLevel.DEBUG)
						curve.add_point(cursor)
						i += 7
				"A":
					log_message("WARNING: the 'A' (absolute arc) operation is not yet supported, shape for <path id=\"%s\"> will be incorrect" % 
							(element.get_named_attribute_value("id") if element.has_attribute("id") else "?"), LogLevel.WARN)
					while string_array.size() > i + 7 and string_array[i+1].is_valid_float():
						cursor = Vector2(float(string_array[i+6]), float(string_array[i+7]))
						log_message(str(cursor), LogLevel.DEBUG)
						curve.add_point(cursor)
						i += 7

		if curve.get_point_count() > 1:
			var id = element.get_named_attribute_value("id") if element.has_attribute("id") else "Path"
			create_path2d(id + "_" + str(string_array_count), current_node,  curve, 
						get_svg_transform(element), get_svg_style(element), scene_root, gradients,
						string_array[string_array.size()-1].to_upper() == "Z")


func create_path2d(path_name: String, parent: Node, curve: Curve2D, transform: Transform2D, 
						style: Dictionary, scene_root: Node2D, gradients : Array[Dictionary],
						is_closed := false, pos_override := Vector2.ZERO) -> void:
	var new_path = DrawablePath2D.new()
	new_path.name = path_name
	new_path.position = pos_override
	new_path.curve = curve
	new_path.self_modulate = Color.TRANSPARENT
	if pos_override == Vector2.ZERO:
		new_path.set_position_to_center()
	if transform == Transform2D.IDENTITY:
		parent.add_child(new_path, true)
	else:
		var transform_node := Node2D.new()
		transform_node.name = path_name + "Transform"
		transform_node.transform = transform
		parent.add_child(transform_node, true)
		transform_node.add_child(new_path, true)
		transform_node.set_owner(scene_root)
	new_path.set_owner(scene_root)
	if style.has("opacity"):
		new_path.modulate.a = float(style["opacity"])
	if style.is_empty():
		var line := Line2D.new()
		line.name = "Stroke"
		new_path.add_child(line, true)
		line.set_owner(scene_root)
		new_path.line = line
		line.width = 1.0
		line.closed = is_closed

	if paint_order_is_normal(style):
		add_fill_to_path(new_path, style, scene_root, is_closed, gradients)
		add_stroke_to_path(new_path, style, scene_root, is_closed)
	else:
		add_stroke_to_path(new_path, style, scene_root, is_closed)
		add_fill_to_path(new_path, style, scene_root, is_closed, gradients)


func paint_order_is_normal(style : Dictionary) -> bool:
	if style.has("paint-order"):
		if style["paint-order"] == "normal":
			return true
		elif style["paint-order"] == "stroke":
			return false
		var parts = style["paint-order"].split(" ")
		return parts.find("stroke") > parts.find("fill")
	return true


func add_stroke_to_path(new_path : Node2D, style: Dictionary, scene_root : Node2D, is_closed: bool):
	if style.has("stroke") and style["stroke"] != "none": 
		var line := Line2D.new()
		line.name = "Stroke"
		new_path.add_child(line, true)
		line.set_owner(scene_root)
		if style["stroke"].begins_with("url"):
			log_message("⚠️ Unsupported stroke style: " + style["stroke"])
		else:
			line.default_color = Color(style["stroke"])
		if style.has("stroke-width"):
			line.width = float(style['stroke-width'])
		if style.has("stroke-opacity"):
			line.self_modulate.a = float(style["stroke-opacity"])
		new_path.line = line
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.closed = is_closed


func add_fill_to_path(new_path : DrawablePath2D, style: Dictionary, scene_root : Node2D, is_closed: bool,
		gradients : Array[Dictionary]):
	if style.has("fill") and style["fill"] != "none":
		var polygon := Polygon2D.new()
		polygon.name = "Fill"
		new_path.add_child(polygon, true)
		polygon.set_owner(scene_root)
		if style["fill"].begins_with("url"):
			var href : String = style["fill"].replace("url(", "").replace(")", "")
			var svg_gradient = get_gradient_by_href(href, gradients)
			if "xlink:href" in svg_gradient:
				svg_gradient.merge(get_gradient_by_href(svg_gradient["xlink:href"], gradients), false)
			elif "href" in svg_gradient:
				svg_gradient.merge(get_gradient_by_href(svg_gradient["href"], gradients), false)

			log_message("Processing gradient %s:" % href, LogLevel.DEBUG)
			log_message(str(svg_gradient), LogLevel.DEBUG)
			var texture := GradientTexture2D.new()
			var box := new_path.get_bounding_rect()
			texture.width = ceil(box.size.x)
			texture.height = ceil(box.size.y)
			texture.gradient = Gradient.new()
			var stops = svg_gradient["stops"] if "stops" in svg_gradient else []
			var gradient_data := {}
			for i in range(stops.size()):
				var stop_style = stops[i]["style"] if "style" in stops[i] else { "stop-color": "#ffffff" }
				var stop_color = stop_style["stop-color"] if "stop-color" in stop_style else "#ffffff"
				var stop_opacity = stop_style["stop-opacity"] if "stop-opacity" in stop_style else "1"
				gradient_data[float(stops[i]["offset"])] = Color(stop_color, float(stop_opacity))
			texture.gradient.colors = gradient_data.values()
			texture.gradient.offsets = gradient_data.keys()
			if "x1" in svg_gradient and "y1" in svg_gradient and "x2" in svg_gradient and "y2" in svg_gradient:
				var transform = (
					process_svg_transform(svg_gradient["gradientTransform"]) if "gradientTransform" in svg_gradient else 
					Transform2D.IDENTITY
				)
				var translated_box_tl = box.position + new_path.position

				var fill_from = Vector2(float(svg_gradient["x1"]), float(svg_gradient["y1"]))
				var fill_to = Vector2(float(svg_gradient["x2"]), float(svg_gradient["y2"]))
				log_message("From %s -> %s" % [str(fill_from), str(fill_from * transform)])
				log_message("From' %s -> %s" % [str(fill_from - translated_box_tl), str((fill_from*transform - translated_box_tl*transform))])

				log_message("To %s -> %s" % [str(fill_to), str(fill_to * transform)])
				log_message("To' %s -> %s" % [str(fill_to - translated_box_tl), str((fill_to*transform - translated_box_tl*transform))])

				log_message("Box TL %s/%s -> %s/%s" % [str(translated_box_tl), str(translated_box_tl + box.size),
						str(translated_box_tl * transform), str((translated_box_tl + box.size) * transform)])

				texture.fill_from = (fill_from - translated_box_tl) / box.size
				texture.fill_to = (fill_to - translated_box_tl) / box.size

			polygon.texture_offset = -box.position
			polygon.texture = texture
		else:
			polygon.color = Color(style["fill"])
		if style.has("fill-opacity"):
			polygon.self_modulate.a = float(style["fill-opacity"])
		new_path.polygon = polygon


func get_svg_transform(element:XMLParser) -> Transform2D:
	if element.has_attribute("transform"):
		return process_svg_transform(element.get_named_attribute_value("transform"))
	else:
		return Transform2D.IDENTITY


func process_svg_transform(svg_transform : String) -> Transform2D:
	var transform = Transform2D.IDENTITY
	if svg_transform.begins_with("translate"):
		svg_transform = svg_transform.replace("translate", "").replacen("(", "").replacen(")", "")
		var transform_split = svg_transform.split_floats(",")
		transform[2] = Vector2(transform_split[0], transform_split[1])
	elif svg_transform.begins_with("scale"):
		svg_transform = svg_transform.replace("scale", "").replacen("(", "").replacen(")", "")
		var transform_split = svg_transform.split_floats(",")
		transform = transform.scaled(Vector2(transform_split[0], transform_split[1]))
	elif svg_transform.begins_with("rotate"):
		svg_transform = svg_transform.replace("rotate", "").replacen("(", "").replacen(")", "")
		var transform_split = svg_transform.split_floats(",")
		if transform_split.size() == 1:
			transform = transform.rotated(deg_to_rad(transform_split[0]))
		elif transform_split.size() == 3:
			transform = transform.translated(-Vector2(transform_split[1], transform_split[2]))
			transform = transform.rotated(deg_to_rad(transform_split[0]))
			transform = transform.translated(Vector2(transform_split[1], transform_split[2]))
	elif svg_transform.begins_with("matrix"):
		svg_transform = svg_transform.replace("matrix", "").replacen("(", "").replacen(")", "")
		var matrix = svg_transform.split_floats(",")
		for i in 3:
			transform[i] = Vector2(matrix[i*2], matrix[i*2+1])
	return transform


func get_svg_style(element:XMLParser) -> Dictionary:
	# FXIME: better parsing
	var style = {}
	if element.has_attribute("style"):
		var svg_style = element.get_named_attribute_value("style")
		svg_style = svg_style.rstrip(";")
		svg_style = svg_style.replacen(": ", ":")
		svg_style = svg_style.replacen(":", "\":\"")
		svg_style = svg_style.replacen("; ", "\",\"")
		svg_style = svg_style.replacen(";", "\",\"")
		svg_style = "{\"" + svg_style + "\"}"
		var json = JSON.new()
		var error = json.parse(svg_style)
		if error == OK:
			style = json.data
		else:
			log_message("Failed to parse some styles for <%s id=\"%s\">" % [element.get_node_name(),
					element.get_named_attribute_value("id") if element.has_attribute("id") else "?"], 
					LogLevel.WARN)
	for style_prop in SUPPORTED_STYLES:
		if element.has_attribute(style_prop):
			style[style_prop] = element.get_named_attribute_value(style_prop)
	if not style.is_empty():
		log_message("Parsed style for <%s id=\"%s\">:" % [element.get_node_name(),
					element.get_named_attribute_value("id") if element.has_attribute("id") else "?"],
					LogLevel.DEBUG)
		log_message(str(style), LogLevel.DEBUG)
	return style

static func parse_attribute_string(raw_attribute_str : String) -> String:
	var regex = RegEx.new()
	regex.compile("\\S+")
	var str_path = ""
	for result  in regex.search_all(raw_attribute_str):
		str_path += result.get_string() + " "
	return str_path.strip_edges()
