extends Resource
class_name InputContainer

#simple struct to hold input together to represent a frame.

@export var m_events : Array[INPUT.Type] = []

func mPushBack(input : INPUT.Type) -> void:
	m_events.push_back(input)

func mClear() -> void:
	m_events.clear()

func mPopFront() -> INPUT.Type:
	return m_events.pop_front()

func mGetxAxisDirection() -> float:
	var xDirection : float = 0.0 # -1 is left and 1 is right.
	for input : INPUT.Type in m_events:
		match input:
			INPUT.Type.MOVE_LEFT:
				xDirection += -1.0
			INPUT.Type.MOVE_RIGHT:
				xDirection += 1.0
	
	return xDirection

