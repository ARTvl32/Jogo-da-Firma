class_name ControlsManager
extends Node

# Autoload que persiste e aplica mapeamento de teclas em tempo de execução.
# Salva em user://controles.cfg via ConfigFile.

const CFG_PATH := "user://controles.cfg"

# Espelha as bindings padrão do project.godot.
# Formato: [keycode, physical_keycode, key_label]
const DEFAULTS: Dictionary = {
	"p1_left":  [KEY_A,          0, 0],
	"p1_right": [KEY_D,          0, 0],
	"p1_up":    [KEY_W,          0, 0],
	"p1_down":  [KEY_S,          0, 0],
	"p1_lp":    [KEY_U,          0, 0],
	"p1_lk":    [KEY_J,          0, 0],
	"p1_hp":    [KEY_I,          0, 0],
	"p1_hk":    [KEY_K,          0, 0],
	"p1_block": [KEY_O,          0, 0],
	"p2_left":  [KEY_LEFT,       0, 0],
	"p2_right": [KEY_RIGHT,      0, 0],
	"p2_up":    [KEY_UP,         0, 0],
	"p2_down":  [KEY_DOWN,       0, 0],
	"p2_lp":    [KEY_L,          0, 0],
	"p2_lk":    [KEY_COMMA,      0, 0],
	"p2_hp":    [KEY_SEMICOLON,  0, 0],
	"p2_hk":    [KEY_PERIOD,     0, 0],
	"p2_block": [KEY_CCEDILLA,   0, 0],
}

func _ready() -> void:
	carregar_e_aplicar()

func carregar_e_aplicar() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) != OK:
		_aplicar_defaults()
		return
	for acao: String in DEFAULTS.keys():
		if cfg.has_section_key("bindings", acao):
			var val: Array = cfg.get_value("bindings", acao)
			_aplicar_binding(acao, val[0], val[1], val[2])
		else:
			var d: Array = DEFAULTS[acao]
			_aplicar_binding(acao, d[0], d[1], d[2])

func _aplicar_defaults() -> void:
	for acao: String in DEFAULTS.keys():
		var d: Array = DEFAULTS[acao]
		_aplicar_binding(acao, d[0], d[1], d[2])

func _aplicar_binding(acao: String, kc: int, phys: int, lbl: int) -> void:
	InputMap.action_erase_events(acao)
	var ev := InputEventKey.new()
	ev.keycode = kc
	ev.physical_keycode = phys
	ev.key_label = lbl
	InputMap.action_add_event(acao, ev)

func salvar_binding(acao: String, ev: InputEventKey) -> void:
	_aplicar_binding(acao, ev.keycode, ev.physical_keycode, ev.key_label)
	_salvar_todos()

func restaurar_padroes() -> void:
	_aplicar_defaults()
	_salvar_todos()

func _salvar_todos() -> void:
	var cfg := ConfigFile.new()
	for acao: String in DEFAULTS.keys():
		var events: Array = InputMap.action_get_events(acao)
		if events.is_empty():
			cfg.set_value("bindings", acao, DEFAULTS[acao])
			continue
		var e: InputEventKey = events[0] as InputEventKey
		if e == null:
			cfg.set_value("bindings", acao, DEFAULTS[acao])
			continue
		cfg.set_value("bindings", acao, [e.keycode, e.physical_keycode, e.key_label])
	cfg.save(CFG_PATH)

func nome_tecla(acao: String) -> String:
	var events: Array = InputMap.action_get_events(acao)
	if events.is_empty():
		return "?"
	var ev: InputEventKey = events[0] as InputEventKey
	if ev == null:
		return "?"
	if ev.key_label != 0:
		return OS.get_keycode_string(ev.key_label)
	if ev.keycode != 0:
		return OS.get_keycode_string(ev.keycode)
	if ev.physical_keycode != 0:
		return OS.get_keycode_string(ev.physical_keycode)
	return "?"
