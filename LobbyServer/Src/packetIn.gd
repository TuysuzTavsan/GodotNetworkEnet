extends RefCounted
class_name PacketIn 

var m_from : Client
var m_data
var m_msgType : Msg.Type

func _init(data : PackedByteArray, from : Client):
	m_from = from
	#Parse packet.
	var packetString  : String = data.get_string_from_ascii()
	var json : JSON = JSON.new()
	var parseResult : int = json.parse(packetString)
	assert(parseResult == OK, "Packet parsing failed. JSON cant parse incoming package.")

	m_msgType = json.data.get("protocol") as Msg.Type
	m_data = json.data.get("data")
