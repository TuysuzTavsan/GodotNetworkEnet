extends Node
class_name Server

#Singleton class that will manage important networking features.

var m_port  : int = -1
var m_address : String = ""

func _ready() -> void:
	var arguments = {}
	for argument in OS.get_cmdline_user_args():
		if argument.find("="):
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			arguments[argument.lstrip("--")] = ""

	
	m_port = arguments.get("port")
	m_address = arguments.get("address")
	
	if(not m_port):
		Logger.mLogError("Cant find start argument --port. Aborting application.")
		get_tree().quit(-1)

	if(not m_address):
		Logger.mLogError("Cant find start argument --address. Aborting application.")
		get_tree().quit(-1)
