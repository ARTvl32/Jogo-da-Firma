extends Control

@onready var label_vencedor: Label = $LabelVencedor
@onready var label_placar: Label = $LabelPlacar
@onready var botao_revanche: Button = $VBoxContainer/BotaoRevanche
@onready var botao_menu: Button = $VBoxContainer/BotaoMenu

func _ready() -> void:
	var v: int = GameManager.vencedor
	if v == 1:
		label_vencedor.text = "P1 VENCEU!"
	elif v == 2:
		label_vencedor.text = "P2 VENCEU!"
	else:
		label_vencedor.text = "EMPATE"
	label_placar.text = "%d  x  %d" % [GameManager.rounds_p1, GameManager.rounds_p2]
	botao_revanche.pressed.connect(_on_revanche)
	botao_menu.pressed.connect(_on_menu)
	botao_revanche.grab_focus()

func _on_revanche() -> void:
	GameManager.rounds_p1 = 0
	GameManager.rounds_p2 = 0
	GameManager.vencedor = 0
	GameManager.ir_para_arena()

func _on_menu() -> void:
	GameManager.ir_para_menu_principal()
