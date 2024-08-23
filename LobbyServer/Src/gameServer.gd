extends Node
class_name GameServer

#Simple node with timer to see which ports are available.

var m_port : int = -1

signal _m_GameServerFree(gameServer : GameServer)

func _on_timer_timeout() -> void:
	_m_GameServerFree.emit(self)
	queue_free()
