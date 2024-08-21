extends Camera2D


func _ready() -> void:
	var netType : Net.Type = Net.mGetNetworkType(self)
	if(netType != Net.Type.LOCAL):
		queue_free()
		return
	
	#This camera belongs to localPlayer.
	enabled = true