extends Control

@onready var label_vencedor: Label = $Centro/VBox/LabelVencedor
@onready var label_placar: Label = $Centro/VBox/LabelPlacar
@onready var botao_revanche: Button = $Centro/VBox/BotoesBox/BotaoRevanche
@onready var botao_selecao: Button = $Centro/VBox/BotoesBox/BotaoSelecao
@onready var botao_menu: Button = $Centro/VBox/BotoesBox/BotaoMenu

func _ready() -> void:
	var v: int = GameManager.vencedor
	var nome_p1: String = GameManager.personagem_p1 if GameManager.personagem_p1 != "" else "P1"
	var nome_p2: String = GameManager.personagem_p2 if GameManager.personagem_p2 != "" else "P2"

	if v == 1:
		label_vencedor.text = nome_p1.to_upper() + "!"
		label_vencedor.modulate = Color(0.08, 0.82, 0.7, 1)
	elif v == 2:
		label_vencedor.text = nome_p2.to_upper() + "!"
		label_vencedor.modulate = Color(1, 0.74, 0, 1)
	else:
		label_vencedor.text = "EMPATE!"
		label_vencedor.modulate = Color(0.8, 0.8, 0.8, 1)

	label_placar.text = "%d  ×  %d" % [GameManager.rounds_p1, GameManager.rounds_p2]

	botao_revanche.pressed.connect(_on_revanche)
	botao_selecao.pressed.connect(_on_selecao)
	botao_menu.pressed.connect(_on_menu)
	botao_revanche.grab_focus()

func _on_revanche() -> void:
	GameManager.resetar_partida()
	GameManager.ir_para_arena()

func _on_selecao() -> void:
	GameManager.ir_para_selecao()

func _on_menu() -> void:
	GameManager.ir_para_menu_principal()
