class_name INPUT #All uppercase to avoid name conflict between Input singleton.

#Enum class to tell gameServer which inputs are pressed.

enum Type {
	UNSPECIFIED = 0,
	JUMP = 1,
	MOVE_LEFT = 2,
	MOVE_RIGHT = 3,
	ATTACK = 4,
	FIRE = 5,
}