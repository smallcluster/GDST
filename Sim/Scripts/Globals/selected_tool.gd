extends Node

enum ToolChoice {
	MOVE_TARGET,
	PAN_VIEW,
	ZOOM_VIEW,
	ROTATE_VIEW
}
	
var current : ToolChoice = ToolChoice.MOVE_TARGET
