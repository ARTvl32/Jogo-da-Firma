extends Control

@onready var label_p1: Label = $PainelP1/LabelEscolha
@onready var label_p2: Label = $PainelP2/LabelEscolha
@onready var label_status: Label = $LabelStatus

var escolha_p1: String = ""
var escolha_p2: String = ""
var p1_confirmado: bool = false
var p2_confirmado: bool = false

func _ready() -> void:
	_atualizar_labels()

func _input(event: InputEvent) -> void:
	if not p1_confirmado:
		if event.is_action_pressed("p1_left"):
			escolha_p1 = "VIP"
		elif event.is_action_pressed("p1_right"):
			escolha_p1 = "MDK"
		elif event.is_action_pressed("p1_lp") and escolha_p1 != "":
			p1_confirmado = true
			label_status.text = "P1 confirmado! Aguardando P2..."

	if not p2_confirmado:
		if event.is_action_pressed("p2_left"):
			escolha_p2 = "VIP"
		elif event.is_action_pressed("p2_right"):
			escolha_p2 = "MDK"
		elif event.is_action_pressed("p2_lp") and escolha_p2 != "":
			p2_confirmado = true
			label_status.text = "P2 confirmado!"

	if event.is_action_pressed("ui_cancel"):
		GameManager.ir_para_menu_principal()

	_atualizar_labels()

	if p1_confirmado and p2_confirmado:
		_iniciar_partida()

func _atualizar_labels() -> void:
	label_p1.text = "P1: %s" % (escolha_p1 if escolha_p1 != "" else "—")
	label_p2.text = "P2: %s" % (escolha_p2 if escolha_p2 != "" else "—")

func _iniciar_partida() -> void:
	label_status.text = "Iniciando..."
	GameManager.personagem_p1 = escolha_p1
	GameManager.personagem_p2 = escolha_p2
	await get_tree().create_timer(0.5).timeout
	GameManager.ir_para_arena()
