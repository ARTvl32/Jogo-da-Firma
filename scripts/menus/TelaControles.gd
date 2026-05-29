extends Control

const ACOES: Array = [
	["MOVER ESQUERDA", "p1_left",  "p2_left"],
	["MOVER DIREITA",  "p1_right", "p2_right"],
	["PULAR",          "p1_up",    "p2_up"],
	["AGACHAR",        "p1_down",  "p2_down"],
	["SOCO LEVE",      "p1_lp",    "p2_lp"],
	["CHUTE LEVE",     "p1_lk",    "p2_lk"],
	["SOCO PESADO",    "p1_hp",    "p2_hp"],
	["CHUTE PESADO",   "p1_hk",    "p2_hk"],
	["BLOQUEAR",       "p1_block", "p2_block"],
]

@onready var container_linhas: VBoxContainer = $PainelPrincipal/Margin/VBox/ContainerLinhas
@onready var label_aviso: Label = $PainelPrincipal/Margin/VBox/LabelAviso
@onready var botao_restaurar: Button = $PainelPrincipal/Margin/VBox/FooterHBox/BotaoRestaurar
@onready var botao_voltar: Button = $PainelPrincipal/Margin/VBox/FooterHBox/BotaoVoltar

var _botoes_p1: Array[Button] = []
var _botoes_p2: Array[Button] = []
var _aguardando_acao: String = ""
var _botao_ativo: Button = null

func _ready() -> void:
	_construir_grid()
	botao_restaurar.pressed.connect(_on_restaurar)
	botao_voltar.pressed.connect(_on_voltar)
	botao_voltar.grab_focus()

func _construir_grid() -> void:
	_botoes_p1.clear()
	_botoes_p2.clear()
	for filho in container_linhas.get_children():
		filho.queue_free()

	for dados: Array in ACOES:
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 8)
		container_linhas.add_child(linha)

		var lbl := Label.new()
		lbl.text = dados[0]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 15)
		linha.add_child(lbl)

		var btn_p1 := _criar_botao(dados[1])
		linha.add_child(btn_p1)
		_botoes_p1.append(btn_p1)

		var btn_p2 := _criar_botao(dados[2])
		linha.add_child(btn_p2)
		_botoes_p2.append(btn_p2)

func _criar_botao(acao: String) -> Button:
	var btn := Button.new()
	btn.text = ControlsManager.nome_tecla(acao)
	btn.custom_minimum_size = Vector2(130, 34)
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(_on_botao_pressionado.bind(acao, btn))
	return btn

func _on_botao_pressionado(acao: String, btn: Button) -> void:
	if _aguardando_acao != "":
		return
	_aguardando_acao = acao
	_botao_ativo = btn
	btn.text = "..."
	btn.release_focus()
	label_aviso.text = "Pressione uma tecla. ESC cancela."

func _unhandled_input(event: InputEvent) -> void:
	if _aguardando_acao == "":
		return
	if not event is InputEventKey:
		return
	var kev: InputEventKey = event as InputEventKey
	if not kev.pressed or kev.echo:
		return
	get_viewport().set_input_as_handled()
	if kev.keycode == KEY_ESCAPE:
		_cancelar_rebind()
		return
	ControlsManager.salvar_binding(_aguardando_acao, kev)
	_botao_ativo.text = ControlsManager.nome_tecla(_aguardando_acao)
	label_aviso.text = ""
	_aguardando_acao = ""
	_botao_ativo = null

func _cancelar_rebind() -> void:
	if _botao_ativo != null:
		_botao_ativo.text = ControlsManager.nome_tecla(_aguardando_acao)
	label_aviso.text = ""
	_aguardando_acao = ""
	_botao_ativo = null

func _on_restaurar() -> void:
	ControlsManager.restaurar_padroes()
	for i in range(ACOES.size()):
		_botoes_p1[i].text = ControlsManager.nome_tecla(ACOES[i][1])
		_botoes_p2[i].text = ControlsManager.nome_tecla(ACOES[i][2])
	label_aviso.text = "Controles restaurados para o padrão."

func _on_voltar() -> void:
	if _aguardando_acao != "":
		_cancelar_rebind()
	get_tree().change_scene_to_file("res://scenes/menus/MenuPrincipal.tscn")
