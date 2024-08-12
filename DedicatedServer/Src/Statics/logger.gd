class_name Logger

#Full static class to log output to console. Usefull for debugging.

######################## PUBLIC FUNCTIONS #############################

static func mLogInfo(msg : String) -> void:
	print_rich("[color=green][INFO] ", _mGetTimeString(), msg , "[/color]")

static func mLogWarning(msg : String) -> void:
	print_rich("[color=yellow][WARNING] ", _mGetTimeString(), msg, "[/color]")

static func mLogError(msg : String) -> void:
	print_rich("[color=red][ERROR] ", _mGetTimeString(), msg, "[/color]")

######################## PUBLIC FUNCTIONS #############################


######################## PRIVATE FUNCTIONS #############################

static func _mGetTimeString() -> String:
	return Time.get_time_string_from_system(true) + " "


######################## PRIVATE FUNCTIONS #############################