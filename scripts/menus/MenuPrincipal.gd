extends Control

@onready var botao_versus: Button = $VBoxContainer/BotaoVersus
@onready var botao_opcoes: Button = $VBoxContainer/BotaoOpcoes
@onready var botao_sair: Button = $VBoxContainer/BotaoSair
@onready var painel_opcoes: PanelContainer = $PainelOpcoes
@onready var slider_volume: HSlider = $PainelOpcoes/Margin/VBox/HBoxVolume/SliderVolume
@onready var label_porcento: Label = $PainelOpcoes/Margin/VBox/HBoxVolume/LabelPorcento
@onready var botao_fechar: Button = $PainelOpcoes/Margin/VBox/BotaoFechar

func _ready() -> void:
	botao_versus.pressed.connect(_on_versus)
	botao_opcoes.pressed.connect(_on_opcoes)
	botao_sair.pressed.connect(_on_sair)
	botao_fechar.pressed.connect(_fechar_opcoes)
	slider_volume.value_changed.connect(_on_volume_changed)
	botao_versus.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if painel_opcoes.visible and event.is_action_pressed("ui_cancel"):
		_fechar_opcoes()

func _on_versus() -> void:
	GameManager.ir_para_selecao()

func _on_opcoes() -> void:
	painel_opcoes.visible = true
	botao_fechar.grab_focus()

func _fechar_opcoes() -> void:
	painel_opcoes.visible = false
	botao_opcoes.grab_focus()

func _on_sair() -> void:
	get_tree().quit()

func _on_volume_changed(value: float) -> void:
	label_porcento.text = str(int(value)) + "%"
	if value <= 0.0:
		AudioServer.set_bus_volume_db(0, -80.0)
	else:
		AudioServer.set_bus_volume_db(0, linear_to_db(value / 100.0))
