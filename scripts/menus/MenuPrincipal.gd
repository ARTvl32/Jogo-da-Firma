extends Control

@onready var botao_versus: Button = $VBoxContainer/BotaoVersus
@onready var botao_opcoes: Button = $VBoxContainer/BotaoOpcoes
@onready var botao_sair: Button = $VBoxContainer/BotaoSair

func _ready() -> void:
	botao_versus.pressed.connect(_on_versus)
	botao_opcoes.pressed.connect(_on_opcoes)
	botao_sair.pressed.connect(_on_sair)
	botao_versus.grab_focus()

func _on_versus() -> void:
	GameManager.ir_para_selecao()

func _on_opcoes() -> void:
	print("[Menu] Opções — não implementado na v0.1")

func _on_sair() -> void:
	get_tree().quit()
