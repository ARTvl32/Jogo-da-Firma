class_name HUD
extends Control

@onready var bar_p1: ProgressBar = $HealthBar1
@onready var bar_p2: ProgressBar = $HealthBar2
@onready var lag_p1: ProgressBar = $LagBar1
@onready var lag_p2: ProgressBar = $LagBar2
@onready var label_timer: Label = $PainelTimer/TimerLabel
@onready var label_round: Label = $PainelTimer/RoundLabel
@onready var combo_p1: Label = $ComboLabel1
@onready var combo_p2: Label = $ComboLabel2
@onready var nome_p1: Label = $NomeP1
@onready var nome_p2: Label = $NomeP2
@onready var rounds_p1: HBoxContainer = $RoundsP1
@onready var rounds_p2: HBoxContainer = $RoundsP2
@onready var painel_pausa: Control = $PainelPausa
@onready var slider_vol: HSlider = $PainelPausa/Centro/Painel/Margin/VBox/HBoxVol/SliderVol
@onready var label_pct: Label = $PainelPausa/Centro/Painel/Margin/VBox/HBoxVol/LabelPct
@onready var botao_continuar: Button = $PainelPausa/Centro/Painel/Margin/VBox/BotaoContinuar
@onready var botao_menu: Button = $PainelPausa/Centro/Painel/Margin/VBox/BotaoMenu

var contador_combo_p1: int = 0
var contador_combo_p2: int = 0
var frames_desde_ultimo_hit_p1: int = 999
var frames_desde_ultimo_hit_p2: int = 999
const FRAMES_RESET_COMBO: int = 30

var vida_lag_p1: float = 0.0
var vida_lag_p2: float = 0.0
const VELOCIDADE_LAG: float = 90.0  # HP drenados por segundo

func _ready() -> void:
	combo_p1.text = ""
	combo_p2.text = ""

	var round_num: int = GameManager.rounds_p1 + GameManager.rounds_p2 + 1
	label_round.text = "Round %d" % round_num

	botao_continuar.pressed.connect(_continuar)
	botao_menu.pressed.connect(_ir_menu)
	slider_vol.value_changed.connect(_on_volume_changed)

	var db := AudioServer.get_bus_volume_db(0)
	slider_vol.value = clampf(db_to_linear(db) * 100.0, 0.0, 100.0)
	label_pct.text = str(int(slider_vol.value)) + "%"

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if painel_pausa.visible:
			_continuar()
		else:
			_pausar()
		get_viewport().set_input_as_handled()

func _pausar() -> void:
	painel_pausa.visible = true
	get_tree().paused = true
	botao_continuar.grab_focus()

func _continuar() -> void:
	painel_pausa.visible = false
	get_tree().paused = false

func _ir_menu() -> void:
	get_tree().paused = false
	GameManager.ir_para_menu_principal()

func _on_volume_changed(value: float) -> void:
	label_pct.text = str(int(value)) + "%"
	AudioServer.set_bus_volume_db(0, -80.0 if value <= 0.0 else linear_to_db(value / 100.0))

func _process(delta: float) -> void:
	frames_desde_ultimo_hit_p1 += 1
	frames_desde_ultimo_hit_p2 += 1
	if frames_desde_ultimo_hit_p1 > FRAMES_RESET_COMBO and contador_combo_p1 > 0:
		contador_combo_p1 = 0
		combo_p1.text = ""
	if frames_desde_ultimo_hit_p2 > FRAMES_RESET_COMBO and contador_combo_p2 > 0:
		contador_combo_p2 = 0
		combo_p2.text = ""

	# Lag bar P1 drena em direção ao valor real
	if vida_lag_p1 > bar_p1.value:
		vida_lag_p1 = maxf(bar_p1.value, vida_lag_p1 - VELOCIDADE_LAG * delta)
		lag_p1.value = vida_lag_p1

	# Lag bar P2 drena em direção ao valor real
	if vida_lag_p2 > bar_p2.value:
		vida_lag_p2 = maxf(bar_p2.value, vida_lag_p2 - VELOCIDADE_LAG * delta)
		lag_p2.value = vida_lag_p2

func conectar_fighters(p1: FighterBase, p2: FighterBase) -> void:
	bar_p1.max_value = p1.vida.vida_maxima
	bar_p1.value = p1.vida.vida_atual
	bar_p2.max_value = p2.vida.vida_maxima
	bar_p2.value = p2.vida.vida_atual

	lag_p1.max_value = p1.vida.vida_maxima
	lag_p2.max_value = p2.vida.vida_maxima
	vida_lag_p1 = float(p1.vida.vida_maxima)
	vida_lag_p2 = float(p2.vida.vida_maxima)
	lag_p1.value = vida_lag_p1
	lag_p2.value = vida_lag_p2

	nome_p1.text = p1.nome_exibicao.to_upper()
	nome_p2.text = p2.nome_exibicao.to_upper()

	p1.vida.vida_alterada.connect(func(atual: int, _max: int): bar_p1.value = atual)
	p2.vida.vida_alterada.connect(func(atual: int, _max: int): bar_p2.value = atual)
	p1.combate.acertou.connect(func(_alvo): _registrar_hit(1))
	p2.combate.acertou.connect(func(_alvo): _registrar_hit(2))

	atualizar_rounds()

func atualizar_rounds() -> void:
	_preencher_rounds(rounds_p1, GameManager.rounds_p1, GameManager.rounds_para_vencer)
	_preencher_rounds(rounds_p2, GameManager.rounds_p2, GameManager.rounds_para_vencer)

func _preencher_rounds(container: HBoxContainer, ganhos: int, total: int) -> void:
	for filho in container.get_children():
		filho.queue_free()
	for i in range(total):
		var l := Label.new()
		l.text = "★" if i < ganhos else "☆"
		l.theme_override_font_sizes["font_size"] = 14
		l.modulate = Color(1, 0.88, 0.1, 1) if i < ganhos else Color(0.45, 0.45, 0.45, 1)
		container.add_child(l)

func _registrar_hit(jogador: int) -> void:
	if jogador == 1:
		contador_combo_p1 += 1
		frames_desde_ultimo_hit_p1 = 0
		if contador_combo_p1 >= 2:
			combo_p1.text = "%d HITS" % contador_combo_p1
	else:
		contador_combo_p2 += 1
		frames_desde_ultimo_hit_p2 = 0
		if contador_combo_p2 >= 2:
			combo_p2.text = "%d HITS" % contador_combo_p2

func atualizar_timer(segundos: int) -> void:
	label_timer.text = "%02d" % segundos
