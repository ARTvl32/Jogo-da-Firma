# CLAUDE_3.md — Los Candidos v0.1.3

> Documento de instrução sequencial para o Claude Code.
> v0.1.2 concluída com 8 partes. Esta versão adiciona polish visual,
> mecânicas de combate e o primeiro modo de conteúdo solo.
>
> **Estimativas de custo de geração por PARTE:**
> As estimativas abaixo refletem tokens aproximados de OUTPUT para implementar cada parte.
> Partes menores podem ser executadas em conjunto; partes pesadas devem ser executadas isoladas.

---

## 0. Pré-requisitos

- v0.1.2 concluída: super meter, knockdown, chip damage, corner clamp, ataques no ar.
- `GeradorSom` autoload disponível com os streams: `hit_leve`, `hit_pesado`, `block`, `pulo`, `aterrissagem`, `morte`.
- `ComponenteCombate.Estado` contém: IDLE, WALK, RUN, JUMP, FALL, CROUCH, ATTACK_LP/LK/HP/HK, BLOCK, HURT, KNOCKDOWN, DEATH.

---

## 1. Regras Gerais

- GDScript estático, tipagem explícita.
- Commits Conventional Commits em PT-BR.
- Atualizar `ATUALIZAÇÕES.md` antes de cada push.
- Checkpoint rodável antes de avançar para a próxima parte.

---

# PARTE 1 — Hit Flash + Barra de Vida Crítica
> **Custo estimado: ~400 tokens** — duas adições pequenas ao mesmo arquivo (FighterBase + HUD).

**Objetivo:** feedback visual imediato ao tomar dano (sprite pisca branco) e aviso quando a vida está baixa (barra pulsa vermelho).

## 1.1 FighterBase.gd — hit flash

Adicionar método que pisca o sprite em branco por 3 frames:

```gdscript
func _piscar_sprite() -> void:
	sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)  # sobrexposição = branco
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
```

Chamar em `receber_hit()`, após aplicar dano (mas não em knockdown — o hitstop já dá feedback):

```gdscript
# No bloco normal (não knockdown):
combate.mudar_estado(ComponenteCombate.Estado.HURT)
_aplicar_hitstop(8)
_piscar_sprite()   # ← ADICIONAR
```

## 1.2 HUD.gd — barra crítica

Adicionar StyleBox vermelho e lógica de pulso em `_process()`:

```gdscript
# Adicionar variáveis
var _pulso_critico: float = 0.0
const LIMIAR_CRITICO: float = 0.20  # 20% da vida máxima

# Adicionar sub-resources no HUD.tscn: CritFill1 e CritFill2
# bg_color = Color(0.9, 0.1, 0.1, 1)

# Em _process():
_atualizar_barra_critica(bar_p1, p1_vida_max)
_atualizar_barra_critica(bar_p2, p2_vida_max)

func _atualizar_barra_critica(bar: ProgressBar, vida_max: int) -> void:
	if vida_max <= 0:
		return
	if bar.value / vida_max <= LIMIAR_CRITICO:
		_pulso_critico += get_process_delta_time() * 6.0
		var alpha: float = 0.7 + sin(_pulso_critico) * 0.3
		bar.modulate = Color(1.0, alpha * 0.3, alpha * 0.3, 1.0)
	else:
		_pulso_critico = 0.0
		bar.modulate = Color(1.0, 1.0, 1.0, 1.0)
```

Guardar `vida_max` de cada fighter em `conectar_fighters()`:
```gdscript
var _vida_max_p1: int = 1000
var _vida_max_p2: int = 1000
# Em conectar_fighters(): _vida_max_p1 = p1.vida.vida_maxima
```

## ✅ CHECKPOINT 1

- [ ] Ao receber hit: sprite pisca branco por ~3 frames.
- [ ] Com vida > 20%: barra na cor normal.
- [ ] Com vida ≤ 20%: barra pulsa em vermelho continuamente.
- [ ] Hit flash não interfere com o knockdown nem com iframes.

**Commit:** `feat(visual): hit flash branco e pulso de barra critica abaixo de 20%`

---

# PARTE 2 — Overlay "FIGHT!" / "KO!"
> **Custo estimado: ~500 tokens** — novos nós na Arena.tscn + lógica em Arena.gd.

**Objetivo:** texto dramático no início de cada round ("FIGHT!") e ao encerrar ("KO!" ou "TEMPO!").

## 2.1 Arena.tscn — adicionar OverlayTexto

```
Arena
└── OverlayTexto (Control)      [anchor full rect, mouse_filter=ignore]
    └── LabelOverlay (Label)    [centro da tela, fonte grande, hidden]
```

Configurações do `LabelOverlay`:
- `horizontal_alignment = CENTER`, `vertical_alignment = CENTER`
- `theme_override_font_sizes/font_size = 96`
- `modulate = Color(1, 1, 1, 0)` (começa invisível)

## 2.2 Arena.gd — exibir overlays

```gdscript
@onready var label_overlay: Label = $OverlayTexto/LabelOverlay

func _iniciar_round() -> void:
	round_em_andamento = true
	tempo_restante = duracao_round_segundos
	timer_round.start(1.0)
	_exibir_overlay("FIGHT!", Color(1.0, 0.9, 0.1, 1), 1.2)

func _ao_fighter_morrer(quem_venceu: int) -> void:
	if not round_em_andamento:
		return
	_exibir_overlay("K.O.!", Color(1.0, 0.2, 0.2, 1), 1.8)
	_encerrar_round(quem_venceu)

func _resolver_round_por_timeout() -> void:
	_exibir_overlay("TEMPO!", Color(0.8, 0.8, 0.8, 1), 1.8)
	# ... lógica existente ...

func _exibir_overlay(texto: String, cor: Color, duracao: float) -> void:
	label_overlay.text = texto
	label_overlay.modulate = cor
	var tween: Tween = create_tween()
	tween.tween_property(label_overlay, "modulate:a", 1.0, 0.15)
	tween.tween_interval(duracao * 0.6)
	tween.tween_property(label_overlay, "modulate:a", 0.0, 0.25)
```

## ✅ CHECKPOINT 2

- [ ] Ao iniciar round: "FIGHT!" aparece em amarelo e some suavemente.
- [ ] Ao morrer: "K.O.!" aparece em vermelho.
- [ ] Ao timeout: "TEMPO!" aparece em cinza.
- [ ] Overlay não bloqueia input (mouse_filter = ignore).
- [ ] Funciona corretamente em rematches (rounds 2 e 3).

**Commit:** `feat(arena): overlay FIGHT! e KO! com fade in/out via Tween`

---

# PARTE 3 — Rematch Rápido + Números de Dano
> **Custo estimado: ~600 tokens** — dois sistemas independentes de tamanho pequeno/médio.

**Objetivo:** atalho de revanche sem navegar menus + números flutuantes que mostram o dano de cada hit.

## 3.1 TelaResultado.gd — rematch rápido

```gdscript
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("p1_lp") or event.is_action_pressed("p2_lp"):
		_on_revanche()
```

Adicionar hint na cena: `Label` com `text = "[ LP ] Revanche rápida"` em cinza no rodapé.

## 3.2 DamageNumber.gd + DamageNumber.tscn

`scripts/efeitos/DamageNumber.gd`:

```gdscript
extends Label

func iniciar(valor: int, cor: Color) -> void:
	text = str(valor)
	modulate = cor
	add_theme_font_size_override("font_size", 28)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 60.0, 0.7)
	tween.tween_property(self, "modulate:a", 0.0, 0.7)
	tween.tween_callback(queue_free).set_delay(0.7)
```

`scenes/efeitos/DamageNumber.tscn` = Node2D com Label filho + script acima.

## 3.3 Arena.gd — spawnar número no hit

```gdscript
const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://scenes/efeitos/DamageNumber.tscn")

# Em _on_acerto() — após instanciar partículas:
func _on_acerto(_alvo: Node, atacante: FighterBase) -> void:
	# ... código existente ...
	var fd: Dictionary = ComponenteCombate.FRAME_DATA.get(atacante.combate.estado_atual, {})
	if not fd.is_empty():
		var dano: int = fd.get("dano", 0)
		var num: Label = DAMAGE_NUMBER_SCENE.instantiate()
		num.position = pos + Vector2(randf_range(-20, 20), -30)
		add_child(num)
		var cor: Color = Color(1, 0.3, 0.2, 1) if dano >= 100 else Color(1, 0.9, 0.3, 1)
		num.iniciar(dano, cor)
```

## ✅ CHECKPOINT 3

- [ ] Na TelaResultado: pressionar LP de qualquer player inicia revanche imediatamente.
- [ ] Hint de "LP = revanche rápida" visível na tela.
- [ ] Ao acertar hit: número amarelo (light) ou vermelho (heavy) flutua para cima e some.
- [ ] Chip damage também gera número (menor, em laranja).
- [ ] Números não acumulam na cena (queue_free ao final da animação).

**Commit:** `feat(ux): revanche rapida com LP + numeros de dano flutuantes`

---

# PARTE 4 — Landing Recovery
> **Custo estimado: ~450 tokens** — novo estado + lógica em FighterBase + ControladorAnimacao.

**Objetivo:** ao pousar de um pulo, o personagem fica brevemente em recuperação — não pode atacar
nem pular imediatamente. Equilibra ataques aéreos e remove o "aterrissar e atacar instantâneo".

## 4.1 ComponenteCombate.gd — novo estado

```gdscript
enum Estado {
	# ... existentes ...
	KNOCKDOWN,
	LANDING,   # ← NOVO: recuperação de aterrissagem
	DEATH
}
```

Adicionar ao `pode_atacar()`:
```gdscript
func pode_atacar() -> bool:
	return estado_atual in [Estado.IDLE, Estado.WALK, Estado.RUN, Estado.JUMP, Estado.FALL, Estado.CROUCH]
	# LANDING intencionalmente excluído
```

## 4.2 FighterBase.gd

Adicionar variável:
```gdscript
var landing_frames: int = 0
const LANDING_DURACAO: int = 8  # ~0.13s — curto mas presente
```

Em `_atualizar_estado_movimento()`:
```gdscript
else:
	if e == ComponenteCombate.Estado.FALL or e == ComponenteCombate.Estado.JUMP:
		combate.mudar_estado(ComponenteCombate.Estado.LANDING)
		landing_frames = LANDING_DURACAO
		GeradorSom.tocar("aterrissagem", -6.0)
```

Em `_physics_process()`, antes de `_processar_input()`:
```gdscript
if landing_frames > 0:
	landing_frames -= 1
	if landing_frames == 0 and combate.estado_atual == ComponenteCombate.Estado.LANDING:
		combate.mudar_estado(ComponenteCombate.Estado.IDLE)

if hitstun_frames == 0 and blockstun_frames == 0 and iframes_restantes == 0 and landing_frames == 0:
	_processar_input()
```

## 4.3 ControladorAnimacao.gd

```gdscript
ComponenteCombate.Estado.LANDING: "crouch",  # fallback para crouch ou idle
```

## ✅ CHECKPOINT 4

- [ ] Ao pousar de um pulo: ~8 frames onde não pode atacar nem pular.
- [ ] Movimento horizontal continua funcionando durante landing.
- [ ] Bloqueio funciona durante landing (pode se defender).
- [ ] Após 8 frames: retorna ao IDLE automaticamente.
- [ ] Nenhum erro de `landed + attack on same frame`.

**Commit:** `feat(combate): landing recovery — 8 frames de recuperacao ao pousar`

---

# PARTE 5 — Super Move (Consumo do Meter)
> **Custo estimado: ~900 tokens** — novo estado, input, frame data, lógica e efeito visual.

**Objetivo:** pressionar HP+HK simultaneamente com super meter cheio executa um super ataque —
dano alto, hitbox grande, knockdown garantido. Fecha o loop do super meter da v0.1.2.

## 5.1 ComponenteCombate.gd — novo estado e frame data

```gdscript
enum Estado {
	# ... existentes ...
	SUPER_ATAQUE,
	LANDING,
	DEATH
}

const FRAME_DATA: Dictionary = {
	# ... existentes ...
	Estado.SUPER_ATAQUE: {
		"startup": 12, "active": 8, "recovery": 24,
		"dano": 280, "hitstun": 0, "blockstun": 22,
		"knockback": Vector2(600, -300), "knockdown": true
	},
}
```

Atualizar `eh_estado_de_ataque()`:
```gdscript
func eh_estado_de_ataque(e: int) -> bool:
	return e in [Estado.ATTACK_LP, Estado.ATTACK_LK, Estado.ATTACK_HP, Estado.ATTACK_HK, Estado.SUPER_ATAQUE]
```

## 5.2 FighterBase.gd — input e consumo

```gdscript
const SUPER_CUSTO: float = 100.0

# Em _processar_input(), antes dos ataques normais:
if _input_just_pressed("hp") and _input_pressionado("hk") and super_atual >= SUPER_CUSTO:
	_ativar_super()
	return

func _ativar_super() -> void:
	super_atual = 0.0
	super_alterado.emit(0.0, SUPER_MAXIMO)
	combate.mudar_estado(ComponenteCombate.Estado.SUPER_ATAQUE)
	velocity.x = 0
	GeradorSom.tocar("hit_pesado")
	_flash_super()

func _flash_super() -> void:
	# Tela clareia rapidamente para indicar ativação
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(1, 1, 1, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(overlay)
	var tween: Tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, 0.3)
	tween.tween_callback(overlay.queue_free)
```

## 5.3 HUD.gd — feedback visual quando meter está cheio

```gdscript
# Em _process(), ao atualizar super bars:
if super_p1.value >= FighterBase.SUPER_MAXIMO:
	_pulso_super_critico += delta * 5.0
	super_p1.modulate = Color(1.0, 1.0, 0.5 + sin(_pulso_super_critico) * 0.5, 1.0)
else:
	super_p1.modulate = Color(1.0, 1.0, 1.0, 1.0)
```

Adicionar `var _pulso_super_critico: float = 0.0`.

## ✅ CHECKPOINT 5

- [ ] HP+HK com meter cheio ativa o super.
- [ ] Meter zera imediatamente ao ativar.
- [ ] Super causa 280 de dano e knockdown.
- [ ] Flash branco na tela ao ativar.
- [ ] Com meter vazio: HP+HK não ativa super (ataque normal).
- [ ] Barra de super pisca dourada quando está cheia.
- [ ] Bloqueando super recebe chip de 8% de 280 = ~22 HP.

**Commit:** `feat(combate): super move HP+HK com meter cheio — flash, knockdown e consumo`

---

# PARTE 6 — Guard Break
> **Custo estimado: ~950 tokens** — nova variável, novo estado, HUD visual e balanceamento.

**Objetivo:** bloquear repetidamente esgota um "guard meter" oculto. Ao zerar, o defensor sofre
guard break — fica vulnerável por 50 frames sem poder bloquear. Penaliza turtle play.

## 6.1 FighterBase.gd — guard meter

```gdscript
var guard_meter: float = 100.0
const GUARD_MAXIMO: float = 100.0
const GUARD_RECUPERACAO: float = 8.0   # por segundo parado
const GUARD_BREAK_DURACAO: int = 50

var guard_break_frames: int = 0

signal guard_alterado(atual: float, maximo: float)
```

Em `receber_hit()`, no bloco de bloqueio:
```gdscript
if combate.esta_bloqueando():
	var custo_guard: float = 8.0 if dano < 100 else 18.0
	guard_meter = maxf(0.0, guard_meter - custo_guard)
	guard_alterado.emit(guard_meter, GUARD_MAXIMO)
	if guard_meter <= 0.0:
		_ativar_guard_break()
		return
	# ... resto do bloco de block ...
```

```gdscript
func _ativar_guard_break() -> void:
	guard_break_frames = GUARD_BREAK_DURACAO
	combate.mudar_estado(ComponenteCombate.Estado.HURT)
	hitstun_frames = GUARD_BREAK_DURACAO
	velocity.x = knockback.x * 0.5
	GeradorSom.tocar("hit_pesado")
```

Em `_physics_process()`, recuperação gradual:
```gdscript
if guard_break_frames > 0:
	guard_break_frames -= 1

# Recupera guard quando não está bloqueando
if not combate.esta_bloqueando() and guard_meter < GUARD_MAXIMO:
	guard_meter = minf(GUARD_MAXIMO, guard_meter + GUARD_RECUPERACAO * delta)
	guard_alterado.emit(guard_meter, GUARD_MAXIMO)
```

## 6.2 HUD.tscn — barra de guard

Adicionar `GuardBar1` e `GuardBar2` — barras roxas muito finas (6px) abaixo das super bars:

```
GuardBar1: offset y=98-104, left=40, right=565, cor roxa Color(0.6, 0.1, 0.9, 1)
GuardBar2: offset y=98-104, left=716, right=1240, fill_mode=1
```

## 6.3 HUD.gd — conectar guard

```gdscript
@onready var guard_p1: ProgressBar = $GuardBar1
@onready var guard_p2: ProgressBar = $GuardBar2

# Em conectar_fighters():
guard_p1.max_value = FighterBase.GUARD_MAXIMO
guard_p2.max_value = FighterBase.GUARD_MAXIMO
guard_p1.value = FighterBase.GUARD_MAXIMO
guard_p2.value = FighterBase.GUARD_MAXIMO
p1.guard_alterado.connect(func(atual, _max): guard_p1.value = atual)
p2.guard_alterado.connect(func(atual, _max): guard_p2.value = atual)
```

Resetar guard em `Arena._encerrar_round()`:
```gdscript
fighter1.guard_meter = FighterBase.GUARD_MAXIMO
fighter2.guard_meter = FighterBase.GUARD_MAXIMO
```

## ✅ CHECKPOINT 6

- [ ] Bloquear repetidamente reduz a barra roxa.
- [ ] Guard break: fighter fica em stun 50 frames, sem poder bloquear.
- [ ] Barra recupera quando não está bloqueando.
- [ ] Resetar entre rounds.
- [ ] Bloqueio normal continua funcionando enquanto guard > 0.

**Commit:** `feat(combate): guard break — meter roxo esgotar ao bloquear muito causa stun`

---

# PARTE 7 — Throw / Grab
> **Custo estimado: ~1100 tokens** — dois novos estados, detecção de proximidade, lógica de escape e animação.

**Objetivo:** pressionar LP+LK em close range executa um throw — ignora block, causa dano médio
e reposiciona o oponente. É a resposta ao bloqueio defensivo (junto com chip e guard break).

## 7.1 ComponenteCombate.gd — estados THROW e THROWN

```gdscript
enum Estado {
	# ... existentes ...
	THROW,    # atacante executa o throw
	THROWN,   # defensor sendo arremessado
	SUPER_ATAQUE,
	LANDING,
	DEATH
}
```

Frame data do throw:
```gdscript
Estado.THROW: {
	"startup": 5, "active": 3, "recovery": 20,
	"dano": 150, "hitstun": 0, "blockstun": 0,
	"knockback": Vector2(350, -150), "knockdown": true
},
```

## 7.2 FighterBase.gd — input e detecção de proximidade

```gdscript
const DISTANCIA_THROW: float = 90.0  # pixels — close range

# Em _processar_input(), antes dos ataques normais:
if _input_just_pressed("lp") and _input_pressionado("lk"):
	if _tentar_throw():
		return

func _tentar_throw() -> bool:
	if conhece_oponente == null:
		return false
	var dist: float = abs(global_position.x - conhece_oponente.global_position.x)
	if dist > DISTANCIA_THROW:
		return false
	if conhece_oponente.combate.estado_atual == ComponenteCombate.Estado.THROWN:
		return false
	combate.mudar_estado(ComponenteCombate.Estado.THROW)
	velocity.x = 0
	return true
```

Em `_on_hit_conectado()` — quando THROW conecta, aplicar THROWN no oponente:
```gdscript
if combate.estado_atual == ComponenteCombate.Estado.THROW:
	var kb: Vector2 = Vector2(350.0 if olhando_direita else -350.0, -150.0)
	alvo.receber_throw(self, 150, kb)
	combate.acertou.emit(alvo)
	GeradorSom.tocar("hit_pesado")
	return
```

```gdscript
func receber_throw(atacante: FighterBase, dano: int, knockback: Vector2) -> void:
	if combate.esta_bloqueando():
		# Throw ignora block
		pass
	vida.aplicar_dano(dano)
	velocity = knockback
	knockdown_frames = KNOCKDOWN_DURACAO
	combate.mudar_estado(ComponenteCombate.Estado.THROWN)
	_aplicar_hitstop(10)
	combate.levou_hit.emit(atacante, dano, knockback)
```

## 7.3 ControladorAnimacao.gd

```gdscript
ComponenteCombate.Estado.THROW:  "attack_hp",  # fallback visual
ComponenteCombate.Estado.THROWN: "hurt",
```

## ✅ CHECKPOINT 7

- [ ] LP+LK em close range: throw executado.
- [ ] Throw fora do alcance: não ativa (sem feedback por enquanto).
- [ ] Throw ignora block completamente — não há chip nem blockstun.
- [ ] Oponente throwado sofre knockdown + 150 de dano.
- [ ] Throw não funciona contra THROWN, KNOCKDOWN ou DEATH.

**Commit:** `feat(combate): throw/grab — LP+LK em close range ignora block e causa knockdown`

---

# PARTE 8 — Modo Treino
> **Custo estimado: ~2000 tokens** — nova cena completa, novo script, dummy AI e HUD dedicado.
> **Executar isolado** — é a parte mais pesada do documento.

**Objetivo:** arena de prática com dummy infinito, opções configuráveis e exibição de frame data.

## 8.1 TrainingHUD.tscn

```
TrainingHUD (Control)
├── LabelFrameData (Label)      [canto inf. esquerdo, mostra startup/active/recovery do último ataque]
├── LabelCombo (Label)          [mostra hits e dano acumulado do combo]
├── LabelDummyStatus (Label)    [canto inf. direito: "DUMMY: Parado / Bloqueando / Aleatório"]
└── PainelConfig (Panel)        [Esc → abre config: vida infinita toggle, comportamento dummy]
```

## 8.2 DummyAI.gd

```gdscript
class_name DummyAI
extends Node

enum Comportamento { PARADO, BLOQUEANDO, ALEATORIO }

@export var fighter: FighterBase
var comportamento: Comportamento = Comportamento.PARADO

func _physics_process(_delta: float) -> void:
	if fighter == null or not fighter.vida.esta_vivo():
		fighter.vida.resetar()
		return
	match comportamento:
		Comportamento.BLOQUEANDO:
			# Força o estado de block via sinal ou método direto
			if fighter.is_on_floor() and not fighter.combate.eh_estado_de_ataque(fighter.combate.estado_atual):
				fighter.combate.mudar_estado(ComponenteCombate.Estado.BLOCK)
		Comportamento.ALEATORIO:
			# Aleatoriamente: idle, block ou andar
			pass  # implementar na v0.1.3 com RNG seedada
```

## 8.3 TrainingArena.gd

Herda ou duplica a Arena com as seguintes diferenças:
- `vida_infinita: bool = true` — se ativado, regenera HP do dummy a cada frame
- Timer não corre (ou é opcional)
- Sem encerramento de round — fighters nunca "morrem" de verdade
- Conecta `DummyAI` ao `fighter2`
- Exibe `TrainingHUD` em vez do HUD padrão

## 8.4 Acesso via MenuPrincipal

Adicionar botão "TREINO" no `MenuPrincipal.tscn` e método em `GameManager.gd`:

```gdscript
func ir_para_treino() -> void:
	personagem_p1 = "VIP"
	personagem_p2 = "MDK"
	get_tree().change_scene_to_file("res://scenes/arena/TrainingArena.tscn")
```

## ✅ CHECKPOINT 8 (FINAL v0.1.3)

- [ ] Menu principal → Treino → arena carrega com VIP vs dummy MDK.
- [ ] Vida do dummy regenera automaticamente (se vida infinita ativo).
- [ ] Dummy fica parado por padrão; pode ser configurado para bloquear.
- [ ] LabelFrameData mostra startup/active/recovery do último ataque de P1.
- [ ] LabelCombo mostra hits e dano acumulado do combo atual.
- [ ] Esc abre painel de config do treino.
- [ ] Esc novamente ou botão Voltar → Menu Principal.

**Commit:** `feat(modo): training mode com dummy configuravel e display de frame data`

---

# Resumo de Custos Estimados

| PARTE | Feature | Tokens estimados |
|---|---|---|
| 1 | Hit flash + barra crítica | ~400 |
| 2 | Overlay FIGHT! / KO! | ~500 |
| 3 | Rematch rápido + damage numbers | ~600 |
| 4 | Landing recovery | ~450 |
| 5 | Super move | ~900 |
| 6 | Guard break | ~950 |
| 7 | Throw / grab | ~1100 |
| 8 | Modo Treino | ~2000 |
| **Total** | | **~6900** |

> Partes 1–4 podem ser executadas em pares (custo ≤ 1000 cada par).
> Partes 5–7 devem ser executadas uma por vez.
> Parte 8 deve ser executada isolada.

---

**FIM DO CLAUDE_3.md — v0.1.3**
