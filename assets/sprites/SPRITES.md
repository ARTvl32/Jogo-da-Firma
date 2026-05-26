# Guia de Integração de Sprites — Los Candidos

> Assets provisórios em pixel art. Serão substituídos por arte autoral do VIP e MDK.

---

## Downloads recomendados (CC0 — sem restrições)

| Asset | Uso | Link | Licença |
|---|---|---|---|
| Martial Hero | Lutador (VIP e MDK) | https://luizmelo.itch.io/martial-hero | CC0 |
| Streets of Fight | Cenário + background parallax | https://opengameart.org/content/streets-of-fight | CC0 |
| Pixel Art Street and Avenue | Alternativa de cenário | https://opengameart.org/content/pixel-art-street-and-avenue | CC0 |

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

### Lutadores (VIP e MDK)

1. Baixe o **Martial Hero** em https://luizmelo.itch.io/martial-hero
2. Extraia e copie os PNGs para `assets/sprites/fighters/vip/` e `assets/sprites/fighters/mdk/`
3. No Godot, abra `scenes/fighters/personagens/VIP/VIP.tscn`
4. Clique em `AnimatedSprite2D` > Inspector > `SpriteFrames` > Editar
5. Para cada animação da tabela acima:
   - Crie a animação com o nome exato
   - Arraste os frames do spritesheet para a linha de frames
   - Configure FPS e loop conforme a tabela
6. Ajuste o `CollisionShape2D` do corpo (60×120) e da `Hurtbox` para casar com o sprite real
7. Repita para `MDK.tscn` (use `Modulate` para diferenciar: VIP=azul, MDK=vermelho se usar o mesmo sheet)

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
