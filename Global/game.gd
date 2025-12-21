extends Node

@export_category("Settings")
@export var names : Array[String]


@onready var main_menu = $Menu
@onready var address_entry = %Address
@onready var nickname = %Nickname_

const player_scene = preload("res://chars/player.tscn")

@onready var world = $World
@onready var players_spawn = $World/Players

var PORT = 25565
var enet_peer = ENetMultiplayerPeer.new()

func _ready():
	if OS.has_feature("dedicated_server"): host_own(); return; #if server
	
	print("Game (Client)")
	
	

func host_own():
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	@warning_ignore("int_as_enum_without_cast", "int_as_enum_without_match")
	var adr = str(IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)) + ", " + str(PORT)
	print("Server: \n" + adr)
	

func disconnect_enet():
	if multiplayer.multiplayer_peer: multiplayer.multiplayer_peer.close();
	multiplayer.multiplayer_peer = null
	get_tree().reload_current_scene()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("pause"):
		disconnect_enet()

#func upnp_setup():
	#var upnp = UPNP.new()
	#
	#var discover_result = upnp.discover()
	#assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		#"UPNP Discover Failed! Error %s" % discover_result)
	#
	#assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		#"UPNP Invalid Getaway!")
	#
	#var map_result = upnp.add_port_mapping(PORT)
	#assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		#"UPNP Port Mapping Failed! Error %s" % map_result)
	#
	#print("join: %s" % upnp.query_external_address())

func _on_host_pressed():
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	@warning_ignore("int_as_enum_without_cast", "int_as_enum_without_match")
	var adr = str(IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)) + ", " + str(PORT)
	print("Hosting: " + adr)
	
	
	start_client()
	
	add_player(multiplayer.get_unique_id())
	


func _on_join_pressed():
	var ip = address_entry.text
	if !ip: ip = address_entry.placeholder_text
	enet_peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	await multiplayer.connected_to_server
	
	
	start_client()

func start_client():
	
	var nick = check_legal_nick(nickname.text)
	Global_Self.nickname = nick
	print(nick + " has joined!")
	
	main_menu.hide()

func check_legal_nick(n):
	var an = n
	#check
	if !n:
		#an = "No Nick"
		an = names.pick_random()
	
	return an

func add_player(peer_id):
	var player = player_scene.instantiate()
	player.name = str(peer_id)
	players_spawn.add_child(player)

func remove_player(peer_id):
	
	var i = players_spawn.get_node_or_null(str(peer_id))
	if i: i.queue_free()
