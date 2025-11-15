extends Node

const STEAM_APP_ID: int = 480

var _networking_stream := LogStream.new("Networking", LogStream.LogLevel.DEBUG)

var networking_enabled: bool = false
var steam_id: int = Steam.getSteamID()
var steam_username: String = Steam.getPersonaName()

func _ready() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx()
	_networking_stream.debug("Raw Steam init response: %s" % initialize_response)
	if initialize_response["status"] > Steam.STEAM_API_INIT_RESULT_OK:
		_networking_stream.error("Steam did not initialize successfully! Networking features will be unavailable!")
		return
	
	
