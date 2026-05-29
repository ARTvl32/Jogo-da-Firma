# CLAUDE_2.md — Los Candidos v0.1.2

> Documento de instrução sequencial para o Claude Code.
> Parte 2 do desenvolvimento — v0.1.1 já está funcional com loop completo,
> audio procedural, menus e HUD. Esta versão foca em corrigir bugs
> remanescentes e adicionar polish de jogo de luta.

---

## 0. Estado atual (pós v0.1.1)

**O que já funciona:**
- Loop completo: Menu → Seleção → Arena → Resultado → Menu
- Fighters com FSM, hitbox/hurtbox, hitstop, hitstun, blockstun, knockback
- HUD com healthbars, timer, combo counter, pausa e controle de volume
- Sprites reais (Martial Hero 2/3), background NightForest com parallax
- ScreenShake em acertos, partículas de impacto
- Áudio procedural (GeradorSom autoload) com música e SFX gerados

**Bugs conhecidos a corrigir nesta versão:**
1. `GeradorSom.tocar()` nunca é chamado durante o combate — sons de hit, block, pulo e morte não tocam.
2. `pode_se_mover()` só inclui IDLE/WALK/RUN — o facing não atualiza durante JUMP/FALL.
3. Chip damage ao bloquear está zerado (multiplicador 0.3 do knockback, mas `vida.aplicar_dano()` nunca é chamado em block).
4. Fighters podem sair pelas laterais da tela (sem câmera clamp lateral por personagem).
5. `TelaControles.tscn` existe mas não está ligada a nenhum botão do menu principal.

---

## 1. Regras Gerais (herdadas do CLAUDE_1.md)

- GDScript estático, tipagem explícita em tudo.
- Toda lógica de gameplay em `_physics_process`, visual/UI em `_process`.
- Commits em português, Conventional Commits.
- Parar em cada checkpoint antes de avançar.

---

# PARTE 1 — Conectar GeradorSom ao Combate

**Objetivo:** Sons de hit, block, pulo, aterrissagem e morte tocando corretamente.
O `GeradorSom` já existe como autoload com os streams prontos — só falta chamá-lo.

## 1.1 FighterBase.gd — adicionar chamadas de som

Adicionar ao `_ready()`:
```gdscript
vida.morreu.connect(_on_morreu)  # já existe — adicionar som abaixo
```

Adicionar método:
```gdscript
func _on_pousou() -> void:
	GeradorSom.tocar("aterrissagem")
```

Conectar em `_physics_process`, logo após `move_and_slide()`:
```gdscript
# Detecta aterrissagem (transição ar → chão)
if is_on_floor() and velocity.y >= 0 and not _estava_no_chao:
	GeradorSom.tocar("aterrissagem")
_estava_no_chao = is_on_floor()
```

Adicionar variável de estado:
```gdscript
var _estava_no_chao: bool = false
```

Adicionar som de pulo em `_processar_input()`, dentro do bloco de pulo:
```gdscript
if _input_just_pressed("up") and is_on_floor():
	velocity.y = forca_pulo
	combate.mudar_estado(ComponenteCombate.Estado.JUMP)
	GeradorSom.tocar("pulo")   # ← ADICIONAR
	return
```

Em `_on_morreu()`:
```gdscript
func _on_morreu() -> void:
	combate.mudar_estado(ComponenteCombate.Estado.DEATH)
	hitbox.desativar()
	GeradorSom.tocar("morte")   # ← ADICIONAR
```

Em `receber_hit()`:
```gdscript
func receber_hit(...) -> void:
	if combate.esta_bloqueando():
		blockstun_frames = blockstun
		velocity.x = knockback.x * 0.3
		_aplicar_hitstop(6)
		GeradorSom.tocar("block")   # ← ADICIONAR
		return
	vida.aplicar_dano(dano)
	...
	GeradorSom.tocar("hit_leve" if dano < 100 else "hit_pesado")   # ← ADICIONAR
```

## ✅ CHECKPOINT 1

- [ ] Pulo toca whoosh.
- [ ] Aterrissagem toca impacto surdo.
- [ ] Hit leve toca som diferente de hit pesado.
- [ ] Block toca som metálico.
- [ ] Morte toca som grave.
- [ ] Sem erros de `GeradorSom` no console.

**Commit:** `feat(audio): conecta GeradorSom ao FighterBase — pulo, hit, block e morte`

---

# PARTE 2 — Chip Damage ao Bloquear

**Objetivo:** Bloquear não é gratuito — ataques pesados causam pequeno dano mesmo bloqueados.
Apenas HP/HK causam chip; LP/LK continuam sem chip (design KOF-style).

## 2.1 FighterBase.gd — adicionar chip em `receber_hit()`

```gdscript
func receber_hit(atacante: FighterBase, dano: int, hitstun: int, blockstun: int, knockback: Vector2) -> void:
	if combate.estado_atual == ComponenteCombate.Estado.DEATH:
		return
	if combate.esta_bloqueando():
		blockstun_frames = blockstun
		velocity.x = knockback.x * 0.3
		_aplicar_hitstop(6)
		GeradorSom.tocar("block")
		# Chip damage: 8% do dano apenas em ataques pesados (dano >= 100)
		if dano >= 100:
			var chip: int = max(1, int(dano * 0.08))
			vida.aplicar_dano(chip)
		combate.levou_hit.emit(atacante, 0, knockback)
		return
	vida.aplicar_dano(dano)
	hitstun_frames = hitstun
	velocity = knockback
	combate.mudar_estado(ComponenteCombate.Estado.HURT)
	_aplicar_hitstop(8)
	GeradorSom.tocar("hit_leve" if dano < 100 else "hit_pesado")
	combate.levou_hit.emit(atacante, dano, knockback)
```

> **Nota de design:** chip não mata — se a vida for a 0 por chip, o fighter fica em 1 HP.
> Adicionar em `ComponenteVida.aplicar_dano()`:
```gdscript
func aplicar_dano(quantidade: int, pode_matar: bool = true) -> void:
	if vida_atual <= 0:
		return
	vida_atual = max(0 if pode_matar else 1, vida_atual - quantidade)
	vida_alterada.emit(vida_atual, vida_maxima)
	if vida_atual == 0:
		morreu.emit()
```
Chamar chip com `vida.aplicar_dano(chip, false)`.

## ✅ CHECKPOINT 2

- [ ] Bloquear LP/LK: healthbar não se move.
- [ ] Bloquear HP/HK: healthbar perde ~8% do dano correspondente.
- [ ] Chip nunca mata (vida para em 1).
- [ ] Som metálico toca ao bloquear.

**Commit:** `feat(combate): chip damage em ataques pesados bloqueados (8%, nao mata)`

---

# PARTE 3 — Health Bar com Lag (Dano Gradual)

**Objetivo:** Barra branca/amarela mostra o dano recente e drena lentamente para o valor real —
estética KOF / Street Fighter Alpha.

## 3.1 HUD.gd — adicionar lag bar

```gdscript
# Adicionar variáveis
var vida_lag_p1: float = 0.0
var vida_lag_p2: float = 0.0
const VELOCIDADE_LAG: float = 80.0   # HP por segundo de drenagem

# Adicionar ProgressBars de lag na cena (ver 3.2)
@onready var lag_p1: ProgressBar = $LagBar1
@onready var lag_p2: ProgressBar = $LagBar2

# Em conectar_fighters(), inicializar lag
func conectar_fighters(p1: FighterBase, p2: FighterBase) -> void:
	# ... código existente ...
	vida_lag_p1 = float(p1.vida.vida_maxima)
	vida_lag_p2 = float(p2.vida.vida_maxima)
	lag_p1.max_value = p1.vida.vida_maxima
	lag_p1.value = vida_lag_p1
	lag_p2.max_value = p2.vida.vida_maxima
	lag_p2.value = vida_lag_p2

# Em _process(), atualizar lag
func _process(delta: float) -> void:
	# ... código existente (combo reset) ...
	if vida_lag_p1 > bar_p1.value:
		vida_lag_p1 = max(bar_p1.value, vida_lag_p1 - VELOCIDADE_LAG * delta)
		lag_p1.value = vida_lag_p1
	if vida_lag_p2 > bar_p2.value:
		vida_lag_p2 = max(bar_p2.value, vida_lag_p2 - VELOCIDADE_LAG * delta)
		lag_p2.value = vida_lag_p2
```

## 3.2 HUD.tscn — adicionar LagBar1 e LagBar2

Inserir dois `ProgressBar` atrás das barras existentes (z_index menor):

```
HUD
├── LagBar1 (ProgressBar)   [mesma posição/tamanho de HealthBar1, cor amarela, atrás]
├── HealthBar1 (ProgressBar)
├── LagBar2 (ProgressBar)   [mesma posição/tamanho de HealthBar2, cor amarela, atrás]
└── HealthBar2 (ProgressBar)
```

- `LagBar1/2` cor: `Color(1, 0.85, 0.1, 1)` (amarelo).
- Mesmos `max_value`, `fill_mode` e dimensões das barras principais.
- Atrás = ordem de nó anterior (ou `show_behind_parent = true`).

## ✅ CHECKPOINT 3

- [ ] Ao receber dano, a barra principal cai imediatamente.
- [ ] Barra amarela permanece e drena ~80 HP/s até igualar a principal.
- [ ] Funciona para P1 (esquerda→direita) e P2 (direita→esquerda).
- [ ] Chip damage também aparece na lag bar.

**Commit:** `feat(hud): lag bar amarela — dano gradual estilo KOF`

---

# PARTE 4 — Indicadores de Round Ganho

**Objetivo:** Ícones (★ / ○) abaixo de cada healthbar mostram quantos rounds cada
jogador venceu — referência visual de best-of-3.

## 4.1 HUD.gd — adicionar indicadores

```gdscript
@onready var rounds_p1: HBoxContainer = $RoundsP1
@onready var rounds_p2: HBoxContainer = $RoundsP2

func atualizar_rounds() -> void:
	_preencher_rounds(rounds_p1, GameManager.rounds_p1, GameManager.rounds_para_vencer)
	_preencher_rounds(rounds_p2, GameManager.rounds_p2, GameManager.rounds_para_vencer)

func _preencher_rounds(container: HBoxContainer, ganhos: int, total: int) -> void:
	for filho in container.get_children():
		filho.queue_free()
	for i in range(total):
		var l := Label.new()
		l.text = "★" if i < ganhos else "☆"
		l.theme_override_font_sizes["font_size"] = 18
		l.modulate = Color(1, 0.85, 0.1, 1) if i < ganhos else Color(0.4, 0.4, 0.4, 1)
		container.add_child(l)
```

Chamar `hud.atualizar_rounds()` em `Arena._encerrar_round()` depois de incrementar os contadores.

## 4.2 HUD.tscn — adicionar HBoxContainers

```
HUD
├── RoundsP1 (HBoxContainer)   [abaixo de HealthBar1, lado esquerdo, separation: 4]
└── RoundsP2 (HBoxContainer)   [abaixo de HealthBar2, lado direito, separation: 4]
```

## ✅ CHECKPOINT 4

- [ ] Início do primeiro round: ☆☆ para ambos.
- [ ] Após P1 ganhar round 1: ★☆ embaixo de P1, ☆☆ embaixo de P2.
- [ ] Best-of-3 correto (para em 2 estrelas preenchidas).

**Commit:** `feat(hud): indicadores de round ganho (estrelas) abaixo das healthbars`

---

# PARTE 5 — Ataques no Ar

**Objetivo:** Permitir LP e HP enquanto o personagem está no ar.
LK e HK no ar ficam para v0.2 (requerem animações específicas).
`pode_atacar()` já retorna `true` para JUMP/FALL — falta liberar no input.

## 5.1 FighterBase.gd — liberar ataques no ar

Em `_processar_input()`, remover a restrição de chão para LP/HP:

```gdscript
func _processar_input() -> void:
	if combate.eh_estado_de_ataque(combate.estado_atual):
		if combate.ataque_terminou():
			combate.mudar_estado(ComponenteCombate.Estado.IDLE)
			hitbox.desativar()
		else:
			return

	# Block só no chão
	if _input_pressionado("block") and is_on_floor():
		combate.mudar_estado(ComponenteCombate.Estado.BLOCK)
		velocity.x = 0
		return

	# LP e HP funcionam no ar também
	if _input_just_pressed("lp"):
		_iniciar_ataque(ComponenteCombate.Estado.ATTACK_LP)
		return
	if _input_just_pressed("hp"):
		_iniciar_ataque(ComponenteCombate.Estado.ATTACK_HP)
		return

	# LK e HK: apenas no chão (sem animação de ar na v0.1.2)
	if is_on_floor():
		if _input_just_pressed("lk"):
			_iniciar_ataque(ComponenteCombate.Estado.ATTACK_LK)
			return
		if _input_just_pressed("hk"):
			_iniciar_ataque(ComponenteCombate.Estado.ATTACK_HK)
			return

	# Pulo
	if _input_just_pressed("up") and is_on_floor():
		velocity.y = forca_pulo
		combate.mudar_estado(ComponenteCombate.Estado.JUMP)
		GeradorSom.tocar("pulo")
		return

	# No ar: ajusta velocidade horizontal, não muda estado
	if not is_on_floor():
		var dir_ar: float = _direcao_horizontal()
		velocity.x = dir_ar * velocidade_andar
		return

	# ... resto do input terrestre ...
```

## 5.2 `_iniciar_ataque()` — não zerar velocidade y no ar

```gdscript
func _iniciar_ataque(estado_ataque: int) -> void:
	combate.mudar_estado(estado_ataque)
	if is_on_floor():
		velocity.x = 0   # para só no chão
	# No ar mantém momento do pulo
```

## ✅ CHECKPOINT 5

- [ ] LP no ar dispara ataque (animação de ataque toca mesmo pulando).
- [ ] HP no ar dispara ataque com knockback correto.
- [ ] LK/HK só funcionam no chão.
- [ ] Block só no chão.
- [ ] Personagem mantém trajetória do pulo durante o ataque aéreo.
- [ ] Hitstop aéreo funciona (ambos congelam brevemente).

**Commit:** `feat(combate): ataques aereos LP e HP liberados no ar`

---

# PARTE 6 — Limites de Câmera por Personagem (Corner)

**Objetivo:** Fighters não saem da tela. Câmera e personagens ficam dentro dos limites
da arena mesmo quando um deles é empurrado para o canto.

## 6.1 FighterBase.gd — clamp de posição lateral

No final de `_physics_process()`, após `move_and_slide()`:

```gdscript
# Clamp horizontal dentro da arena
const MARGEM_LATERAL: float = 40.0
global_position.x = clampf(global_position.x, MARGEM_LATERAL, 1280.0 - MARGEM_LATERAL)
```

## 6.2 Arena.gd — câmera segue mas não sai dos limites

A câmera já tem `limit_left = 0` e `limit_right = 1280`.
Adicionar clamp manual no meio dos dois fighters para não travar na borda:

```gdscript
func _atualizar_camera() -> void:
	if fighter1 == null or fighter2 == null:
		return
	var meio_x: float = (fighter1.global_position.x + fighter2.global_position.x) * 0.5
	meio_x = clampf(meio_x, 200.0, 1080.0)   # câmera nunca vai além das bordas
	camera.global_position.x = lerp(camera.global_position.x, meio_x, 0.1)
```

## ✅ CHECKPOINT 6

- [ ] Personagem empurrado para o canto para na borda visível, não passa.
- [ ] Câmera não mostra área além dos limites da arena.
- [ ] Corner pressure funciona: quem está no canto recebe knockback mas não "some" da tela.

**Commit:** `fix(arena): clamp lateral impede fighters de sair da tela (corner)`

---

# PARTE 7 — Tela de Controles integrada ao Menu Principal

**Objetivo:** `TelaControles.tscn` já existe — conectar ao botão "Controles"
que deve ser adicionado ao `MenuPrincipal.tscn`.

## 7.1 GameManager.gd — adicionar navegação

```gdscript
func ir_para_controles() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/TelaControles.tscn")
```

## 7.2 MenuPrincipal.gd — adicionar botão

```gdscript
@onready var botao_controles: Button = $VBoxContainer/BotaoControles

func _ready() -> void:
	botao_versus.pressed.connect(_on_versus)
	botao_controles.pressed.connect(_on_controles)   # ← ADICIONAR
	botao_opcoes.pressed.connect(_on_opcoes)
	botao_sair.pressed.connect(_on_sair)
	botao_versus.grab_focus()

func _on_controles() -> void:
	GameManager.ir_para_controles()
```

## 7.3 MenuPrincipal.tscn — adicionar BotaoControles

Inserir `Button` com `text = "CONTROLES"` entre BotaoVersus e BotaoOpcoes no VBoxContainer.

## 7.4 TelaControles.gd — garantir botão de volta

```gdscript
# Verificar se já existe ou adicionar:
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.ir_para_menu_principal()
```

## ✅ CHECKPOINT 7

- [ ] Menu principal exibe botão "CONTROLES".
- [ ] Clicar abre a tela de controles.
- [ ] Esc ou botão "Voltar" retorna ao menu.
- [ ] Layout da tela de controles legível (teclas P1 e P2 listadas).

**Commit:** `feat(menu): botao Controles no menu principal — integra TelaControles.tscn`

---

# PARTE 8 — Barra de Super (Medidor de Energia)

**Objetivo:** Medidor que carrega ao dar e receber golpes. Base para specials na v0.2.
Nesta versão apenas acumula e exibe — sem consumo ainda.

## 8.1 ComponenteCombate.gd — adicionar sinais de super

Sem mudanças nesta parte — o sinal `acertou` e `levou_hit` já existem.

## 8.2 FighterBase.gd — adicionar super meter

```gdscript
var super_atual: float = 0.0
const SUPER_MAXIMO: float = 100.0
const SUPER_POR_ATAQUE_ACERTADO: float = 15.0
const SUPER_POR_DANO_RECEBIDO: float = 10.0

signal super_alterado(atual: float, maximo: float)

# Em _ready(), conectar:
combate.acertou.connect(_on_acertou_super)
combate.levou_hit.connect(_on_levou_hit_super)

func _on_acertou_super(_alvo: Node) -> void:
	_ganhar_super(SUPER_POR_ATAQUE_ACERTADO)

func _on_levou_hit_super(_atacante: Node, _dano: int, _kb: Vector2) -> void:
	_ganhar_super(SUPER_POR_DANO_RECEBIDO)

func _ganhar_super(quantidade: float) -> void:
	super_atual = minf(super_atual + quantidade, SUPER_MAXIMO)
	super_alterado.emit(super_atual, SUPER_MAXIMO)

func resetar_super() -> void:
	super_atual = 0.0
	super_alterado.emit(0.0, SUPER_MAXIMO)
```

## 8.3 HUD.gd — adicionar barras de super

```gdscript
@onready var super_p1: ProgressBar = $SuperBar1
@onready var super_p2: ProgressBar = $SuperBar2

# Em conectar_fighters():
super_p1.max_value = FighterBase.SUPER_MAXIMO
super_p1.value = 0.0
super_p2.max_value = FighterBase.SUPER_MAXIMO
super_p2.value = 0.0
p1.super_alterado.connect(func(atual, _max): super_p1.value = atual)
p2.super_alterado.connect(func(atual, _max): super_p2.value = atual)
```

## 8.4 HUD.tscn — adicionar SuperBar1 e SuperBar2

```
HUD
├── SuperBar1 (ProgressBar)  [abaixo de HealthBar1+RoundsP1, fino (h=8px), cor azul/dourada]
└── SuperBar2 (ProgressBar)  [abaixo de HealthBar2+RoundsP2, fino, fill_mode=end_to_begin]
```

- Altura: 8px. Cor: `Color(0.08, 0.74, 1, 1)` (azul brilhante).
- Resetar na troca de round (chamar `fighter.resetar_super()` em `Arena._encerrar_round()`).

## ✅ CHECKPOINT 8 (FINAL v0.1.2)

- [ ] Barra de super aparece abaixo das estrelas de round.
- [ ] Carrega ao acertar golpes (15% por hit).
- [ ] Carrega ao levar dano (10% por hit recebido).
- [ ] Reseta entre rounds.
- [ ] Fica cheia (100) após ~6-7 golpes acertados.
- [ ] Não aparece nenhum erro no console.

**Commit:** `feat(combate): super meter — carrega com hits e dano, base para specials v0.2`

---

# Checkpoints Rápidos de Regressão

Antes de fazer push de cada PARTE, confirmar que o jogo ainda funciona:

- [ ] F5 abre o menu principal.
- [ ] Versus → Seleção → Arena funciona.
- [ ] Ambos os fighters batem, tomam dano, morrem.
- [ ] Round encerra e vai para resultado.
- [ ] Revanche e Menu Principal funcionam.
- [ ] Sem erros no console de output.

---

# Apêndice — Bugs conhecidos NÃO endereçados nesta versão

| Bug | Motivo de adiar |
|---|---|
| Animação de bloco/agachar ausente (fallback para idle) | Precisaria de novos spritesheets ou animações manuais |
| Sprite desalinhado do chão em casos extremos | Requer ajuste manual de `position.y` por personagem no editor |
| Mirror match (VIP vs VIP) com cores idênticas | Adiar para v0.2 quando houver paletas autorais |
| `ControlsManager.gd` não integrado ao remapping | Feature completa — v0.2 |

---

# Próximos passos após v0.1.2 → v0.2

1. **Special moves** — `InputBuffer.gd` com detecção QCF/DP. Consumo do super meter.
2. **Personagens distintos** — `VIPFighter` e `MDKFighter` com frame data e specials únicos.
3. **Sprites autorais** — Substituir Martial Hero 2/3 por arte final de VIP e MDK.
4. **Stage select** — 2-3 arenas com parallax diferentes.
5. **Modo Treino** — Dummy infinito, display de frame data na tela.

---

**FIM DO CLAUDE_2.md — v0.1.2**
