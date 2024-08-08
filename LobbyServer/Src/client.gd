extends RefCounted
class_name Client

#ENetPacketPeer wrapper to use for clients.

var m_eNetPeer : ENetPacketPeer
var m_userName : String = ""
const M_DEFAULT_CHANNEl : int = 0

func _init(peer : ENetPacketPeer):
	m_eNetPeer = peer

############################################# PUBLIC FUNCTIONS #############################################

#Data is a VARIANT! we can send any data type we want.
func mSendMsg(type : Msg.Type, data):
	var arrayToSend : PackedByteArray = JSON.stringify({"protocol" : int(type), "data" : data}).to_utf8_buffer()

	var result : int = m_eNetPeer.send(M_DEFAULT_CHANNEl, arrayToSend, ENetPacketPeer.FLAG_RELIABLE)

	if(result == 0):
		Logger.mLogInfo("Packet sent successfully to user: " + m_userName + ".")
	else:
		Logger.mLogError("Cant send packet to user: " + m_userName + ".")

############################################# PUBLIC FUNCTIONS #############################################
