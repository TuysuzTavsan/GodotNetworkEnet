extends PlayerState
class_name  PlayerAttack

#State specific variants and logic should live here.

#Additional parameters can be used to customize init function.
#Because XPersistantState.mChangeState will pass additional parameters to XFooState.new(params)
func _init(_params : Dictionary = {}):
	pass

#You can call generic XState process with super.
func _process(_delta):
	print("FOOOOOOOOO I am the XFooState")
	
	
	#You can change state here.
	#if(someCondition):
		#m_virtualChangeFunc.call(XPersistantState.STATES.BAR, additionalParams)