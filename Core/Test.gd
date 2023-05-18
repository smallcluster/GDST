extends Node
class_name Test

var frames : Array[Dictionary]


func load_file(path:String):
	if FileAccess.file_exists(path):
		var json_text := FileAccess.get_file_as_string(path)
		var json = JSON.parse_string(json_text)
		if json:
			print(json)
	
