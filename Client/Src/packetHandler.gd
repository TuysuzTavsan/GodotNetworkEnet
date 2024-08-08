extends Resource
class_name PacketHandler

#Any node can subscribe desired packets with protocols. This is to achieve some kind of listening on specific message types.

var m_subscribers : Dictionary = {}

###################################### PUBLIC FUNCTIONS START #####################################

func mForwardPacket(packet : PacketIn) -> bool:
	
	var subscriber = m_subscribers.get(packet.m_msgType)
	
	if(subscriber != null):
		m_subscribers[packet.m_msgType].mHandle(packet)
		Logger.mLogInfo("Forwarding packet to handler...")
		return true
	else:
		Logger.mLogWarning("Unhandled packet received.")
		return false

func mSubscribe(msgType : Msg.Type , subscriber : Node) ->void:
	assert(m_subscribers.get(Msg.Type) == null, "Trying to assign another subscriber to a protocol.")
	m_subscribers[msgType] = subscriber

func mUnSubscribe(msgType : Msg.Type, subscriber : Node) -> void:
	assert(m_subscribers.get(msgType) == subscriber, "Trying to unsubscribe not existing subscriber.")
	m_subscribers.erase(msgType)

###################################### PUBLIC FUNCTIONS END #######################################
