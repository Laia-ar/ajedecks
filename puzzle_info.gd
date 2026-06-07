extends Panel

@onready var ToggleButton: Button = $ToggleButton
@onready var InformationText: RichTextLabel = $InformationText

var IsExpanded := true

func _ready():
	ToggleButton.pressed.connect(_on_toggle_pressed)
	InformationText.scroll_active = true
	InformationText.fit_content = false
	visible = false

func set_information(information: String):
	var clean_information = information.strip_edges()
	visible = not clean_information.is_empty()
	InformationText.text = clean_information
	IsExpanded = true
	_update_expanded_state()

func _on_toggle_pressed():
	IsExpanded = not IsExpanded
	_update_expanded_state()

func _update_expanded_state():
	InformationText.visible = IsExpanded
	ToggleButton.text = (
		"Información del puzzle ▲"
		if IsExpanded
		else "Información del puzzle ▼"
	)
	size.y = 290.0 if IsExpanded else 46.0
