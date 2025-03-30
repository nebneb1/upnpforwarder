extends Control

@onready var text_edit: TextEdit = $VBoxContainer/TextEdit
@onready var start: Button = $VBoxContainer/start
@onready var stop: Button = $VBoxContainer/stop
@onready var rich_text_label: RichTextLabel = $VBoxContainer/RichTextLabel

var port = 25565
var identifier = "upnp_forwarder"
var open = false

var upnp = UPNP.new()
func setup_upnp():
	open = true
	var discover_result = upnp.discover()
	if discover_result == UPNP.UPNP_RESULT_SUCCESS:
		if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
			var map_result_udp = upnp.add_port_mapping(port, 0, identifier + "_UDP", "UDP", 0)
			var map_result_tcp = upnp.add_port_mapping(port, 0, identifier + "_TCP", "TCP", 0)
			
			if map_result_udp != UPNP.UPNP_RESULT_SUCCESS:
				map_result_udp = upnp.add_port_mapping(port, 0, "", "UDP")
			if map_result_tcp != UPNP.UPNP_RESULT_SUCCESS:
				map_result_tcp = upnp.add_port_mapping(port, 0, "", "TCP")
			
			if map_result_tcp != UPNP.UPNP_RESULT_SUCCESS or map_result_udp != UPNP.UPNP_RESULT_SUCCESS:
				push("UPNP setup failed with error codes " + str(map_result_tcp) + ", " + str(map_result_udp))
				open = false
			
		else:
			push("UPNP setup failed")
			open = false
	
	else: 
		push("UPNP discovery failure")
		open = false
	
	if open:
		push("UPNP setup sucess, port " + str(port) + " forwarded")
		stop.show()
	else:
		stop.hide()

func push(msg):
	rich_text_label.text = msg

func _on_start_pressed() -> void:
	port = int(text_edit.text)
	setup_upnp()

func _on_stop_pressed() -> void:
	close_ports()

func close_ports():
	if open:
		var sucess = [upnp.delete_port_mapping(port, "UDP"), upnp.delete_port_mapping(port, "TCP")]
		if sucess[0] == UPNP.UPNP_RESULT_SUCCESS and sucess[1] == UPNP.UPNP_RESULT_SUCCESS: 
			push("Port closing on " + str(port) + " successful")
			open = false
			stop.hide()
		else: 
			push("Port closing unsuccessful")


var quitting = false
func _notification(what: int):
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not quitting:
		quitting = true
		close_ports()
		await get_tree().create_timer(2.0).timeout # make sure that everything goes through, should be near immediate but better safe than sorry !
		get_tree().quit()
