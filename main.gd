class_name Main
extends Node3D

var xr_interface: XRInterface

func _ready() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface && xr_interface.is_initialized():
		print("OpenXR initialized successfully")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
		
		if xr_interface.is_passthrough_supported():
			print("Passthrough is supported, starting")
			xr_interface.start_passthrough()
		else:
			var modes: Array = xr_interface.get_supported_environment_blend_modes()
			if xr_interface.XR_ENV_BLEND_MODE_ALPHA_BLEND in modes:
				xr_interface.environment_blend_mode = xr_interface.XR_ENV_BLEND_MODE_ALPHA_BLEND
	else:
		print("OpenXR not initialized, please check if your headset is connected.")
	get_viewport().transparent_bg = true
