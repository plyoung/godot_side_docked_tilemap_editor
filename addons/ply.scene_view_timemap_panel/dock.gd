@tool
class_name SceneViewTileMapDock
extends MarginContainer

const min_panel_width: float = 600
const main_margins := Vector4i(5, 5, 0, 10)
const container_margins := Vector4i(5, 30, 10, 5)
const resize_button_width := 4
const save_data_section := "addons"
const save_data_panel_width := "scene_view_timemap_panel_width"

@onready var panel: Control = %Panel
@onready var margin_container: Control = %MarginContainer
@onready var editor_container: Control = %EditorContainer
@onready var resize_button: Button = %ResizeButton

var editor_scale: float
var tilemap_ed: Control
var bottom_dock: Control
var bottom_dock_button_bar: Control
var selected_tilemap: TileMap
var bottom_dock_tilemap_button: Button
var resizing: bool
var initial_mouse_position: Vector2
var initial_panel_size: Vector2

# ----------------------------------------------------------------------------------------------------------------------
#region system

func _ready() -> void:
	editor_scale = EditorInterface.get_editor_scale()

	var margins := main_margins * editor_scale
	add_theme_constant_override("margin_left", margins.x)
	add_theme_constant_override("margin_top", margins.y)
	add_theme_constant_override("margin_right", margins.z)
	add_theme_constant_override("margin_bottom", margins.w)

	margins = container_margins * editor_scale
	margin_container.add_theme_constant_override("margin_left", margins.x)
	margin_container.add_theme_constant_override("margin_top", margins.y)
	margin_container.add_theme_constant_override("margin_right", margins.z)
	margin_container.add_theme_constant_override("margin_bottom", margins.w)

	await get_tree().process_frame

	var ed_settings := EditorInterface.get_editor_settings()
	self.size.x = ed_settings.get_project_metadata(save_data_section, save_data_panel_width, min_panel_width * editor_scale)

	resize_button.button_down.connect(_on_resize_button_down)
	resize_button.button_up.connect(_on_resize_button_up)
	resize_button.size = Vector2(resize_button_width * editor_scale, resize_button.size.y)
	resize_button.position = Vector2(panel.size.x - resize_button.size.x, 0)
	resize_button.set_anchors_preset(Control.PRESET_RIGHT_WIDE)


func _process(_delta: float) -> void:
	if not visible: return
	if resizing: _process_resizing()


func setup(tilemap_ed : Control, bottom_dock: Control, selected_tilemap : TileMap) -> void:
	self.tilemap_ed = tilemap_ed
	self.bottom_dock = bottom_dock
	self.bottom_dock_button_bar = bottom_dock.get_children().back()
	self.selected_tilemap = selected_tilemap
	tilemap_ed.reparent(editor_container, false)
	bottom_dock.resized.connect(_on_bottom_dock_resized)
	# assume the TileMap button is 12th. Could search by text but then will not work for non-english
	var button_bar_buttons := bottom_dock.get_children().back().get_child(0) as Node
	bottom_dock_tilemap_button = button_bar_buttons.get_child(12) as Button
	bottom_dock_tilemap_button.pressed.connect(_on_tilemap_dock_button_pressed)
	bottom_dock_tilemap_button.toggled.connect(_on_tilemap_dock_button_toggled)
	if tilemap_ed and selected_tilemap:
		bottom_dock_tilemap_button.button_pressed = false
		tilemap_ed.visible = true


func dispose() -> void:
	selected_tilemap = null
	if bottom_dock:
		bottom_dock.resized.disconnect(_on_bottom_dock_resized)
	if bottom_dock_tilemap_button:
		bottom_dock_tilemap_button.button_pressed = false
		bottom_dock_tilemap_button.pressed.disconnect(_on_tilemap_dock_button_pressed)
		bottom_dock_tilemap_button.toggled.disconnect(_on_tilemap_dock_button_toggled)
	if tilemap_ed:
		tilemap_ed.visible = false
		tilemap_ed = null

#endregion
# ----------------------------------------------------------------------------------------------------------------------
#region callbackspub

func _on_bottom_dock_resized() -> void:
	tilemap_ed.visible = selected_tilemap and self.visible


func _on_tilemap_dock_button_pressed() -> void:
	pass


func _on_tilemap_dock_button_toggled(on : bool) -> void:
	await get_tree().process_frame
	bottom_dock_tilemap_button.button_pressed = false
	tilemap_ed.visible = selected_tilemap and self.visible


#endregion
# ----------------------------------------------------------------------------------------------------------------------
#region resizing

func _on_resize_button_down() -> void:
	if resizing: return
	resizing = true
	initial_mouse_position = get_global_mouse_position()
	initial_panel_size = self.size


func _on_resize_button_up() -> void:
	resizing = false
	var ed_settings := EditorInterface.get_editor_settings()
	ed_settings.set_project_metadata(save_data_section, save_data_panel_width, self.size.x)

func _process_resizing() -> void:
	var viewport_size :=  EditorInterface.get_editor_main_screen().size
	var delta_mouse_position := initial_mouse_position - get_global_mouse_position()
	var resize := initial_panel_size - delta_mouse_position
	resize.x = clamp(resize.x, min_panel_width, viewport_size.x - (10 * editor_scale))
	resize.y = self.size.y
	self.size = resize


#endregion
# ----------------------------------------------------------------------------------------------------------------------
#region pub

func tilemap_selected(tilemap: TileMap, in_2d_view: bool) -> void:
	selected_tilemap = tilemap
	if not in_2d_view or not tilemap or not tilemap_ed:
		hide()
	else:
		tilemap_ed.visible = true
		show()


#endregion
# ----------------------------------------------------------------------------------------------------------------------
