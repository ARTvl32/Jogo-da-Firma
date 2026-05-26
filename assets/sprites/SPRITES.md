# Guia de Integração de Sprites — Los Candidos

> Assets provisórios em pixel art. Serão substituídos por arte autoral do VIP e MDK.

---

## Assets Integrados

| Asset | Personagem | Pasta | Licença |
|---|---|---|---|
| Martial Hero 3 | VIP (Player 1) | `assets/sprites/fighters/vip/` | CC0 |
| Martial Hero 2 | MDK (Player 2) | `assets/sprites/fighters/mdk/` | CC0 |
| Night Forest | Arena (fundo) | `assets/sprites/arena/NightForest/` | CC0 |

---

## Onde os arquivos estão

```
assets/sprites/
├── fighters/
│   ├── vip/
│   │   └── Martial Hero 3/Sprite/   ← spritesheets do VIP (azul)
│   └── mdk/
│       └── Martial Hero 2/Sprites/  ← spritesheets do MDK (vermelho)
├── arena/
│   └── NightForest/                 ← background da arena
└── efeitos/                         ← hit sparks, poeira (futuro)
```

---

## Animações mapeadas no código

### VIP — Martial Hero 3 (126×126 px por frame)

| Arquivo | Frames | Nome no jogo | FPS | Loop |
|---|---|---|---|---|
| `Idle.png` | 10 | `idle` | 8 | sim |
| `Run.png` | 8 | `walk`, `run` | 10 / 12 | sim |
| `Going Up.png` | 3 | `jump` | 10 | não |
| `Going Down.png` | 3 | `fall` | 10 | sim |
| `Attack1.png` | 7 | `attack_lp` | 15 | não |
| `Attack2.png` | 6 | `attack_lk` | 15 | não |
| `Attack3.png` | 9 | `attack_hp`, `attack_hk` | 12 | não |
| `Take Hit.png` | 3 | `hurt` | 12 | não |
| `Death.png` | 11 | `death` | 10 | não |

### MDK — Martial Hero 2 (200×200 px por frame)

| Arquivo | Frames | Nome no jogo | FPS | Loop |
|---|---|---|---|---|
| `Idle.png` | 4 | `idle` | 8 | sim |
| `Run.png` | 8 | `walk`, `run` | 10 / 12 | sim |
| `Jump.png` | 2 | `jump` | 10 | não |
| `Fall.png` | 2 | `fall` | 10 | sim |
| `Attack1.png` | 4 | `attack_lp`, `attack_lk` | 15 | não |
| `Attack2.png` | 4 | `attack_hp`, `attack_hk` | 12 | não |
| `Take hit.png` | 3 | `hurt` | 12 | não |
| `Death.png` | 7 | `death` | 10 | não |

> Animações `block` e `crouch` não estão disponíveis nos assets — `ControladorAnimacao.gd` faz fallback automático para `idle`.

---

## Diferenciação visual VIP vs MDK

Cor aplicada via `Modulate` no `AnimatedSprite2D`:

- **VIP** → `Color(0.247, 0.533, 1, 1)` — azul `#3F88FF`
- **MDK** → `Color(0.902, 0.271, 0.271, 1)` — vermelho `#E64545`

---

> **Lembrete:** estes assets são **provisórios**. A arte final autoral dos personagens VIP (Vinícius) e MDK (Arthur) será produzida em versões pós-v0.1.
