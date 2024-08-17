class_name Net

#enum class to hold network type of a node and access later.
#Will improve code readability.

enum Type {
	UNSPECIFIED = 0,
	SERVER = 1,
	LOCAL = 2,
	PUPPET = 3
}

static func mGetNetworkType(node : Node) -> Type:
	if(node.multiplayer.is_server()):
		#This node is in server.
		return Net.Type.SERVER

	if(node.get_tree().get_multiplayer().get_unique_id() == node.multiplayer.get_unique_id()):
		#This node is local player.
		return Net.Type.LOCAL

	return Net.Type.PUPPET
