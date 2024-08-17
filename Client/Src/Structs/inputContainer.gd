extends RefCounted
class_name InputContainer

#simple struct to hold input together to represent a frame.

var m_events : Array[INPUT.Type] = []

func PushBack(input : INPUT.Type) -> void:
	m_events.push_back(input)

func PopFront() -> INPUT.Type:
	return m_events.pop_front()