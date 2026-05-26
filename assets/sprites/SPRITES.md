# Guia de Integração de Sprites — Los Candidos

> Assets provisórios em pixel art. Serão substituídos por arte autoral do VIP e MDK.

---

## Downloads (CC0 — sem restrições)

| Asset | Uso | Link | Licença |
|---|---|---|---|
| Martial Hero 2 | VIP (Player 1) | https://luizmelo.itch.io/martial-hero-2 | CC0 |
| Martial Hero 3 | MDK (Player 2) | https://luizmelo.itch.io/martial-hero-3 | CC0 |
| Streets of Fight | Cenário + background parallax | https://opengameart.org/content/streets-of-fight | CC0 |

---

## Onde colocar os arquivos

```
assets/sprites/
├── fighters/
│   ├── vip/        ← spritesheets do VIP (azul)
│   └── mdk/        ← spritesheets do MDK (vermelho)
├── arena/          ← background e tiles do cenário
└── efeitos/        ← hit sparks, poeira (futuro)
```

---

## Animações obrigatórias (nomes exatos usados no ControladorAnimacao.gd)

| Nome | Prioridade | FPS | Loop |
|---|---|---|---|
| `idle` | OBRIGATÓRIA | 8 | sim |
| `walk` | OBRIGATÓRIA | 10 | sim |
| `jump` | OBRIGATÓRIA | 10 | não |
| `attack_lp` | OBRIGATÓRIA | 15 | não |
| `attack_hp` | OBRIGATÓRIA | 12 | não |
| `hurt` | OBRIGATÓRIA | 12 | não |
| `block` | OBRIGATÓRIA | 10 | não |
| `run` | recomendada | 12 | sim |
| `fall` | recomendada | 10 | sim |
| `crouch` | recomendada | 12 | não |
| `attack_lk` | recomendada | 15 | não |
| `attack_hk` | recomendada | 12 | não |
| `death` | recomendada | 10 | não |

> O `ControladorAnimacao.gd` tem fallback automático para `idle` se uma animação não existir.

---

## Passo a passo para integrar no Godot

### Lutadores

**VIP (Player 1) — Martial Hero 2:**
1. Baixe em https://luizmelo.itch.io/martial-hero-2
2. Extraia e copie os PNGs para `assets/sprites/fighters/vip/`
3. Mapeamento de animações:
   - Idle → `idle` | Run → `walk` e `run` | Jump → `jump` | Fall → `fall`
   - Attack1 → `attack_lp` e `attack_lk` | Attack2 → `attack_hp` e `attack_hk`
   - Take Hit → `hurt` | Death → `death`

**MDK (Player 2) — Martial Hero 3:**
1. Baixe em https://luizmelo.itch.io/martial-hero-3
2. Extraia e copie os PNGs para `assets/sprites/fighters/mdk/`
3. Mapeamento de animações:
   - Idle → `idle` | Run → `walk` e `run` | Going Up → `jump` | Going Down → `fall`
   - Attack1 → `attack_lp` | Attack2 → `attack_lk` | Attack3 → `attack_hp` e `attack_hk`
   - Take Hit → `hurt` | Death → `death`

**Para ambos no Godot:**
1. Abra a cena do personagem > `AnimatedSprite2D` > Inspector > `SpriteFrames` > Editar
2. Crie cada animação com o nome exato da coluna "Nome no jogo"
3. Arraste os frames do spritesheet e configure FPS/loop conforme a tabela acima
4. Ajuste `CollisionShape2D` do corpo e `Hurtbox` para casar com o sprite real
5. Mantenha o `Modulate`: VIP=azul `#3F88FF`, MDK=vermelho `#E64545`

### Cenário (Arena)

1. Baixe o **Streets of Fight** em https://opengameart.org/content/streets-of-fight
2. Copie o background para `assets/sprites/arena/`
3. No Godot, abra `scenes/arena/Arena.tscn`
4. Selecione o nó `Background` (ColorRect)
5. Troque por `TextureRect`, carregue a imagem, configure `stretch_mode = TILE` ou `KEEP_ASPECT_COVERED`

---

## Diferenciação visual VIP vs MDK

Se usar o mesmo spritesheet para os dois personagens, aplique cor via `Modulate` no `AnimatedSprite2D`:

- **VIP** → `Color(0.247, 0.533, 1, 1)` — azul `#3F88FF`
- **MDK** → `Color(0.902, 0.271, 0.271, 1)` — vermelho `#E64545`

---

> **Lembrete:** estes assets são **provisórios**. A arte final autoral dos personagens VIP (Vinícius) e MDK (Arthur) será produzida em versões pós-v0.1.
