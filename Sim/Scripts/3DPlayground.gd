extends CanvasLayer
@onready var _mainView := $"GUI/HSplitContainer/3DView/MainViewContainer/MainView"


# -- GUI EVENTS --
func _on_show_radius_toggled(button_pressed):
	_mainView.show_radius(button_pressed)

func _on_top_down_view_toggled(button_pressed):
	_mainView.top_down_view(button_pressed)

func _on_disable_shadows_toggled(button_pressed):
	_mainView.disable_shadows(button_pressed)
	
func _on_move_time_value_changed(value):
	_mainView.move_time_value_changed(value)
	
func _on_reset_pressed():
	_mainView.reset_pressed()

func _on_perspective_cam():
	$GUI/HSplitContainer/OptionsPanel/VBoxContainer/TopDownView.set_pressed_no_signal(false)
