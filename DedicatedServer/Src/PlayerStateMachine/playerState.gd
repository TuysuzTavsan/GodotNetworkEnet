extends CharacterBody2D
class_name PlayerState

#Generic PlayerState class.
#Every playerState must derive from this class.

var m_player : Player = null #Owner Player node reference to access quickly.
var m_changeState : Callable #Callable reference to changeState from the owner = m_player.

func mSetup(ownerPlayer : Player, changeState : Callable) -> void:
	m_player = ownerPlayer
	m_changeState = changeState
