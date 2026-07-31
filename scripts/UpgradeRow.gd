extends VBoxContainer

signal pressed

@onready var _name_label: Label = %NameLabel
@onready var _desc_label: Label = %DescLabel
@onready var _button: Button = %ActionButton

func _ready() -> void:
	_button.pressed.connect(func(): pressed.emit())

func configure(stat_name: String, desc: String) -> void:
	_name_label.text = stat_name
	_desc_label.text = desc

func set_state(level: int, cost: int, disabled: bool) -> void:
	_button.text = "Nv.%d — $%s" % [level + 1, _fmt(cost)]
	_button.disabled = disabled

func _fmt(n: int) -> String:
	if n >= 1_000_000: return "%.1fM" % (n / 1_000_000.0)
	if n >= 1_000:     return "%.1fK" % (n / 1_000.0)
	return str(n)
