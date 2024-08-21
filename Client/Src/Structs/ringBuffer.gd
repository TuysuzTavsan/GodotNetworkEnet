extends RefCounted
class_name RingBuffer

#classic ringbuffer to store player related sync data.

var m_buffer : Array = []
var m_index : int = 0

func _init(bufferSize : int) -> void:
	m_buffer.resize(bufferSize)

func mPushBack(data) -> void:
	m_buffer[m_index] = data
	m_index = (m_index + 1) % m_buffer.size()

func mGetwOffset(offset : int):
	assert(offset < m_buffer.size(), "offset cant be more then buffer size.")

	return m_buffer[(m_index - offset) % m_buffer.size()]
