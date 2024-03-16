extends Node3D

@onready var edit_button = $EditButton
@onready var fix_button = $FixButton

var active = false:
	set(value):
		if value:
			edit_button.label = "save"
			fix_button.disabled = true
			fix_button.visible = false
		else:
			edit_button.label = "edit"
			fix_button.disabled = false
			fix_button.visible = true
		active = value

func _ready():

	edit_button.on_button_down.connect(func():
		if active:
			House.body.save_reference()
		else:
			House.body.edit_reference()
		active = !active
	)

	fix_button.on_button_down.connect(func():
		House.body.fix_reference()
		active = true
	)