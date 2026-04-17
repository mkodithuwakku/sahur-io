extends RefCounted
class_name TestSuite

var test_root: Node = null
var assertion_count: int = 0
var _current_failures: Array[String] = []
var _temp_nodes: Array[Node] = []

func suite_name() -> String:
	return get_script().resource_path.get_file().trim_suffix(".gd")

func setup_suite() -> void:
	pass

func teardown_suite() -> void:
	_cleanup_temp_nodes()

func before_each() -> void:
	pass

func after_each() -> void:
	_cleanup_temp_nodes()

func run_suite() -> Array:
	var results: Array = []
	setup_suite()
	var method_names: Array[String] = []
	for method_info in get_method_list():
		var method_name: String = method_info.name
		if method_name.begins_with("test_"):
			method_names.append(method_name)
	method_names.sort()
	for method_name in method_names:
		_current_failures = []
		var assertions_before: int = assertion_count
		before_each()
		call(method_name)
		after_each()
		results.append({
			"name": method_name,
			"assertions": assertion_count - assertions_before,
			"passed": _current_failures.is_empty(),
			"failures": _current_failures.duplicate()
		})
	teardown_suite()
	return results

func track_temp_node(node: Node, add_to_tree: bool = false) -> Node:
	_temp_nodes.append(node)
	if add_to_tree and test_root != null and node.get_parent() == null:
		test_root.add_child(node)
	return node

func assert_true(condition: bool, message: String = "Expected condition to be true") -> void:
	assertion_count += 1
	if not condition:
		_current_failures.append(message)

func assert_false(condition: bool, message: String = "Expected condition to be false") -> void:
	assertion_count += 1
	if condition:
		_current_failures.append(message)

func assert_equal(expected, actual, message: String = "") -> void:
	assertion_count += 1
	if expected != actual:
		if message.is_empty():
			message = "Expected %s, got %s" % [str(expected), str(actual)]
		_current_failures.append(message)

func assert_near(expected: float, actual: float, tolerance: float = 0.001, message: String = "") -> void:
	assertion_count += 1
	if absf(expected - actual) > tolerance:
		if message.is_empty():
			message = "Expected %.4f, got %.4f" % [expected, actual]
		_current_failures.append(message)

func assert_vector3_near(expected: Vector3, actual: Vector3, tolerance: float = 0.001, message: String = "") -> void:
	assertion_count += 1
	if expected.distance_to(actual) > tolerance:
		if message.is_empty():
			message = "Expected %s, got %s" % [str(expected), str(actual)]
		_current_failures.append(message)

func _cleanup_temp_nodes() -> void:
	for node in _temp_nodes:
		if is_instance_valid(node):
			node.free()
	_temp_nodes.clear()
