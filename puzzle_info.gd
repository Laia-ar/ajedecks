extends Panel

@onready var ToggleButton: Button = $ToggleButton
@onready var InformationText: RichTextLabel = $InformationText

var IsExpanded := true

func _ready():
	ToggleButton.pressed.connect(_on_toggle_pressed)
	InformationText.scroll_active = true
	InformationText.fit_content = false
	InformationText.bbcode_enabled = true
	visible = false

func set_information(information: String, difficulty: String = "", complexity: String = ""):
	var clean_information = information.strip_edges()
	var clean_difficulty = difficulty.strip_edges()
	var clean_complexity = complexity.strip_edges()
	var sections := []
	if not clean_difficulty.is_empty():
		sections.append("[b]Dificultad:[/b] " + clean_difficulty)
	if not clean_complexity.is_empty():
		sections.append("[b]Complejidad:[/b] " + clean_complexity)
	if not clean_information.is_empty():
		if not sections.is_empty():
			sections.append("")
		sections.append(clean_information)
	visible = not sections.is_empty()
	InformationText.text = "\n".join(sections)
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
