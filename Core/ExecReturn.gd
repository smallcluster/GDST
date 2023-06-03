class_name ExecReturn

var fail : bool
var msg : String
var state : Dictionary

func _init(failure : bool, message : String, next_state : Dictionary):
	fail = failure
	msg = message
	state = next_state
