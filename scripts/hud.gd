extends CanvasLayer

@export_category("Stats")
@export var nickname = ""
@export var health = 0:
	set(v):
		health = v
		

@export var health_max = 0:
	set(v):
		health_max = v
		


func _ready() -> void:
	
	chat_style_o = chat_.get_theme_stylebox("panel")
	chat_.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	chat_edit.visible = false
	




@export_category("Chat")
var chat_style_o : StyleBox
@export var chat_ :PanelContainer
@export var chat_list :RichTextLabel
@export var chat_edit :LineEdit

@rpc("any_peer","call_local")
func chat(msg):
	chat_list.append_text(msg)
	#chat_list.scroll_to_line(chat_list.get_line_count())

func chat_local(msg):
	chat_list.append_text(msg)


func _chat_submitted(text: String) -> void:
	rpc("chat", str("[color=white][%s] %s[/color]\n" % [Global_self.nickname, text]))
	chat_edit.clear()
	
	chat_edit.release_focus()


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("chat"):
		chat_edit.grab_focus()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_viewport().set_input_as_handled()
		
		Global_self.input_blocked = true
		chat_.add_theme_stylebox_override("panel", chat_style_o)
		chat_edit.visible = true
	
	if Input.is_action_just_pressed("pause"):
		if chat_edit.has_focus(): chat_edit.release_focus()
		
		else: #pause menu
			Input.set_mouse_mode(
				Input.MOUSE_MODE_VISIBLE if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE else Input.MOUSE_MODE_HIDDEN
				)
	

func _chat_exited() -> void:
	Global_self.input_blocked = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	chat_.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	chat_edit.visible = false
