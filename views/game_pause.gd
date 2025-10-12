extends Control

@onready var resume_button: Button = $CenterContainer/ModalPanel/VBoxContainer/ResumeButton
@onready var return_button: Button = $CenterContainer/ModalPanel/VBoxContainer/ReturnButton
@export var main_scene:Control


# 继续游戏
func _on_resume_pressed():
	# 获取主场景并调用恢复函数
	if main_scene and main_scene.has_method("resume_game"):
		main_scene.resume_game()

# 返回主菜单
func _on_return_pressed():
	# 取消暂停并返回主菜单
	get_tree().paused = false
	Global.game_status = Enums.GameStatus.NOTSTARTED
	# 切换到主菜单场景
	get_tree().change_scene_to_file("res://scenes/index.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if visible:
		if event.is_action_pressed("enter_game"):
			_on_return_pressed()
		elif event.is_action_pressed("ui_cancel"):
			_on_resume_pressed()
			get_viewport().set_input_as_handled()
