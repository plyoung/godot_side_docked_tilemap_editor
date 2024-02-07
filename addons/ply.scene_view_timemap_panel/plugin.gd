@tool
extends EditorPlugin

const dock_scene = preload("res://addons/ply.scene_view_timemap_panel/dock.tscn")

var dock : SceneViewTileMapDock
var last_screen : String
var tilemap_ed : Node
var tilemap_ed_original_parent : Control

# ----------------------------------------------------------------------------------------------------------------------
#region system

func _enter_tree() -> void:
	main_screen_changed.connect(_on_main_screen_changed)
	EditorInterface.get_selection().selection_changed.connect(_on_editor_selection_changed)

	dock = dock_scene.instantiate() as SceneViewTileMapDock
	dock.visible = false

	var viewport := EditorInterface.get_editor_viewport_2d()
	var container := _get_first_node_by_class(viewport.get_parent().get_parent(), "CanvasItemEditorViewport")
	container.add_child(dock)
	container.move_child(dock, 0)

	tilemap_ed = _get_first_node_by_class(EditorInterface.get_base_control(), "TileMapEditor")
	if tilemap_ed:
		tilemap_ed_original_parent = tilemap_ed.get_parent() as Control
		var tilemap := _get_selected_tilemap_or_null()
		dock.setup(tilemap_ed, tilemap_ed_original_parent, tilemap)
	else:
		printerr("Could not find TileMapEditor node");


func _exit_tree() -> void:
	main_screen_changed.disconnect(_on_main_screen_changed)
	EditorInterface.get_selection().selection_changed.disconnect(_on_editor_selection_changed)
	if dock: dock.queue_free()


func _ready() -> void:
	# todo: https://github.com/godotengine/godot-proposals/issues/2081
	EditorInterface.set_main_screen_editor("Script")
	EditorInterface.set_main_screen_editor("2D")


func _disable_plugin() -> void:
	if dock:
		dock.dispose()
	if tilemap_ed and tilemap_ed_original_parent:
		tilemap_ed.reparent(tilemap_ed_original_parent, false)
		tilemap_ed_original_parent.move_child(tilemap_ed, 0)


#endregion
# ----------------------------------------------------------------------------------------------------------------------
#region callbacks

func _on_main_screen_changed(screen_name: String) -> void:
	last_screen = screen_name
	_on_editor_selection_changed()


func _on_editor_selection_changed() -> void:
	var tilemap := _get_selected_tilemap_or_null()
	dock.tilemap_selected(tilemap, last_screen == "2D")


#endregion
# ----------------------------------------------------------------------------------------------------------------------
#region helpers

func _get_selected_tilemap_or_null() -> TileMap:
	var nodes := EditorInterface.get_selection().get_selected_nodes()
	for node in nodes:
		if node is TileMap:
			return node as TileMap
	return null


func _get_first_node_by_class(parent_node : Node, target_class_name : String) -> Node:
	var nodes := parent_node.find_children("*", target_class_name, true, false)
	if !nodes.size(): return null
	return nodes[0]


func _print_layout_direct_children(base: Node) -> void:
	print("%s > %s" % [base.get_class(), base.name])
	var nodes := base.get_children()
	for node in nodes:
		var control = node as Control
		if control:
			var text : String = control.text if control is Label else control.tooltip_text
			print("\t%s > %s (%s) - %s" % [control.get_class(), control.name, control.visible,  text])
		else:
			print("\t%s > %s" % [node.get_class(), node.name])


func _print_layout(base: Node, indent: String, containers_only : bool = true) -> void:
	var nodes := base.get_children()
	for node in nodes:
		if containers_only:
			var control = node as Container
			if control:
				print("%s %s > %s (%s)" % [indent, control.get_class(), control.name, control.visible])
				_print_layout(node, indent + "\t", containers_only)
		else:
			var control = node as Control
			if control:
				var text : String = control.text if control is Label else control.tooltip_text
				var size := "" #Rect2(control.global_position, control.size)
				print("%s %s > %s (%s) (%s) - %s" % [indent, control.get_class(), control.name, control.visible, size, text])
			else:
				print("%s %s > %s" % [indent, node.get_class(), node.name])
			_print_layout(node, indent + "\t", containers_only)


#endregion
# ----------------------------------------------------------------------------------------------------------------------
