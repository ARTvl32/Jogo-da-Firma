# CLAUDE.md — Los Candidos (Godot 4.6.3 / GDScript)

> **Documento de instrução para o Claude Code.**
> Implementar o jogo de luta arcade *Los Candidos* em partes sequenciais. Cada PARTE termina com um **checkpoint rodável** — o jogo deve abrir no editor e funcionar até o ponto descrito antes de seguir para a próxima PARTE.

---

## 0. Contexto do Projeto

**Jogo:** Los Candidos (provisório) — jogo de luta 2D pixel art arcade.
**Engine:** Godot 4.6.3 (GDScript).
**Inspirações:** Street Fighter II, The King of Fighters '98, Samurai Shodown.
**Devs:** Vinicius Pessoa Parente + José Arthur Vieira Lima.
**Personagens (v0.1):** Vinicius "VIP" Pessoa (shoto/karatê) + Arthur "MDK" Vieira (grappler/streetwear).

### Escopo da v0.1 (esta implementação)

✅ INCLUI:
- Movimento completo (walk, run, jump, crouch).
- 4 botões de ataque: LP / LK / HP / HK (light/heavy punch/kick).
- Sistema de block via **botão dedicado** (KOF-style, sem back-to-block).
- HP, hitstun, blockstun, knockback, hitstop.
- HUD com healthbars, timer, combo counter.
- Fluxo completo de telas: Menu → Character Select → Arena → Resultado → Menu.
- Modo Versus Local (2 humanos).
- Juice: hitstop + screen shake + partículas + hit sparks.
- Sprites grátis de OpenGameArt / itch.io integrados.

❌ NÃO INCLUI (deixar para v0.2+):
- Special moves (QCF/DP/charge) — sem InputBuffer com motion detection.
- Modo Treino com Dummy IA configurável.
- Modo Arcade vs CPU.
- Itens arremessáveis.
- Multiplayer online.

---

## 1. Regras Gerais para o Claude Code

1. **Pare nos checkpoints.** Não pule para a próxima PARTE sem o checkpoint anterior validar.
2. **Idioma:** todo código, comentário, nome de arquivo e mensagem de commit em **português brasileiro**. Identificadores de classe/método podem ficar em inglês quando for convenção da engine (ex: `_physics_process`, `_ready`).
3. **GDScript estático:** sempre tipar variáveis e retornos (`var velocidade: float = 0.0`, `func aplicar_dano(valor: int) -> void`).
4. **Sem `randf()` na lógica de combate.** Toda variação determinística (preparação para netcode futuro).
5. **Toda lógica de gameplay em `_physics_process`**, nunca em `_process`. Visual/UI em `_process`.
6. **Componentes desacoplados.** HealthComponent não conhece CombatComponent diretamente — comunicação por sinais.
7. **Sinais com nomes em português:** `vida_alterada`, `morreu`, `estado_alterado`, `acertou`, `levou_hit`.
8. **Sem assets pesados no repo.** Sprites baixados ficam em `assets/sprites/` e são versionados; mas projetos enormes (raros) podem ir para `.gitignore`.

### Versionamento (Git)

**Sempre que terminar uma PARTE com checkpoint validado, comite.**

```bash
# Inicialização (na PARTE 1)
git init
git branch -M main

# Padrão de commit (Conventional Commits adaptado)
git add .
git commit -m "feat(parte-N): descrição curta do que foi implementado"
```

Prefixos aceitos: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `style:`, `test:`, `assets:`.

Estrutura sugerida de commits ao longo das partes:
- `chore(parte-1): setup inicial do projeto Godot e estrutura de pastas`
- `feat(parte-2): FighterBase com FSM, HealthComponent e CombatComponent`
- `feat(parte-3): VIP e MDK herdando FighterBase`
- `feat(parte-4): Arena com câmera e physics`
- `feat(parte-5): HUD com healthbars, timer e combo counter`
- `feat(parte-6): hitbox/hurtbox com hitstop e knockback`
- `feat(parte-7): juice — screen shake, partículas, hit sparks`
- `assets(parte-8): integração de sprites de OpenGameArt`
- `feat(parte-9): GameManager autoload e fluxo de telas`
- `feat(parte-10): menu principal, character select e tela de resultado`

---

## 2. Configurações Globais do Projeto

**Estas configurações devem ser aplicadas na PARTE 1 e mantidas durante todo o projeto.**

### project.godot — Display
- Viewport: `1280 x 720`
- Stretch Mode: `viewport`
- Stretch Aspect: `keep`
- Renderer: `Compatibility` (pixel-perfect)

### Physics
- Physics tick: `60` (default — confirmar)
- Default Gravity: `980` (ajustaremos depois se preciso)

### Input Map (todas as actions registradas em `Project > Project Settings > Input Map`)

```
# === JOGADOR 1 (WASD + Tecnado lado esquerdo) ===
p1_left            A
p1_right           D
p1_up              W
p1_down            S
p1_lp              U          # Light Punch
p1_lk              J          # Light Kick
p1_hp              I          # Heavy Punch
p1_hk              K          # Heavy Kick
p1_block           O

# === JOGADOR 2 (Setas + Numpad) ===
p2_left            Seta Esquerda
p2_right           Seta Direita
p2_up              Seta Cima
p2_down            Seta Baixo
p2_lp              Numpad 4   # Light Punch
p2_lk              Numpad 1   # Light Kick
p2_hp              Numpad 5   # Heavy Punch
p2_hk              Numpad 2   # Heavy Kick
p2_block           Numpad 3

# === SISTEMA ===
ui_accept          Enter / Espaço
ui_cancel          Esc
ui_pause           Esc
```

> **Layout mnemônico dos botões (P1):**
> ```
> U I       ← Punches  (Light / Heavy)
> J K       ← Kicks    (Light / Heavy)
>     O     ← Block
> ```

### Collision Layers (renomear em `Project Settings > Layer Names > 2D Physics`)

| Layer | Nome    | Uso                                  |
|-------|---------|--------------------------------------|
| 1     | World   | Cenário, chão, paredes invisíveis    |
| 2     | Fighter | Corpo físico (CharacterBody2D)       |
| 3     | Hitbox  | Áreas ofensivas (Area2D)             |
| 4     | Hurtbox | Áreas vulneráveis (Area2D)           |

> Godot indexa layers a partir de 1 na UI mas usa máscara de bits internamente.
> Layer 1 = bit 1, Layer 2 = bit 2, Layer 3 = bit 4, Layer 4 = bit 8.
> No GDD original mencionava "layer=4 mask=8" para Hitbox → significa layer **3** (bit 4) mask **4** (bit 8). Use os nomes da tabela acima como referência.

---

## 3. Estrutura de Pastas (criar na PARTE 1)

```
res://
├── scenes/
│   ├── main/                Main.tscn (ponto de entrada)
│   ├── menus/
│   │   ├── MenuPrincipal.tscn
│   │   ├── SelecaoPersonagem.tscn
│   │   └── TelaResultado.tscn
│   ├── arena/               Arena.tscn
│   ├── fighters/
│   │   ├── FighterBase.tscn
│   │   └── personagens/
│   │       ├── VIP/         VIP.tscn
│   │       └── MDK/         MDK.tscn
│   ├── hud/                 HUD.tscn
│   └── efeitos/
│       ├── EfeitoHit.tscn
│       └── ParticulasHit.tscn
│
├── scripts/
│   ├── componentes/
│   │   ├── ComponenteVida.gd
│   │   ├── ComponenteCombate.gd
│   │   └── ControladorAnimacao.gd
│   ├── combate/
│   │   ├── Hitbox.gd
│   │   └── Hurtbox.gd
│   ├── fighters/
│   │   ├── FighterBase.gd
│   │   └── personagens/
│   │       ├── VIPFighter.gd
│   │       └── MDKFighter.gd
│   ├── ui/
│   │   ├── HUD.gd
│   │   ├── MenuPrincipal.gd
│   │   ├── SelecaoPersonagem.gd
│   │   └── TelaResultado.gd
│   ├── arena/               Arena.gd
│   ├── efeitos/
│   │   ├── EfeitoHit.gd
│   │   ├── ParticulasHit.gd
│   │   └── ScreenShake.gd
│   └── sistemas/
│       └── GameManager.gd   (Autoload singleton)
│
├── assets/
│   ├── sprites/
│   │   ├── fighters/
│   │   │   ├── vip/
│   │   │   └── mdk/
│   │   ├── arena/
│   │   └── efeitos/
│   ├── sounds/
│   │   ├── sfx/
│   │   └── music/
│   └── fonts/
│
├── CLAUDE.md
├── .gitignore
└── project.godot
```

### .gitignore mínimo

```
# Godot 4
.godot/
.import/
export.cfg
export_presets.cfg

# Sistema
.DS_Store
Thumbs.db

# Editor
*.tmp
*.bak
```

---

# PARTE 1 — Setup Inicial do Projeto

**Objetivo:** Projeto Godot rodável, com estrutura de pastas, Input Map, Collision Layers e GameManager autoload. Nenhuma cena funcional ainda — apenas o esqueleto.

## Tarefas

1. Criar o projeto Godot 4.6.3 com renderer `Compatibility`.
2. Aplicar configurações de Display (1280×720, viewport, keep).
3. Criar TODA a estrutura de pastas listada na seção 3.
4. Aplicar o Input Map completo (seção 2).
5. Renomear as 4 Collision Layers (seção 2).
6. Criar `scripts/sistemas/GameManager.gd` (ver código abaixo).
7. Registrar `GameManager` como Autoload em `Project > Project Settings > Autoload` com nome `GameManager`.
8. Criar `scenes/main/Main.tscn` (Node simples com Label central "Los Candidos — Setup OK").
9. Em `Project Settings > Application > Run > Main Scene` apontar para `Main.tscn`.
10. Criar `.gitignore` na raiz.
11. `git init` e fazer o primeiro commit.

## GameManager.gd (esqueleto inicial)

```gdscript
extends Node

# === GameManager ===
# Singleton autoload responsável por:
# - Estado global da partida
# - Transições de cena
# - Configurações persistentes

# Personagens escolhidos pelo P1 e P2 (preenchido na seleção)
var personagem_p1: String = ""
var personagem_p2: String = ""

# Placar (rounds vencidos)
var rounds_p1: int = 0
var rounds_p2: int = 0

# Vencedor da última partida (preenchido pela Arena ao terminar)
var vencedor: int = 0  # 0 = ninguém, 1 = P1, 2 = P2

# Configurações
var rounds_para_vencer: int = 2  # best-of-3

func _ready() -> void:
	print("[GameManager] Inicializado.")

func resetar_partida() -> void:
	rounds_p1 = 0
	rounds_p2 = 0
	vencedor = 0

func ir_para_menu_principal() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/MenuPrincipal.tscn")

func ir_para_selecao() -> void:
	resetar_partida()
	get_tree().change_scene_to_file("res://scenes/menus/SelecaoPersonagem.tscn")

func ir_para_arena() -> void:
	get_tree().change_scene_to_file("res://scenes/arena/Arena.tscn")

func ir_para_resultado() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/TelaResultado.tscn")
```

## ✅ CHECKPOINT 1

**O que validar abrindo o editor:**
- [ ] Projeto abre sem erros no Godot 4.6.3.
- [ ] Estrutura de pastas está criada conforme seção 3.
- [ ] Input Map contém TODAS as 19 actions listadas.
- [ ] Collision Layers 1-4 estão renomeadas.
- [ ] GameManager aparece em Autoload.
- [ ] Ao apertar F5, vê a tela com "Los Candidos — Setup OK".
- [ ] Console imprime `[GameManager] Inicializado.`.

**Commit:** `chore(parte-1): setup inicial do projeto Godot e estrutura de pastas`

---

# PARTE 2 — Componentes Base (Vida, Combate, Animação)

**Objetivo:** Componentes de fighter implementados e prontos para serem usados pela FighterBase. Sem cena ainda — apenas scripts.

## 2.1 ComponenteVida.gd

```gdscript
class_name ComponenteVida
extends Node

# === ComponenteVida ===
# Gerencia HP do fighter. Emite sinais quando vida muda ou chega a 0.

signal vida_alterada(vida_atual: int, vida_maxima: int)
signal morreu

@export var vida_maxima: int = 1000

var vida_atual: int

func _ready() -> void:
	vida_atual = vida_maxima
	vida_alterada.emit(vida_atual, vida_maxima)

func aplicar_dano(quantidade: int) -> void:
	if vida_atual <= 0:
		return
	vida_atual = max(0, vida_atual - quantidade)
	vida_alterada.emit(vida_atual, vida_maxima)
	if vida_atual == 0:
		morreu.emit()

func curar(quantidade: int) -> void:
	vida_atual = min(vida_maxima, vida_atual + quantidade)
	vida_alterada.emit(vida_atual, vida_maxima)

func resetar() -> void:
	vida_atual = vida_maxima
	vida_alterada.emit(vida_atual, vida_maxima)

func esta_vivo() -> bool:
	return vida_atual > 0
```

## 2.2 ComponenteCombate.gd

```gdscript
class_name ComponenteCombate
extends Node

# === ComponenteCombate ===
# Máquina de estados do fighter (FSM).
# Responsável por validar transições e ativar/desativar hitboxes.

signal estado_alterado(novo_estado: int)
signal acertou(alvo: Node)
signal levou_hit(atacante: Node, dano: int, knockback: Vector2)

enum Estado {
	IDLE,
	WALK,
	RUN,
	JUMP,
	FALL,
	CROUCH,
	ATTACK_LP,
	ATTACK_LK,
	ATTACK_HP,
	ATTACK_HK,
	BLOCK,
	HURT,
	DEATH
}

# Frame data por tipo de ataque (em frames de 60 FPS).
# Estrutura: { startup, active, recovery, dano, hitstun, blockstun, knockback }
const FRAME_DATA: Dictionary = {
	Estado.ATTACK_LP: { "startup": 3, "active": 2, "recovery": 6, "dano": 60, "hitstun": 12, "blockstun": 8, "knockback": Vector2(120, 0) },
	Estado.ATTACK_LK: { "startup": 4, "active": 3, "recovery": 8, "dano": 70, "hitstun": 14, "blockstun": 10, "knockback": Vector2(140, 0) },
	Estado.ATTACK_HP: { "startup": 8, "active": 3, "recovery": 14, "dano": 120, "hitstun": 20, "blockstun": 14, "knockback": Vector2(260, -80) },
	Estado.ATTACK_HK: { "startup": 10, "active": 4, "recovery": 18, "dano": 140, "hitstun": 22, "blockstun": 16, "knockback": Vector2(300, -100) },
}

var estado_atual: int = Estado.IDLE
var frames_no_estado: int = 0
var hitbox_ativa: bool = false

func _ready() -> void:
	mudar_estado(Estado.IDLE)

func mudar_estado(novo: int) -> void:
	if novo == estado_atual:
		return
	estado_atual = novo
	frames_no_estado = 0
	estado_alterado.emit(novo)

func tick() -> void:
	# Chamado em _physics_process do FighterBase
	frames_no_estado += 1
	_atualizar_hitbox_por_frame_data()

func _atualizar_hitbox_por_frame_data() -> void:
	if not FRAME_DATA.has(estado_atual):
		hitbox_ativa = false
		return
	var fd: Dictionary = FRAME_DATA[estado_atual]
	var startup: int = fd["startup"]
	var active: int = fd["active"]
	hitbox_ativa = frames_no_estado >= startup and frames_no_estado < startup + active

func ataque_terminou() -> bool:
	if not FRAME_DATA.has(estado_atual):
		return true
	var fd: Dictionary = FRAME_DATA[estado_atual]
	var total: int = fd["startup"] + fd["active"] + fd["recovery"]
	return frames_no_estado >= total

func eh_estado_de_ataque(e: int) -> bool:
	return e in [Estado.ATTACK_LP, Estado.ATTACK_LK, Estado.ATTACK_HP, Estado.ATTACK_HK]

func pode_se_mover() -> bool:
	return estado_atual in [Estado.IDLE, Estado.WALK, Estado.RUN]

func pode_atacar() -> bool:
	return estado_atual in [Estado.IDLE, Estado.WALK, Estado.RUN, Estado.JUMP, Estado.FALL, Estado.CROUCH]

func esta_bloqueando() -> bool:
	return estado_atual == Estado.BLOCK
```

## 2.3 ControladorAnimacao.gd

```gdscript
class_name ControladorAnimacao
extends Node

# === ControladorAnimacao ===
# Mapeia estado do ComponenteCombate para animações no AnimatedSprite2D.

signal animacao_terminou

@export var sprite_path: NodePath
var sprite: AnimatedSprite2D

const MAPA_ANIMACAO: Dictionary = {
	ComponenteCombate.Estado.IDLE:       "idle",
	ComponenteCombate.Estado.WALK:       "walk",
	ComponenteCombate.Estado.RUN:        "run",
	ComponenteCombate.Estado.JUMP:       "jump",
	ComponenteCombate.Estado.FALL:       "fall",
	ComponenteCombate.Estado.CROUCH:     "crouch",
	ComponenteCombate.Estado.ATTACK_LP:  "attack_lp",
	ComponenteCombate.Estado.ATTACK_LK:  "attack_lk",
	ComponenteCombate.Estado.ATTACK_HP:  "attack_hp",
	ComponenteCombate.Estado.ATTACK_HK:  "attack_hk",
	ComponenteCombate.Estado.BLOCK:      "block",
	ComponenteCombate.Estado.HURT:       "hurt",
	ComponenteCombate.Estado.DEATH:      "death",
}

func _ready() -> void:
	if sprite_path:
		sprite = get_node(sprite_path)
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)

func tocar_para_estado(estado: int) -> void:
	if sprite == null:
		return
	var nome: String = MAPA_ANIMACAO.get(estado, "idle")
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(nome):
		if sprite.animation != nome:
			sprite.play(nome)
	else:
		# Fallback: usa idle se animação não existir (placeholder safe)
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

func _on_animation_finished() -> void:
	animacao_terminou.emit()
```

## ✅ CHECKPOINT 2

**O que validar:**
- [ ] Os 3 scripts existem em `scripts/componentes/`.
- [ ] Nenhum erro no editor (verificar painel de erros).
- [ ] Os scripts compilam (basta abrir cada um — Godot reporta erro se houver).
- [ ] Main.tscn ainda roda normalmente.

**Commit:** `feat(parte-2): componentes de vida, combate e animação`

---

# PARTE 3 — FighterBase (cena + script base)

**Objetivo:** Cena base de fighter funcional, com movimento, pulo, agachamento, ataques e block — usando placeholders coloridos como sprite. Reage a inputs via `player_index`.

## 3.1 Hitbox.gd e Hurtbox.gd

`scripts/combate/Hitbox.gd`:

```gdscript
class_name Hitbox
extends Area2D

# === Hitbox ===
# Área ofensiva ativa durante frames de ataque.
# Detecta Hurtboxes inimigas e dispara sinal.

signal hit_conectado(hurtbox: Hurtbox)

@export var dono: Node  # Fighter dono dessa hitbox

func _ready() -> void:
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)
	# Layer: Hitbox (3), Mask: Hurtbox (4)
	collision_layer = 0b0100  # bit 3
	collision_mask  = 0b1000  # bit 4

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var hb: Hurtbox = area
		# Evita auto-hit (hitbox e hurtbox do mesmo fighter)
		if hb.dono == dono:
			return
		hit_conectado.emit(hb)

func ativar() -> void:
	monitoring = true
	$CollisionShape2D.disabled = false

func desativar() -> void:
	monitoring = false
	$CollisionShape2D.disabled = true
```

`scripts/combate/Hurtbox.gd`:

```gdscript
class_name Hurtbox
extends Area2D

# === Hurtbox ===
# Área vulnerável do fighter. Passiva — apenas é detectada.

@export var dono: Node

func _ready() -> void:
	monitoring = false
	monitorable = true
	collision_layer = 0b1000  # bit 4 (Hurtbox)
	collision_mask  = 0        # não monitora nada
```

## 3.2 FighterBase.gd

`scripts/fighters/FighterBase.gd`:

```gdscript
class_name FighterBase
extends CharacterBody2D

# === FighterBase ===
# Classe base de todos os personagens jogáveis.
# Inputs roteados via player_index (1 ou 2).

@export var player_index: int = 1
@export var velocidade_andar: float = 200.0
@export var velocidade_correr: float = 380.0
@export var forca_pulo: float = -700.0
@export var olhando_direita: bool = true

# Stats sobrescritos por subclasses
@export var nome_exibicao: String = "Fighter"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var vida: ComponenteVida = $ComponenteVida
@onready var combate: ComponenteCombate = $ComponenteCombate
@onready var animacao: ControladorAnimacao = $ControladorAnimacao
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox

# Estado interno
var hitstop_frames: int = 0
var hitstun_frames: int = 0
var blockstun_frames: int = 0
var conhece_oponente: FighterBase = null

# Gravidade lida do project settings
var gravidade: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

# Detecção de duplo-tap para run
var ultimo_tap_direcao: int = 0  # 1 = direita, -1 = esquerda, 0 = nenhum
var frames_desde_ultimo_tap: int = 999
const JANELA_DUPLO_TAP: int = 15  # frames

func _ready() -> void:
	# Conecta sinais
	hitbox.dono = self
	hurtbox.dono = self
	hitbox.hit_conectado.connect(_on_hit_conectado)
	combate.estado_alterado.connect(_on_estado_alterado)
	vida.morreu.connect(_on_morreu)
	# Animação inicial
	animacao.tocar_para_estado(combate.estado_atual)
	hitbox.desativar()

func _physics_process(delta: float) -> void:
	# Hitstop congela tudo — não processa input nem aplica velocidade
	if hitstop_frames > 0:
		hitstop_frames -= 1
		return

	# Atualiza face em direção ao oponente quando no chão e neutro
	_atualizar_facing()

	# Decrementa stuns
	if hitstun_frames > 0:
		hitstun_frames -= 1
		if hitstun_frames == 0 and combate.estado_atual == ComponenteCombate.Estado.HURT:
			combate.mudar_estado(ComponenteCombate.Estado.IDLE)
	if blockstun_frames > 0:
		blockstun_frames -= 1
		if blockstun_frames == 0 and combate.estado_atual == ComponenteCombate.Estado.BLOCK:
			# Continua em block se ainda segurando, ou volta a idle
			if not _input_pressionado("block"):
				combate.mudar_estado(ComponenteCombate.Estado.IDLE)

	# Aplica gravidade
	if not is_on_floor():
		velocity.y += gravidade * delta

	# Processa input se livre
	if hitstun_frames == 0 and blockstun_frames == 0:
		_processar_input()

	# Atualiza FSM
	combate.tick()
	_atualizar_hitbox_por_combate()
	_atualizar_estado_movimento()

	# Aplica movimento
	move_and_slide()

	frames_desde_ultimo_tap += 1

func _processar_input() -> void:
	# Não aceita input durante ataques (sem cancelamento na v0.1)
	if combate.eh_estado_de_ataque(combate.estado_atual):
		if combate.ataque_terminou():
			combate.mudar_estado(ComponenteCombate.Estado.IDLE)
			hitbox.desativar()
		else:
			return

	# Block tem prioridade — pode entrar de qualquer estado terrestre
	if _input_pressionado("block") and is_on_floor():
		combate.mudar_estado(ComponenteCombate.Estado.BLOCK)
		velocity.x = 0
		return

	# Ataques (chão e ar)
	if _input_just_pressed("lp"):
		_iniciar_ataque(ComponenteCombate.Estado.ATTACK_LP)
		return
	if _input_just_pressed("lk"):
		_iniciar_ataque(ComponenteCombate.Estado.ATTACK_LK)
		return
	if _input_just_pressed("hp"):
		_iniciar_ataque(ComponenteCombate.Estado.ATTACK_HP)
		return
	if _input_just_pressed("hk"):
		_iniciar_ataque(ComponenteCombate.Estado.ATTACK_HK)
		return

	# Pulo
	if _input_just_pressed("up") and is_on_floor():
		velocity.y = forca_pulo
		combate.mudar_estado(ComponenteCombate.Estado.JUMP)
		return

	# No ar: só ajusta velocidade horizontal levemente, não muda estado
	if not is_on_floor():
		var dir_ar: float = _direcao_horizontal()
		velocity.x = dir_ar * velocidade_andar
		return

	# Agachar
	if _input_pressionado("down"):
		combate.mudar_estado(ComponenteCombate.Estado.CROUCH)
		velocity.x = 0
		return

	# Movimento horizontal
	var dir: float = _direcao_horizontal()
	if dir != 0.0:
		_detectar_duplo_tap(int(sign(dir)))
		var correndo: bool = ultimo_tap_direcao == int(sign(dir)) and frames_desde_ultimo_tap < JANELA_DUPLO_TAP * 4
		if correndo:
			velocity.x = dir * velocidade_correr
			combate.mudar_estado(ComponenteCombate.Estado.RUN)
		else:
			velocity.x = dir * velocidade_andar
			combate.mudar_estado(ComponenteCombate.Estado.WALK)
	else:
		velocity.x = 0
		combate.mudar_estado(ComponenteCombate.Estado.IDLE)

func _iniciar_ataque(estado_ataque: int) -> void:
	combate.mudar_estado(estado_ataque)
	velocity.x = 0  # ataques no chão param o movimento

func _atualizar_hitbox_por_combate() -> void:
	if combate.hitbox_ativa:
		hitbox.ativar()
	else:
		hitbox.desativar()

func _atualizar_estado_movimento() -> void:
	# Transições JUMP → FALL e FALL → IDLE
	var e: int = combate.estado_atual
	if not is_on_floor():
		if velocity.y > 0 and e == ComponenteCombate.Estado.JUMP:
			combate.mudar_estado(ComponenteCombate.Estado.FALL)
	else:
		if e == ComponenteCombate.Estado.FALL or e == ComponenteCombate.Estado.JUMP:
			combate.mudar_estado(ComponenteCombate.Estado.IDLE)

func _atualizar_facing() -> void:
	if conhece_oponente == null:
		return
	if not is_on_floor():
		return
	if not combate.pode_se_mover():
		return
	var deveria_olhar_direita: bool = conhece_oponente.global_position.x >= global_position.x
	if deveria_olhar_direita != olhando_direita:
		olhando_direita = deveria_olhar_direita
		sprite.flip_h = not olhando_direita

func _direcao_horizontal() -> float:
	var esq: bool = _input_pressionado("left")
	var dir: bool = _input_pressionado("right")
	if esq and not dir:
		return -1.0
	if dir and not esq:
		return 1.0
	return 0.0

func _detectar_duplo_tap(direcao: int) -> void:
	if not _input_just_pressed("right") and not _input_just_pressed("left"):
		return
	if ultimo_tap_direcao == direcao and frames_desde_ultimo_tap < JANELA_DUPLO_TAP:
		# Confirma duplo-tap: extende janela para sustentar o run
		frames_desde_ultimo_tap = 0
	else:
		ultimo_tap_direcao = direcao
		frames_desde_ultimo_tap = 0

# === Wrappers de input por player_index ===

func _prefixo() -> String:
	return "p1_" if player_index == 1 else "p2_"

func _input_pressionado(acao: String) -> bool:
	return Input.is_action_pressed(_prefixo() + acao)

func _input_just_pressed(acao: String) -> bool:
	return Input.is_action_just_pressed(_prefixo() + acao)

# === Recebendo hits ===

func _on_hit_conectado(hurtbox_inimiga: Hurtbox) -> void:
	var alvo: FighterBase = hurtbox_inimiga.dono as FighterBase
	if alvo == null:
		return
	# Desativa hitbox para garantir 1 hit por ataque
	hitbox.desativar()
	# Lê frame data do ataque atual
	var fd: Dictionary = ComponenteCombate.FRAME_DATA.get(combate.estado_atual, {})
	if fd.is_empty():
		return
	var dano: int = fd["dano"]
	var hitstun: int = fd["hitstun"]
	var blockstun: int = fd["blockstun"]
	var knockback: Vector2 = fd["knockback"]
	# Sentido do knockback baseado em quem ataca
	if not olhando_direita:
		knockback.x = -knockback.x
	# Envia para o alvo
	alvo.receber_hit(self, dano, hitstun, blockstun, knockback)
	combate.acertou.emit(alvo)

func receber_hit(atacante: FighterBase, dano: int, hitstun: int, blockstun: int, knockback: Vector2) -> void:
	if combate.estado_atual == ComponenteCombate.Estado.DEATH:
		return
	# Bloqueando?
	if combate.esta_bloqueando():
		# Chip damage: 10% só para specials (sem specials na v0.1 → sem chip)
		blockstun_frames = blockstun
		velocity.x = knockback.x * 0.3  # empurrão menor ao bloquear
		_aplicar_hitstop(6)
		return
	# Aplica dano e hitstun
	vida.aplicar_dano(dano)
	hitstun_frames = hitstun
	velocity = knockback
	combate.mudar_estado(ComponenteCombate.Estado.HURT)
	_aplicar_hitstop(8)
	combate.levou_hit.emit(atacante, dano, knockback)

func _aplicar_hitstop(frames: int) -> void:
	hitstop_frames = frames

func _on_estado_alterado(novo: int) -> void:
	animacao.tocar_para_estado(novo)

func _on_morreu() -> void:
	combate.mudar_estado(ComponenteCombate.Estado.DEATH)
	hitbox.desativar()

func definir_oponente(outro: FighterBase) -> void:
	conhece_oponente = outro
```

## 3.3 FighterBase.tscn

**Estrutura da cena (criar no editor):**

```
FighterBase (CharacterBody2D)              [script: FighterBase.gd]
├── CollisionShape2D                       [shape: RectangleShape2D, size: 60×120]
├── AnimatedSprite2D                       [com SpriteFrames placeholder — ver abaixo]
├── ComponenteVida (Node)                  [script: ComponenteVida.gd]
├── ComponenteCombate (Node)               [script: ComponenteCombate.gd]
├── ControladorAnimacao (Node)             [script: ControladorAnimacao.gd]
│   └── sprite_path → ../AnimatedSprite2D
├── Hitbox (Area2D)                        [script: Hitbox.gd]
│   └── CollisionShape2D                   [shape: RectangleShape2D, size: 80×40, position: x=60]
└── Hurtbox (Area2D)                       [script: Hurtbox.gd]
    └── CollisionShape2D                   [shape: RectangleShape2D, size: 60×120]
```

### SpriteFrames placeholder (para a v0.1 inicial até integrar sprites reais)

Crie um `SpriteFrames` no AnimatedSprite2D com **uma animação `idle`** contendo um retângulo colorido de 80×120 px. As demais animações (`walk`, `run`, `jump`, `fall`, `crouch`, `attack_lp`, `attack_lk`, `attack_hp`, `attack_hk`, `block`, `hurt`, `death`) podem reutilizar o mesmo frame com cor diferente — basta criar a animação com nome correto. O ControladorAnimacao tem fallback para idle se faltar.

**Gerar placeholders programaticamente (opcional):** rodar um script EditorTool que cria PlaceholderTexture2D de 80×120 com cores diferentes por animação. Para a PARTE 3, usar quadrados brancos chapados já funciona.

## ✅ CHECKPOINT 3

**Antes de testar:** crie uma cena de teste rápida (`scenes/main/Main.tscn`) com:
- Um chão (StaticBody2D + CollisionShape2D retangular cobrindo a parte inferior).
- Dois nós instanciando `FighterBase.tscn` lado a lado, um com `player_index = 1` e outro com `player_index = 2`.
- Conectar `definir_oponente` no `_ready` do script Main.

**Valide:**
- [ ] P1 (WASD) anda, corre (duplo-tap D), pula (W), agacha (S).
- [ ] P2 (setas) anda, corre (duplo-tap →), pula (↑), agacha (↓).
- [ ] Apertar U/J/I/K (P1) ou Numpad 4/1/5/2 (P2) muda a animação para attack_lp/lk/hp/hk.
- [ ] Apertar O (P1) ou Numpad 3 (P2) entra em block.
- [ ] Os fighters caem por gravidade e param no chão.
- [ ] Os fighters viram automaticamente para o lado do oponente.
- [ ] **Hit ainda não causa dano** (Arena vai conectar isso na PARTE 4).

**Commit:** `feat(parte-3): FighterBase com FSM, movimento e ataques normais`

---

# PARTE 4 — Personagens (VIP e MDK)

**Objetivo:** Criar `VIPFighter.gd` e `MDKFighter.gd` herdando de `FighterBase`, com stats próprios. Criar as cenas `.tscn` correspondentes herdando de `FighterBase.tscn` (Inherited Scene).

## 4.1 VIPFighter.gd

```gdscript
class_name VIPFighter
extends FighterBase

# === Vinicius "VIP" Pessoa ===
# Arquétipo: Shoto / All-rounder (karatê)
# Velocidade alta, alcance curto, dano médio.

func _ready() -> void:
	nome_exibicao = "VIP"
	velocidade_andar = 220.0
	velocidade_correr = 420.0
	forca_pulo = -720.0
	vida.vida_maxima = 1000
	super._ready()
```

## 4.2 MDKFighter.gd

```gdscript
class_name MDKFighter
extends FighterBase

# === Arthur "MDK" Vieira ===
# Arquétipo: Grappler / Pressão (streetwear)
# Velocidade baixa, alcance curto, dano alto.

func _ready() -> void:
	nome_exibicao = "MDK"
	velocidade_andar = 160.0
	velocidade_correr = 300.0
	forca_pulo = -680.0
	vida.vida_maxima = 1100  # grappler mais resistente
	super._ready()
```

## 4.3 Cenas VIP.tscn e MDK.tscn

Use **"New Inherited Scene"** com base em `FighterBase.tscn`:

1. `scene/fighters/personagens/VIP/VIP.tscn` — herdada, trocar script raiz para `VIPFighter.gd`.
2. `scene/fighters/personagens/MDK/MDK.tscn` — herdada, trocar script raiz para `MDKFighter.gd`.

**Diferenciação visual placeholder:** mude a Modulate do AnimatedSprite2D:
- VIP → cor `#3F88FF` (azul)
- MDK → cor `#E64545` (vermelho)

## ✅ CHECKPOINT 4

- [ ] VIP e MDK aparecem como cenas no FileSystem.
- [ ] Ambas instanciam no Main.tscn (substituir os FighterBase do checkpoint 3 por VIP e MDK).
- [ ] VIP é visivelmente mais rápido que MDK ao andar.
- [ ] MDK tem barra de vida maior (1100 vs 1000 — confirmar via debug print do `vida.vida_maxima`).
- [ ] Cores placeholder distinguem os dois.

**Commit:** `feat(parte-4): personagens VIP e MDK herdando FighterBase`

---

# PARTE 5 — Arena (cenário + câmera + conexão de combate)

**Objetivo:** Arena funcional com chão, câmera Average, dois fighters conectados, e dano de fato aplicado entre eles.

## 5.1 Arena.gd

```gdscript
class_name Arena
extends Node2D

# === Arena ===
# Cena de combate. Gerencia round, timer, fighters e câmera.

signal round_terminou(vencedor: int)

@export var duracao_round_segundos: int = 99

@onready var fighter1: FighterBase = $Fighters/Fighter1
@onready var fighter2: FighterBase = $Fighters/Fighter2
@onready var camera: Camera2D = $Camera2D
@onready var hud: Control = $HUD
@onready var timer_round: Timer = $TimerRound

var tempo_restante: int = 99
var round_em_andamento: bool = false

func _ready() -> void:
	tempo_restante = duracao_round_segundos
	# Conecta fighters
	fighter1.definir_oponente(fighter2)
	fighter2.definir_oponente(fighter1)
	fighter1.vida.morreu.connect(func(): _ao_fighter_morrer(2))
	fighter2.vida.morreu.connect(func(): _ao_fighter_morrer(1))
	# Configura HUD
	if hud and hud.has_method("conectar_fighters"):
		hud.conectar_fighters(fighter1, fighter2)
	# Timer
	timer_round.timeout.connect(_on_timer_tick)
	# Inicia round
	_iniciar_round()

func _process(_delta: float) -> void:
	_atualizar_camera()

func _iniciar_round() -> void:
	round_em_andamento = true
	tempo_restante = duracao_round_segundos
	timer_round.start(1.0)

func _on_timer_tick() -> void:
	if not round_em_andamento:
		return
	tempo_restante -= 1
	if hud and hud.has_method("atualizar_timer"):
		hud.atualizar_timer(tempo_restante)
	if tempo_restante <= 0:
		_resolver_round_por_timeout()

func _resolver_round_por_timeout() -> void:
	var vencedor: int = 0
	if fighter1.vida.vida_atual > fighter2.vida.vida_atual:
		vencedor = 1
	elif fighter2.vida.vida_atual > fighter1.vida.vida_atual:
		vencedor = 2
	# else: double draw — vencedor = 0
	_encerrar_round(vencedor)

func _ao_fighter_morrer(quem_venceu: int) -> void:
	if not round_em_andamento:
		return
	_encerrar_round(quem_venceu)

func _encerrar_round(vencedor: int) -> void:
	round_em_andamento = false
	timer_round.stop()
	if vencedor == 1:
		GameManager.rounds_p1 += 1
	elif vencedor == 2:
		GameManager.rounds_p2 += 1
	round_terminou.emit(vencedor)
	# Aguarda 2 segundos antes de decidir próximo passo
	await get_tree().create_timer(2.0).timeout
	if GameManager.rounds_p1 >= GameManager.rounds_para_vencer:
		GameManager.vencedor = 1
		GameManager.ir_para_resultado()
	elif GameManager.rounds_p2 >= GameManager.rounds_para_vencer:
		GameManager.vencedor = 2
		GameManager.ir_para_resultado()
	else:
		# Próximo round — recarrega a arena
		get_tree().reload_current_scene()

func _atualizar_camera() -> void:
	# Average: posiciona a câmera no ponto médio horizontal dos dois fighters
	var meio_x: float = (fighter1.global_position.x + fighter2.global_position.x) * 0.5
	camera.global_position.x = lerp(camera.global_position.x, meio_x, 0.1)
```

## 5.2 Arena.tscn

```
Arena (Node2D)                              [Arena.gd]
├── Background (ColorRect ou TextureRect)   [tamanho 1280×720, cor placeholder]
├── Floor (StaticBody2D)
│   └── CollisionShape2D                    [RectangleShape2D, size: 2000×40, position y=300]
├── Fighters (Node2D)
│   ├── Fighter1 (VIP.tscn — instância)     [position: (480, 200), player_index=1]
│   └── Fighter2 (MDK.tscn — instância)     [position: (800, 200), player_index=2]
├── Camera2D                                [ver config abaixo]
├── TimerRound (Timer)                      [one_shot=false, autostart=false]
└── HUD (placeholder por enquanto — Control vazio)
```

### Configuração da Camera2D (Inspector)

| Propriedade           | Valor                        |
|-----------------------|------------------------------|
| Anchor Mode           | Drag Center                  |
| Limit Left            | 0                            |
| Limit Right           | 1280                         |
| Limit Top             | -200                         |
| Limit Bottom          | 720                          |
| Drag Horizontal Enabled | true                       |
| Drag Vertical Enabled | false                        |
| Position Smoothing Enabled | true                    |
| Position Smoothing Speed | 5.0                       |
| Zoom                  | (1, 1)                       |

## ✅ CHECKPOINT 5

- [ ] Abrir Arena.tscn diretamente (F6) inicia o combate com VIP e MDK.
- [ ] Ao atacar com sucesso, o oponente recebe dano (debug print do `vida.vida_atual` confirma).
- [ ] Hitstop visível ao acertar (~6 frames de congelamento).
- [ ] Knockback empurra o oponente atingido para trás.
- [ ] Block (botão O / Numpad 3) reduz o dano (na v0.1 sem chip, dano = 0 ao bloquear) e empurra menos.
- [ ] Câmera segue o ponto médio dos fighters.
- [ ] Ao zerar HP de um fighter, depois de 2s a cena recarrega para o próximo round (e GameManager incrementa o placar).
- [ ] Timer decrementa de 99 (debug print por enquanto).

**Commit:** `feat(parte-5): Arena com câmera, conexão de fighters e dano funcional`

---

# PARTE 6 — HUD (healthbars, timer, combo counter)

**Objetivo:** UI funcional sobre a arena. Healthbars de P1 e P2 que esvaziam corretamente, timer central, combo counter por jogador.

## 6.1 HUD.gd

```gdscript
class_name HUD
extends Control

# === HUD ===
# Interface durante combate.

@onready var bar_p1: ProgressBar = $HealthBar1
@onready var bar_p2: ProgressBar = $HealthBar2
@onready var label_timer: Label = $TimerLabel
@onready var combo_p1: Label = $ComboLabel1
@onready var combo_p2: Label = $ComboLabel2

var contador_combo_p1: int = 0
var contador_combo_p2: int = 0
var frames_desde_ultimo_hit_p1: int = 999
var frames_desde_ultimo_hit_p2: int = 999

const FRAMES_RESET_COMBO: int = 30  # 0.5s a 60fps

func _ready() -> void:
	combo_p1.text = ""
	combo_p2.text = ""

func _process(_delta: float) -> void:
	frames_desde_ultimo_hit_p1 += 1
	frames_desde_ultimo_hit_p2 += 1
	if frames_desde_ultimo_hit_p1 > FRAMES_RESET_COMBO and contador_combo_p1 > 0:
		contador_combo_p1 = 0
		combo_p1.text = ""
	if frames_desde_ultimo_hit_p2 > FRAMES_RESET_COMBO and contador_combo_p2 > 0:
		contador_combo_p2 = 0
		combo_p2.text = ""

func conectar_fighters(p1: FighterBase, p2: FighterBase) -> void:
	# Health bars
	bar_p1.max_value = p1.vida.vida_maxima
	bar_p1.value = p1.vida.vida_atual
	bar_p2.max_value = p2.vida.vida_maxima
	bar_p2.value = p2.vida.vida_atual
	p1.vida.vida_alterada.connect(func(atual, _max): bar_p1.value = atual)
	p2.vida.vida_alterada.connect(func(atual, _max): bar_p2.value = atual)
	# Combo counter — quando p1 acerta, incrementa combo_p1
	p1.combate.acertou.connect(func(_alvo): _registrar_hit(1))
	p2.combate.acertou.connect(func(_alvo): _registrar_hit(2))

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
```

## 6.2 HUD.tscn

```
HUD (Control)                              [anchor full rect, mouse filter: ignore]
├── HealthBar1 (ProgressBar)               [top-left, 500×30, position (40, 30), show_percentage=false]
├── HealthBar2 (ProgressBar)               [top-right, 500×30, position (740, 30), fill_mode=fill_end_to_begin]
├── TimerLabel (Label)                     [centro topo, fonte grande, "99" como exemplo]
├── ComboLabel1 (Label)                    [abaixo da HealthBar1, fonte média, vazio inicial]
└── ComboLabel2 (Label)                    [abaixo da HealthBar2, fonte média, vazio inicial]
```

### Configurações de estilo (rápido)
- HealthBar1 cor: verde (degradê para amarelo/vermelho em iteração futura).
- HealthBar2: igual mas com `fill_mode = FILL_END_TO_BEGIN` (esvazia para a direita).
- Fonte da TimerLabel: a maior padrão do Godot. ComboLabels: médias.
- ComboLabel cor: amarelo (`#F1C40F`).

### Integração com Arena.tscn
Substituir o `HUD` placeholder em `Arena.tscn` por uma instância de `HUD.tscn`. O `Arena.gd` já chama `hud.conectar_fighters()` e `hud.atualizar_timer()` se os métodos existirem.

## ✅ CHECKPOINT 6

- [ ] Healthbars aparecem nas duas pontas superiores e esvaziam ao receber dano.
- [ ] Timer central conta de 99 a 0.
- [ ] Combo counter aparece com "2 HITS" / "3 HITS" ao encadear ataques.
- [ ] Combo zera após ~0.5s sem novos acertos.
- [ ] Round termina por timeout corretamente quando o timer chega a 0.

**Commit:** `feat(parte-6): HUD com healthbars, timer e combo counter`

---

# PARTE 7 — Juice (Hitstop, Screen Shake, Partículas)

**Objetivo:** Polir feedback de impacto — hitstop já existe básico, agora screen shake quando heavy hit, hit sparks no ponto de contato, partículas de impacto.

## 7.1 ScreenShake.gd

```gdscript
class_name ScreenShake
extends Node

# === ScreenShake ===
# Anexo a uma Camera2D. Aplica deslocamento aleatório em offset.

@export var camera_path: NodePath
var camera: Camera2D

var trauma: float = 0.0
const TRAUMA_DECAIMENTO: float = 5.0
const FORCA_MAX: float = 12.0
const ROTACAO_MAX: float = 0.05

# RNG seedada com 0 — determinístico
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 42
	if camera_path:
		camera = get_node(camera_path)

func _process(delta: float) -> void:
	if camera == null:
		return
	if trauma > 0.0:
		trauma = max(trauma - TRAUMA_DECAIMENTO * delta, 0.0)
		var amount: float = trauma * trauma
		camera.offset = Vector2(
			rng.randf_range(-1.0, 1.0) * FORCA_MAX * amount,
			rng.randf_range(-1.0, 1.0) * FORCA_MAX * amount
		)
		camera.rotation = rng.randf_range(-1.0, 1.0) * ROTACAO_MAX * amount
	else:
		camera.offset = Vector2.ZERO
		camera.rotation = 0.0

func tremer(forca: float) -> void:
	trauma = min(trauma + forca, 1.0)
```

> Nota: este shake usa RNG seedada. Para a v0.1 isso é OK — quando entrar netcode, o trauma deve ser sincronizado e a RNG seedada por frame.

## 7.2 EfeitoHit.tscn e EfeitoHit.gd

`scripts/efeitos/EfeitoHit.gd`:

```gdscript
class_name EfeitoHit
extends Node2D

# === EfeitoHit ===
# Spark visual instanciado no ponto de contato.

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	sprite.play("default")
	sprite.animation_finished.connect(queue_free)
```

Cena: `EfeitoHit.tscn` = Node2D + AnimatedSprite2D com animação `default` (placeholder: círculo amarelo brilhando 4-5 frames, não-looping).

## 7.3 ParticulasHit.tscn

Node2D + GPUParticles2D configurado com:
- emitting = false (controlado por código)
- one_shot = true
- explosiveness = 1.0
- amount = 12
- lifetime = 0.4
- direction = (1, 0), spread = 180
- initial velocity: min 200, max 400
- color: branco/amarelo

`scripts/efeitos/ParticulasHit.gd`:

```gdscript
class_name ParticulasHit
extends Node2D

@onready var particulas: GPUParticles2D = $GPUParticles2D

func _ready() -> void:
	particulas.emitting = true
	await get_tree().create_timer(particulas.lifetime + 0.1).timeout
	queue_free()
```

## 7.4 Integração na Arena

Adicionar à Arena.gd:

```gdscript
# Adicionar como filho de Arena:
@onready var screen_shake: ScreenShake = $Camera2D/ScreenShake  # Node filho da câmera

# Adicionar à árvore:
# Arena
# ├── Camera2D
# │   └── ScreenShake (Node)   [script: ScreenShake.gd, camera_path: ..]

const EFEITO_HIT_SCENE: PackedScene = preload("res://scenes/efeitos/EfeitoHit.tscn")
const PARTICULAS_HIT_SCENE: PackedScene = preload("res://scenes/efeitos/ParticulasHit.tscn")

func _ready() -> void:
	# ... código existente ...
	# Conectar sinais de acerto para spawnar efeitos
	fighter1.combate.acertou.connect(_on_acerto.bind(fighter1))
	fighter2.combate.acertou.connect(_on_acerto.bind(fighter2))

func _on_acerto(_alvo: Node, atacante: FighterBase) -> void:
	# Posição: meio entre atacante e oponente
	var pos: Vector2 = (atacante.global_position + atacante.conhece_oponente.global_position) * 0.5
	pos.y -= 60  # altura do tronco
	# Spark
	var spark: Node2D = EFEITO_HIT_SCENE.instantiate()
	spark.global_position = pos
	add_child(spark)
	# Partículas
	var parts: Node2D = PARTICULAS_HIT_SCENE.instantiate()
	parts.global_position = pos
	add_child(parts)
	# Screen shake — mais forte se foi heavy
	var fd: Dictionary = ComponenteCombate.FRAME_DATA.get(atacante.combate.estado_atual, {})
	if not fd.is_empty():
		var dano: int = fd.get("dano", 60)
		var forca: float = 0.3 if dano < 100 else 0.6
		screen_shake.tremer(forca)
```

> **Cuidado:** o `acertou` é emitido em `_on_hit_conectado` *depois* do `combate.estado_atual` ainda ser o ataque — então a leitura de `FRAME_DATA` funciona. Se mover essa emissão para depois, ajustar.

## ✅ CHECKPOINT 7

- [ ] Ao acertar: visível hit spark no ponto de contato.
- [ ] Partículas voam do ponto de impacto.
- [ ] Heavy attacks (HP, HK) tremem a tela visivelmente; lights tremem pouco.
- [ ] Sem stuttering ou frame drops.
- [ ] Câmera retorna ao centro suavemente após o shake.

**Commit:** `feat(parte-7): juice — screen shake, partículas e hit sparks`

---

# PARTE 8 — Integração de Sprites Grátis

**Objetivo:** Substituir os placeholders coloridos por sprites reais de OpenGameArt / itch.io.

## Fontes recomendadas (todos com licenças permissivas)

1. **OpenGameArt — Fighting Game**
   - https://opengameart.org/content/martial-hero — sprites de luta CC0, ótimo placeholder.
   - https://opengameart.org/content/karate-fighter — alternativa.

2. **itch.io — busca por "free fighting sprites"**
   - https://itch.io/game-assets/free/tag-fighting

3. **LPC (Liberated Pixel Cup)** — para pose base de personagem genérico.

## Passos

1. Baixar pelo menos 2 spritesheets de fighters (1 para VIP, 1 para MDK).
2. Colocar em `assets/sprites/fighters/vip/` e `assets/sprites/fighters/mdk/`.
3. Em cada `VIP.tscn` e `MDK.tscn`, editar o `AnimatedSprite2D > SpriteFrames`.
4. Criar as animações com os nomes exatos mapeados em `ControladorAnimacao.MAPA_ANIMACAO`:
   - idle, walk, run, jump, fall, crouch, attack_lp, attack_lk, attack_hp, attack_hk, block, hurt, death.
5. Não precisa de todas — o controlador faz fallback para idle. Mas **idle, walk, jump, attack_lp, attack_hp, hurt, block** são prioritárias.
6. Ajustar tamanho do CollisionShape2D do FighterBase + Hurtbox para casar com o sprite real.
7. Diferenciação visual entre VIP e MDK: pode-se usar `Modulate` (tonalidade) no AnimatedSprite2D OU usar dois sprite sets diferentes — o que for mais rápido.

## Cenário (background)

Para a arena, baixar 1 cenário pixel art em loop (rua urbana de preferência):
- https://opengameart.org/content/backgrounds-for-2d-platformers
- Aplicar como TextureRect no Background da Arena.tscn.

## ✅ CHECKPOINT 8

- [ ] VIP e MDK têm sprites distintos (não são mais retângulos coloridos).
- [ ] Animações principais (idle, walk, attack) funcionam.
- [ ] Sprites estão alinhados ao chão (não flutuando nem afundando).
- [ ] Cenário visível no background.
- [ ] Performance estável (60 FPS).

**Commit:** `assets(parte-8): integração de sprites de OpenGameArt para VIP, MDK e cenário`

---

# PARTE 9 — Menu Principal

**Objetivo:** Tela de menu inicial com botões Versus, Opções, Sair. É a primeira tela ao abrir o jogo.

## 9.1 MenuPrincipal.gd

```gdscript
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
	# v0.1 ainda não implementa opções
	print("[Menu] Opções — não implementado na v0.1")

func _on_sair() -> void:
	get_tree().quit()
```

## 9.2 MenuPrincipal.tscn

```
MenuPrincipal (Control)                    [anchor full rect, script: MenuPrincipal.gd]
├── Background (ColorRect)                 [cor escura ou imagem]
├── TituloLabel (Label)                    [centro-superior, "LOS CANDIDOS", fonte grande]
└── VBoxContainer                          [centralizado, separation: 20]
    ├── BotaoVersus (Button)               [text: "VERSUS"]
    ├── BotaoOpcoes (Button)               [text: "OPÇÕES"]
    └── BotaoSair (Button)                 [text: "SAIR"]
```

### Trocar Main Scene
Em `Project Settings > Application > Run > Main Scene` apontar para `MenuPrincipal.tscn`.

## ✅ CHECKPOINT 9

- [ ] Ao iniciar o jogo, abre o menu principal.
- [ ] Botão Versus leva para tela de seleção (que ainda não existe — vai dar erro 404 da cena; é OK por enquanto).
- [ ] Botão Sair fecha o jogo.

**Commit:** `feat(parte-9): menu principal funcional`

---

# PARTE 10 — Seleção de Personagem

**Objetivo:** Tela onde P1 e P2 escolhem entre VIP e MDK. Ao confirmar ambos, vai para Arena.

## 10.1 SelecaoPersonagem.gd

```gdscript
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
	# P1 escolhe com A/D, confirma com U (lp)
	if not p1_confirmado:
		if event.is_action_pressed("p1_left"):
			escolha_p1 = "VIP"
		elif event.is_action_pressed("p1_right"):
			escolha_p1 = "MDK"
		elif event.is_action_pressed("p1_lp") and escolha_p1 != "":
			p1_confirmado = true
			label_status.text = "P1 confirmado!"
	# P2 escolhe com setas, confirma com Numpad 4 (lp)
	if not p2_confirmado:
		if event.is_action_pressed("p2_left"):
			escolha_p2 = "VIP"
		elif event.is_action_pressed("p2_right"):
			escolha_p2 = "MDK"
		elif event.is_action_pressed("p2_lp") and escolha_p2 != "":
			p2_confirmado = true
			label_status.text = "P2 confirmado!"
	# Cancelar
	if event.is_action_pressed("ui_cancel"):
		GameManager.ir_para_menu_principal()
	_atualizar_labels()
	# Se ambos confirmaram, segue
	if p1_confirmado and p2_confirmado:
		_iniciar_partida()

func _atualizar_labels() -> void:
	label_p1.text = "P1: %s" % (escolha_p1 if escolha_p1 != "" else "—")
	label_p2.text = "P2: %s" % (escolha_p2 if escolha_p2 != "" else "—")

func _iniciar_partida() -> void:
	GameManager.personagem_p1 = escolha_p1
	GameManager.personagem_p2 = escolha_p2
	await get_tree().create_timer(0.5).timeout
	GameManager.ir_para_arena()
```

## 10.2 SelecaoPersonagem.tscn

```
SelecaoPersonagem (Control)                [anchor full rect, script]
├── Background (ColorRect)
├── TituloLabel (Label)                    [topo, "SELECIONE SEU LUTADOR"]
├── PainelP1 (Panel)                       [lado esquerdo]
│   ├── RetratoVIP (TextureRect ou Sprite2D placeholder)
│   ├── RetratoMDK
│   └── LabelEscolha (Label)               [text: "P1: —"]
├── PainelP2 (Panel)                       [lado direito, mesma estrutura]
│   ├── RetratoVIP
│   ├── RetratoMDK
│   └── LabelEscolha
└── LabelStatus (Label)                    [centro inferior, instruções]
```

### Ajustar Arena.gd para usar GameManager.personagem_p1/p2

No `Arena.tscn`, em vez de Fighter1 e Fighter2 serem instâncias fixas de VIP e MDK, instanciar dinamicamente em `Arena.gd._ready()`:

```gdscript
const CENA_VIP: PackedScene = preload("res://scenes/fighters/personagens/VIP/VIP.tscn")
const CENA_MDK: PackedScene = preload("res://scenes/fighters/personagens/MDK/MDK.tscn")

func _instanciar_fighters() -> void:
	var pai: Node = $Fighters
	# Limpar filhos existentes
	for f in pai.get_children():
		f.queue_free()
	# P1
	var cena_p1: PackedScene = CENA_VIP if GameManager.personagem_p1 == "VIP" else CENA_MDK
	var f1: FighterBase = cena_p1.instantiate()
	f1.player_index = 1
	f1.global_position = Vector2(480, 200)
	pai.add_child(f1)
	# P2
	var cena_p2: PackedScene = CENA_VIP if GameManager.personagem_p2 == "VIP" else CENA_MDK
	var f2: FighterBase = cena_p2.instantiate()
	f2.player_index = 2
	f2.global_position = Vector2(800, 200)
	# Inverte o sprite do P2
	f2.olhando_direita = false
	pai.add_child(f2)
	# Reatribuir referências
	fighter1 = f1
	fighter2 = f2
```

Chamar `_instanciar_fighters()` no início de `_ready()` antes do resto.

## ✅ CHECKPOINT 10

- [ ] Menu → Versus abre Seleção.
- [ ] P1 (A/D) e P2 (setas) navegam entre VIP e MDK.
- [ ] Confirmação com LP de cada jogador.
- [ ] Ao ambos confirmarem, vai para Arena com os personagens escolhidos.
- [ ] Mirror match (P1=VIP, P2=VIP) funciona — duas instâncias do mesmo personagem.
- [ ] Esc volta para menu principal.

**Commit:** `feat(parte-10): tela de seleção de personagem com confirmação dupla`

---

# PARTE 11 — Tela de Resultado e Loop Completo

**Objetivo:** Fechar o ciclo Menu → Seleção → Arena → Resultado → Menu.

## 11.1 TelaResultado.gd

```gdscript
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
	# Mantém personagens, reseta placar
	GameManager.rounds_p1 = 0
	GameManager.rounds_p2 = 0
	GameManager.vencedor = 0
	GameManager.ir_para_arena()

func _on_menu() -> void:
	GameManager.ir_para_menu_principal()
```

## 11.2 TelaResultado.tscn

```
TelaResultado (Control)
├── Background (ColorRect)
├── LabelVencedor (Label)                  [centro-superior, fonte grande]
├── LabelPlacar (Label)                    [abaixo, fonte média]
└── VBoxContainer                          [centralizado inferior]
    ├── BotaoRevanche (Button)             [text: "REVANCHE"]
    └── BotaoMenu (Button)                 [text: "MENU PRINCIPAL"]
```

## ✅ CHECKPOINT 11 (FINAL DA v0.1)

- [ ] Fluxo completo funciona ponta-a-ponta:
  1. Inicia → Menu Principal.
  2. Versus → Seleção de Personagem.
  3. Ambos confirmam → Arena (best-of-3).
  4. Alguém vence 2 rounds → Tela de Resultado.
  5. Revanche → volta para Arena com mesmos personagens.
  6. Menu Principal → volta ao começo.
- [ ] Não há erros no console durante o loop.
- [ ] HUD, juice, combate, animações — tudo funcionando junto.

**Commit:** `feat(parte-11): tela de resultado e loop completo de fluxo de telas`

---

# Apêndice A — Resolução de Problemas Comuns

| Sintoma                                                  | Causa provável                                    | Correção                                                    |
|----------------------------------------------------------|---------------------------------------------------|-------------------------------------------------------------|
| Fighter atravessa o chão                                 | Floor não está em layer World, ou CollisionShape ausente | Verificar layers e ativar `is_on_floor()` debug              |
| Hitbox não acerta                                        | Layer/Mask errados                                | Hitbox: layer 3 mask 4. Hurtbox: layer 4 mask 0.            |
| Animações não tocam                                      | Nome diferente do mapa em ControladorAnimacao    | Verificar `MAPA_ANIMACAO`                                   |
| Sprite invertido na direção errada                       | `flip_h` em vez de `scale.x`                      | Usar `sprite.flip_h = not olhando_direita`                  |
| Câmera trepida em excesso                                | Trauma somando sem limite                         | Confirmar `min(trauma + forca, 1.0)`                        |
| Combo nunca reseta                                       | `frames_desde_ultimo_hit` não incrementa          | Confirmar `_process` em HUD.gd                              |
| Auto-hit (fighter acerta a si mesmo)                     | Hitbox detectando própria Hurtbox                 | Checar `hb.dono == dono` em Hitbox.gd                       |

---

# Apêndice B — Tabela de Frame Data (referência)

| Ataque | Startup | Active | Recovery | Dano | Hitstun | Blockstun | Knockback     |
|--------|---------|--------|----------|------|---------|-----------|---------------|
| LP     | 3       | 2      | 6        | 60   | 12      | 8         | (120, 0)      |
| LK     | 4       | 3      | 8        | 70   | 14      | 10        | (140, 0)      |
| HP     | 8       | 3      | 14       | 120  | 20      | 14        | (260, -80)    |
| HK     | 10      | 4      | 18       | 140  | 22      | 16        | (300, -100)   |

> Total frames = startup + active + recovery. LP: 11 frames total. HK: 32 frames total. Ajustar conforme playtesting.

---

# Apêndice C — Próximos Passos (Pós v0.1)

Após validar todos os 11 checkpoints e fazer playtesting:

1. **v0.2 — Special Moves**
   - Implementar `InputBuffer.gd` com detecção de motion (QCF, DP, QCB, charge, 360).
   - Adicionar specials por personagem (Chinelada/Voadora VIP/Subindo Forte; Abraço de Urso/Parafuso/Salto Suplex).
   - Sistema de cancel (normal → special).

2. **v0.3 — Polimento Audiovisual**
   - Trilha sonora completa.
   - SFX de impacto, voz, UI.
   - Sprites finais autorais.

3. **v0.4 — Modo Arcade vs CPU.**

4. **v0.5 — Itens Arremessáveis** (chinelo flamejante VIP, corrente MDK).

5. **v1.0 — Lançamento Local com mais personagens.**

6. **Online (longo prazo)** — refatorar Input para InputBuffer alimentável por rede + MultiplayerSynchronizer.

---

**FIM DO CLAUDE.md — v0.1**

> Sempre que terminar uma PARTE: validar checkpoint, fazer commit, atualizar Histórico de Revisões no GDD se houver mudança de design.
