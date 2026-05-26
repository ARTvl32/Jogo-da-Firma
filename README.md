# Los Candidos

> Jogo de luta 2D arcade em pixel art — desenvolvido em Godot 4.6.3

**Los Candidos** é um fighting game 1v1 de inspiração clássica: footsies, execução manual de movimentos especiais e combate rápido sem muletas de auto-combo. Feito por dois amigos que quiseram ser personagens jogáveis.

---

## Conceito

O jogo homenageia a era de ouro dos fliperamas — Street Fighter II, The King of Fighters '98, Samurai Shodown. A vitória vem de leitura de espaçamento, timing e execução. Sem sistemas que joguem pelo jogador.

**Três pilares de design:**

| Pilar | O que significa |
|---|---|
| Honestidade arcade | Sem auto-combo, sem dano aleatório. Vence quem lê melhor. |
| Resposta tátil | Todo input importa em frames. Hitstop, screen shake e som reforçam cada acerto. |
| Identidade pixel art | Silhueta legível, paleta limitada (~16 cores por personagem), animações com peso. |

---

## Personagens

### VIP — Vinícius "VIP" Pessoa
Lutador ágil, voltado para pressão e mix-up. Especialidade: entrar no espaço do oponente e misturar altos e baixos.

- **Voadora** — pulo alto que atravessa o campo e converte em ataque aéreo pesado (tem penalidade de recuperação ao errar).
- **Pião** — giro low que passa por baixo de projéteis e serve de anti-aéreo de baixo custo.
- **Bumerangue** (especial 3) — projétil de curto/médio alcance que retorna ao personagem.

> Arquétipo: Rushdown / Mix-up — fácil de entrar, difícil de defender.

---

### MDK — Arthur "MDK" Vieira
Lutador pesado, baixa mobilidade compensada por dano alto e command grabs.

- **Abraço de Urso** (360 + Soco) — command grab de curto alcance, dano alto. Análogo ao Spinning Piledriver.
- **Parafuso** (charge ← → + Soco) — avanço giratório com armadura nos primeiros frames (absorve 1 hit).
- **Salto Suplex** (QCF + Chute) — pulo curto que converte em command grab anti-aéreo.

> Arquétipo: Grappler — recompensa quem lê aproximação e força situações de 50/50.

---

## Gameplay

```
Round Start → Combate (footsies, whiff punish, mix-up) → KO ou Time Up → Próximo round
```

- **Best-of-3** por padrão (configurável).
- **Sistema de bloqueio:** botão dedicado (decisão final pós-playtesting).
- **Input buffer:** janela de 6 frames (~100 ms) — permite links e cancels manuais.
- **Notação de movimento padrão:** 236 = QCF, 214 = QCB, 623 = Dragon Punch, 360 = Full Circle.

---

## Controles padrão

| Ação | Jogador 1 | Jogador 2 |
|---|---|---|
| Mover | `WASD` | `Setas` |
| Ataque leve | `U` | `Numpad 1` |
| Ataque pesado | `I` | `Numpad 2` |
| Bloquear | `O` | `Numpad 3` |

Suporte a gamepad (Xbox/PlayStation). Controles remapeáveis.

---

## Modos de jogo

| Modo | Status |
|---|---|
| Versus local (PvP) | Foco da v0.1 |
| Treino (vs Dummy) | Planejado para v0.1 |
| Arcade (vs CPU) | v0.4 |
| Online (netcode rollback) | Pós v1.0 |

---

## Roadmap

```
v0.1  MVP: 2 personagens, movimentação, ataques, HP, HUD, versus local
v0.2  Movimentos especiais, sistema de cancel, damage scaling
v0.3  Sprites finais, cenário parallax, trilha sonora e SFX
v0.4  Modo arcade com CPU e dificuldade crescente
v0.5  Itens arremessáveis (chinelo flamejante do VIP, item do MDK)
v1.0  Roster expandido, segunda arena, rebinding completo
```

---

## Stack técnica

| Item | Valor |
|---|---|
| Engine | Godot 4.6.3 |
| Linguagem | GDScript |
| Resolução | 1280 × 720 (pixel-perfect) |
| FPS alvo | 60 FPS fixos (`_physics_process`) |
| Arquitetura | Componentes desacoplados (HealthComponent, CombatComponent, AnimationController) |
| Multiplayer futuro | Determinístico — preparado para rollback netcode (GGPO-like) |

---

## Como rodar

> Requisitos: [Godot 4.6.3](https://godotengine.org/download)

```bash
# Clone o repositório
git clone https://github.com/ARTvl32/Jogo-da-Firma.git

# Abra o Godot, importe o projeto (project.godot) e pressione F5
```

---

## Equipe

| Nome | Papel |
|---|---|
| Vinícius Pessoa Parente | Desenvolvedor · Designer · Personagem VIP |
| José Arthur Vieira Lima | Desenvolvedor · Designer · Personagem MDK |

---

## Referências

Street Fighter II · The King of Fighters '98 · Samurai Shodown · Garou: Mark of the Wolves · Street Fighter III: 3rd Strike

---

*Los Candidos — GDD v0.1 · Documento vivo*
