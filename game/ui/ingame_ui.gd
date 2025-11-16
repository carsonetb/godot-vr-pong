class_name IngameUI
extends CanvasLayer

@onready var singleplayer_button: Button = $MarginContainer/MainMenuUI/VSplitContainer/HSplitContainer/SingleplayerButton
@onready var multiplayer_button: Button = $MarginContainer/MainMenuUI/VSplitContainer/HSplitContainer/MultiplayerButton
@onready var main_menu_container: Container = $MarginContainer/MainMenuUI
@onready var lobby_list_container: Container = $MarginContainer/LobbyList
@onready var lobby_list_vbox: VBoxContainer = $MarginContainer/LobbyList/ListContainer
@onready var members_list_container: Container = $MarginContainer/MembersList
@onready var members_list_vbox: VBoxContainer = $MarginContainer/MembersList/VBoxContainer/ListContainer
@onready var lobby_name_label: Label = $MarginContainer/MembersList/VBoxContainer/LobbyNameLabel
@onready var leave_lobby_button: Button = $MarginContainer/MembersList/VBoxContainer/LeaveLobbyButton

var _stream: LogStream = LogStream.new("UI", LogStream.LogLevel.DEBUG)

enum MenuState {
	MAIN_MENU,
	LOBBY_LIST,
	MEMBERS_LIST,
}
var state: MenuState = MenuState.MAIN_MENU

func _ready() -> void:
	Networking.lobby_match_list.connect(_on_lobby_match_list)
	Networking.member_list_updated.connect(_on_member_list_updated)
	multiplayer_button.pressed.connect(_on_multiplayer_button_pressed)
	leave_lobby_button.pressed.connect(_on_leave_lobby_button_pressed)

func _process(_delta: float) -> void:
	if state == MenuState.MAIN_MENU:
		main_menu_container.visible = true
		lobby_list_container.visible = false
		members_list_container.visible = false
	if state == MenuState.LOBBY_LIST:
		main_menu_container.visible = false
		lobby_list_container.visible = true
		members_list_container.visible = false
	if state == MenuState.MEMBERS_LIST:
		main_menu_container.visible = false
		lobby_list_container.visible = false
		members_list_container.visible = true

func _on_lobby_match_list(lobbies: Array[Networking.LobbyInfo]) -> void:
	_stream.debug("Got lobby list, displaying")
	state = MenuState.LOBBY_LIST
	
	for child in lobby_list_vbox.get_children():
		child.queue_free()
	
	var header_label: Label = Label.new()
	header_label.text = "Lobby List: "
	lobby_list_vbox.add_child(header_label)
	
	for lobby in lobbies:
		var entry: HBoxContainer = HBoxContainer.new()
		var name_label: Label = Label.new()
		var num_members_label: Label = Label.new()
		var join_button: Button = Button.new()
		name_label.text = lobby.lobby_name
		num_members_label.text = "Members: %s" % lobby.num_members
		join_button.text = "Join"
		join_button.pressed.connect(_on_lobby_join_button_pressed.bind(lobby.id))
		entry.add_child(name_label)
		entry.add_child(num_members_label)
		entry.add_child(join_button)
		lobby_list_container.add_child(entry)
		
	var create_lobby_button: Button = Button.new()
	create_lobby_button.text = "Create Lobby"
	create_lobby_button.pressed.connect(_on_create_lobby_button_pressed)
	lobby_list_vbox.add_child(create_lobby_button)
	
	var reload_lobbies_button: Button = Button.new()
	reload_lobbies_button.text = "Reload"
	reload_lobbies_button.pressed.connect(_on_reload_lobbies_button_pressed)
	lobby_list_vbox.add_child(reload_lobbies_button)

func _on_lobby_joined() -> void:
	_stream.debug("Lobby joined, switching to members list")
	state = MenuState.MEMBERS_LIST
	lobby_name_label.text = "Lobby Name: %s" % Networking.lobby_data

func _on_member_list_updated(list: Array[Networking.LobbyMember]) -> void:
	_stream.debug("Member list updated, reloading UI")
	state = MenuState.MEMBERS_LIST
	
	for child in members_list_vbox.get_children():
		child.queue_free()
	
	lobby_name_label.text = "Name: %s" % Networking.lobby_data.lobby_name
	
	for member in list:
		var name_label: Label = Label.new()
		name_label.text = "Member: %s" % member.member_name
		members_list_vbox.add_child(name_label)

func _on_multiplayer_button_pressed() -> void:
	_stream.debug("Multiplayer button pressed, begin networking")
	Networking.begin_networking()

func _on_lobby_join_button_pressed(id: int) -> void:
	_stream.debug("Requested to join lobby id %s" % id)
	Networking.join_lobby(id)

func _on_create_lobby_button_pressed() -> void:
	_stream.debug("Requested to create a lobby")
	Networking.create_lobby()

func _on_reload_lobbies_button_pressed() -> void:
	_stream.debug("Reloading lobbies list")
	Networking.request_lobbies()

func _on_leave_lobby_button_pressed() -> void:
	_stream.debug("Requested to leave lobby")
	# TODO: Do this
