extends Node

var xr_interface: XRInterface

var xr_stream := LogStream.new("XR", LogStream.LogLevel.DEBUG)

func _ready() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface && xr_interface.is_initialized():
		xr_stream.debug("OpenXR initialized successfully")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
	else:
		xr_stream.error("OpenXR not initialized, please check if your headset is connected.")
