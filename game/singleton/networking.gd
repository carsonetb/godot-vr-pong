extends Node

signal lobby_match_list(lobbies: Array[LobbyInfo])
signal lobby_joined()
signal member_list_updated(list: Array[LobbyMember])

const STEAM_APP_ID: int = 480
const PACKET_READ_LIMIT: int = 32
const LOBBY_NAME: String = "Ping Pong Test"
const LOBBY_MODE: String = "Default"

var _networking_stream := LogStream.new("Networking", LogStream.LogLevel.DEBUG)

var networking_enabled: bool = false
var lobby_data: LobbyInfo
var lobby_id: int = 0
var lobby_members: Array[LobbyMember]
var lobby_members_max: int = 10
var lobby_vote_kick: bool = false
var is_lobby_owner: bool = false
var steam_id: int
var steam_username: String

func begin_networking() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx()
	_networking_stream.debug("Raw Steam init response: %s" % initialize_response)
	if initialize_response["status"] > Steam.STEAM_API_INIT_RESULT_OK:
		_networking_stream.error("Steam did not initialize successfully! Networking features will be unavailable!")
		return
	
	steam_id = Steam.getSteamID()
	steam_username = Steam.getFriendPersonaName(steam_id)
	
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.persona_state_change.connect(_on_persona_change)
	Steam.p2p_session_request.connect(_on_p2p_session_request)
	Steam.p2p_session_connect_fail.connect(_on_p2p_session_connect_fail)
	Steam.lobby_joined.connect(_on_lobby_joined)
	
	check_command_line()
	
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	
	_networking_stream.debug("Requesting lobby list")
	request_lobbies()
	
	networking_enabled = true
	_networking_stream.info("Networking setup complete and successful")

func _process(_delta: float) -> void:
	Steam.run_callbacks()
	
	if lobby_id > 0:
		read_all_p2p_packets()

func request_lobbies() -> void:
	Steam.requestLobbyList()

func read_all_p2p_packets(read_count: int = 0) -> void:
	if read_count >= PACKET_READ_LIMIT:
		return
	
	if Steam.getAvailableP2PPacketSize(0) > 0:
		read_p2p_packet()
		read_all_p2p_packets(read_count + 1)

func read_p2p_packet() -> void:
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)
	
	if packet_size > 0:
		var this_packet: Dictionary = Steam.readP2PPacket(packet_size, 0)
		
		if this_packet.is_empty() or this_packet == null:
			_networking_stream.warn("Read an empty packet with non-zero size!")
		
		var packet_sender: int = this_packet["remote_steam_id"]
		var packet_code: PackedByteArray = this_packet["data"]
		var readable_data: Dictionary = bytes_to_var(packet_code.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))
		
		if readable_data["message"] == "handshake":
			_networking_stream.info("Handshake from %s" % Steam.getFriendPersonaName(packet_sender))
		if readable_data["message"] == "set_variable":
			get_node(readable_data["path"]).set(readable_data["varname"], readable_data["value"])
		if readable_data["message"] == "call_function":
			get_node(readable_data["path"]).callv(readable_data["name"], readable_data["args"])

func set_remote_variable(node: Node, varname: String) -> void:
	send_p2p_packet(0, {"message": "set_variable", "path": node.get_path(), "varname": varname, "value": node.get(varname)})

func call_remote_function(node: Node, function: String, args: Array) -> void:
	send_p2p_packet(0, {"message": "call_function", "path": node.get_path(), "name": function, "args": args})

func send_p2p_packet(this_target: int, packet_data: Dictionary) -> void:
	var send_type: int = Steam.P2P_SEND_RELIABLE
	var channel: int = 0
	
	var this_data: PackedByteArray
	this_data.append_array(var_to_bytes(packet_data).compress(FileAccess.COMPRESSION_GZIP))
	
	if this_target == 0:
		if lobby_members.size() > 1:
			for member in lobby_members:
				if member.id != steam_id:
					Steam.sendP2PPacket(member.id, this_data, send_type, channel)
	else:
		Steam.sendP2PPacket(this_target, this_data, send_type, channel)

func check_command_line() -> void:
	var these_arguments: Array = OS.get_cmdline_args()
	
	if these_arguments.size() > 0:
		if these_arguments[0] == "+connect_lobby":
			if int(these_arguments[1]) > 0:
				_networking_stream.debug("Command line lobby ID: %s" % these_arguments[1])
				join_lobby(int(these_arguments[1]))

func create_lobby() -> void:
	if lobby_id == 0:
		is_lobby_owner = true
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, lobby_members_max)

func join_lobby(this_lobby_id: int) -> void:
	is_lobby_owner = false
	_networking_stream.debug("Attempting to join lobby %s" % this_lobby_id)
	lobby_members.clear()
	Steam.joinLobby(this_lobby_id)

func get_lobby_members() -> void:
	lobby_members.clear()

	var num_of_members: int = Steam.getNumLobbyMembers(lobby_id)
	for this_member in range(0, num_of_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		
		lobby_members.append(LobbyMember.new(member_steam_id, member_steam_name))
	
	member_list_updated.emit(lobby_members)

func make_p2p_handshake() -> void:
	_networking_stream.debug("Sending P2P handshake to the lobby")
	send_p2p_packet(0, {"message": "handshake", "from": steam_id})

func _on_lobby_created(connect_response: int, this_lobby_id: int) -> void:
	if connect_response == 1:
		lobby_id = this_lobby_id
		_networking_stream.info("Created a lobby: %s" % lobby_id)
		
		Steam.setLobbyJoinable(lobby_id, true)
		Steam.setLobbyData(lobby_id, "name", "%s's lobby" % steam_username)
		Steam.setLobbyData(lobby_id, "mode", LOBBY_MODE)
		
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		_networking_stream.debug("Allowing Steam to be relay backup: %s" % set_relay)

func _on_lobby_match_list(these_lobbies: Array) -> void:
	var out: Array[LobbyInfo]
	for lobby: int in these_lobbies:
		var lobby_name: String = Steam.getLobbyData(lobby, "name")
		var lobby_mode: String = Steam.getLobbyData(lobby, "mode")
		var num_members: int = Steam.getNumLobbyMembers(lobby)
		if lobby_mode == LOBBY_MODE:
			out.append(LobbyInfo.new(lobby, lobby_name, num_members))
			
	lobby_match_list.emit(out)

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		lobby_data = LobbyInfo.new(lobby_id, Steam.getLobbyData(lobby_id, "name"), Steam.getNumLobbyMembers(lobby_id))
		
		get_lobby_members()
		make_p2p_handshake()
		
		lobby_joined.emit()
	else:
		var fail_reason: String
		
		match response:
			Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: fail_reason = "This lobby no longer exists."
			Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: fail_reason = "You don't have permission to join this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: fail_reason = "The lobby is now full."
			Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: fail_reason = "Uh... something unexpected happened!"
			Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: fail_reason = "You are banned from this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: fail_reason = "You cannot join due to having a limited account."
			Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: fail_reason = "This lobby is locked or disabled."
			Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: fail_reason = "This lobby is community locked."
			Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: fail_reason = "A user in the lobby has blocked you from joining."
			Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: fail_reason = "A user you have blocked is in the lobby."
		
		_networking_stream.error("Failed to join this lobby: %s" % fail_reason)

func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
	var owner_name: String = Steam.getFriendPersonaName(friend_id)
	_networking_stream.debug("Joining %s's lobby" % owner_name)
	join_lobby(this_lobby_id)

func _on_persona_change(this_steam_id: int, _flag: int) -> void:
	if lobby_id > 0:
		_networking_stream.debug("A user (%s) had information change, update the lobby list" % Steam.getFriendPersonaName(this_steam_id))
		get_lobby_members()

func _on_lobby_chat_update(_this_lobby_id: int, change_id: int, _making_change_id: int, chat_state: int) -> void:
	var changer_name: String = Steam.getFriendPersonaName(change_id)

	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		_networking_stream.info("%s has joined the lobby." % changer_name)
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		_networking_stream.info("%s has left the lobby." % changer_name)
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		_networking_stream.info("%s has been kicked from the lobby." % changer_name)
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		_networking_stream.info("%s has been banned from the lobby." % changer_name)
	else:
		_networking_stream.info("%s did... something." % changer_name)

	get_lobby_members()

func _on_p2p_session_request(remote_id: int) -> void:
	var this_requester: String = Steam.getFriendPersonaName(remote_id)
	_networking_stream.debug("%s is requesting a P2P session" % this_requester)
	
	Steam.acceptP2PSessionWithUser(remote_id)
	make_p2p_handshake()

func _on_p2p_session_connect_fail(this_steam_id: int, session_error: int) -> void:
	if session_error == 0:
		print("WARNING: Session failure with %s: no error given" % this_steam_id)
	elif session_error == 1:
		print("WARNING: Session failure with %s: target user not running the same game" % this_steam_id)
	elif session_error == 2:
		print("WARNING: Session failure with %s: local user doesn't own app / game" % this_steam_id)
	elif session_error == 3:
		print("WARNING: Session failure with %s: target user isn't connected to Steam" % this_steam_id)
	elif session_error == 4:
		print("WARNING: Session failure with %s: connection timed out" % this_steam_id)
	elif session_error == 5:
		print("WARNING: Session failure with %s: unused" % this_steam_id)
	else:
		print("WARNING: Session failure with %s: unknown error %s" % [this_steam_id, session_error])

class LobbyInfo:
	func _init(p_id: int, p_lobby_name: String, p_num_members: int) -> void:
		id = p_id
		lobby_name = p_lobby_name
		num_members = p_num_members
	
	var id: int
	var lobby_name: String
	var num_members: int

class LobbyMember:
	func _init(p_id: int, p_member_name: String) -> void:
		id = p_id
		member_name = p_member_name
	
	var id: int
	var member_name: String
