extends Node

signal focus_lost
signal focus_gained 
signal pose_recentered

@export var max_refresh_rate: int = 144


var xr_interface: OpenXRInterface
var xr_is_focused: bool = false
var viewport: Viewport
var environment: Environment ## Must be set by another node

var _stream := LogStream.new("XR", LogStream.LogLevel.DEBUG)

func _ready() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if !xr_interface || !xr_interface.is_initialized():
		_stream.error("OpenXR not initialized, please check if your headset is connected.")
		return
	viewport = get_viewport()
	viewport.use_xr = true
	
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	if RenderingServer.get_rendering_device():
		viewport.vrs_mode = Viewport.VRS_XR
	elif int(ProjectSettings.get_setting("xr/openxr/foveation_level")) == 0:
		_stream.warn("It is recommended to set foveation level to high in Project Settings.")
	
	xr_interface.session_begun.connect(_on_openxr_session_begun)
	xr_interface.session_visible.connect(_on_openxr_visible_state)
	xr_interface.session_focussed.connect(_on_openxr_focused_state)
	xr_interface.session_stopping.connect(_on_openxr_stopping)
	xr_interface.pose_recentered.connect(_on_openxr_pose_recentered)
	
	_stream.debug("OpenXR initialized successfully")

func switch_to_ar() -> bool:
	if !environment:
		_stream.warn("No environment node is set on XR singleton")
		return false
	if xr_interface:
		var modes: Array = xr_interface.get_supported_environment_blend_modes()
		if XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND in modes:
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND
			viewport.transparent_bg = true
		elif XRInterface.XR_ENV_BLEND_MODE_ADDITIVE in modes:
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_ADDITIVE
			viewport.transparent_bg = false
	else:
		return false

	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.0, 0.0, 0.0, 0.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	return true

func switch_to_vr() -> bool:
	if !environment:
		_stream.warn("No environment node is set on XR singleton")
		return false
	if xr_interface:
		var modes: Array = xr_interface.get_supported_environment_blend_modes()
		if XRInterface.XR_ENV_BLEND_MODE_OPAQUE in modes:
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_OPAQUE
		else:
			return false

	viewport.transparent_bg = false
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_BG
	return true

func _on_openxr_session_begun() -> void:
	var current_refresh_rate: int = int(xr_interface.display_refresh_rate)
	if current_refresh_rate > 0:
		_stream.debug("Refresh rate reported as %s" % current_refresh_rate)
	else:
		_stream.warn("No refresh rate given by XR runtime")
	
	var new_rate: int = current_refresh_rate
	var available_rates: Array = xr_interface.get_available_display_refresh_rates()
	if available_rates.size() == 0:
		_stream.warn("XR target does not support refresh rate extension")
	elif available_rates.size() == 1:
		new_rate = available_rates[0]
	else:
		for rate: int in available_rates:
			if rate > new_rate && rate <= max_refresh_rate:
				new_rate = rate
	
	if current_refresh_rate != new_rate:
		_stream.debug("Setting refresh rate to %s" % new_rate)
		xr_interface.set_display_refresh_rate(new_rate)
		current_refresh_rate = new_rate
	
	_stream.debug("Setting physics engine TPS to %s" % 240)
	Engine.physics_ticks_per_second = 240

func _on_openxr_visible_state() -> void:
	if xr_is_focused:
		_stream.debug("Lost focus")
		xr_is_focused = false
		get_tree().paused = true
		focus_lost.emit()

func _on_openxr_focused_state() -> void:
	_stream.debug("Gained focus")
	xr_is_focused = true
	get_tree().paused = false
	focus_gained.emit()

func _on_openxr_stopping() -> void:
	_stream.warn("OpenXR is stopping")

func _on_openxr_pose_recentered() -> void:
	pose_recentered.emit()
