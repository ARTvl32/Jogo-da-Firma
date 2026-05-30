# Checklist de Testes Manuais — Los Candidos v0.1.2

> Executar do início ao fim antes de cada push para `main`.
> Marque ✅ ao passar, ❌ ao falhar (anotar o bug abaixo do item).

---

## 🔁 FLUXO DE TELAS

### Menu Principal
- [ ] Jogo abre direto no Menu Principal (não na arena)
- [ ] Botão **VERSUS** navega para Seleção de Personagem
- [ ] Botão **OPÇÕES** abre painel de volume in-menu
- [ ] Slider de volume altera o som da música em tempo real
- [ ] Botão **CONTROLES** abre a Tela de Controles
- [ ] Botão **SAIR** fecha o jogo

### Tela de Controles
- [ ] Lista todas as 9 ações (mover esq/dir, pular, agachar, LP/LK/HP/HK, bloquear)
- [ ] Teclas de P1 e P2 exibidas corretamente lado a lado
- [ ] Clicar num botão de tecla → mostra "..." e aguarda input
- [ ] Pressionar nova tecla → atualiza o botão com o novo nome
- [ ] Pressionar ESC durante rebind → cancela sem alterar a tecla
- [ ] Botão **Restaurar** → reverte todas as teclas para o padrão
- [ ] Botão **Voltar** / ESC → retorna ao Menu Principal

### Seleção de Personagem
- [ ] P1 usa **A/D** para alternar entre VIP e MDK
- [ ] P2 usa **←/→** para alternar entre VIP e MDK
- [ ] P1 confirma com **U** (lp); P2 confirma com **L** (lp)
- [ ] Label de escolha atualiza ao navegar
- [ ] Após ambos confirmarem → Arena carrega com os personagens corretos
- [ ] Mirror match (VIP vs VIP ou MDK vs MDK) funciona sem erros
- [ ] **ESC** → volta ao Menu Principal

### Tela de Resultado
- [ ] Exibe nome do vencedor corretamente
- [ ] Placar de rounds correto (ex: "2 × 1")
- [ ] Botão **REVANCHE** → reinicia arena com mesmos personagens, placar zerado
- [ ] Botão **SELEÇÃO** → vai para seleção de personagem
- [ ] Botão **MENU PRINCIPAL** → vai para o menu

---

## ⚔️ COMBATE — MECÂNICAS BASE

### Movimento (P1: WASD | P2: ←↑↓→)
- [ ] Andar esquerda/direita funciona para ambos
- [ ] Duplo-tap direção → corre (mais rápido)
- [ ] Pular com W/↑ aplica força vertical
- [ ] Movimento horizontal no ar funciona
- [ ] Agachar com S/↓ muda estado para CROUCH
- [ ] Sprite vira automaticamente ao pressionar a direção oposta
- [ ] Sprite vira para encarar o oponente quando parado

### Ataques no Chão
- [ ] **LP** (U / L) → soco leve, animação curta
- [ ] **LK** (J / ,) → chute leve, animação curta
- [ ] **HP** (I / ;) → soco pesado, animação mais lenta
- [ ] **HK** (K / .) → chute pesado, animação mais lenta
- [ ] Nenhum ataque cancela o anterior antes de terminar

### Ataques no Ar
- [ ] **LP** no ar → funciona e causa dano
- [ ] **HP** no ar → funciona e causa dano (knockdown)
- [ ] **LK** no ar → **não funciona** (exclusivo do chão)
- [ ] **HK** no ar → **não funciona** (exclusivo do chão)
- [ ] Personagem mantém trajetória do pulo durante ataque aéreo

### Bloqueio (O / /)
- [ ] Segurar bloquear → estado BLOCK, recebe knockback reduzido
- [ ] Bloquear **LP/LK** → sem chip damage, barra de vida não move
- [ ] Bloquear **HP/HK** → chip damage ~8%, barra de vida perde levemente
- [ ] Chip damage nunca mata (vida para em 1 HP)
- [ ] Soltar o botão de bloquear → volta ao IDLE

---

## 💥 SISTEMA DE DANO E STUN

### Hitstun (LP/LK)
- [ ] Receber LP → breve stun, personagem pode reagir logo depois
- [ ] Spam de LP **não** prende o defensor infinitamente
- [ ] Após o stun de LP: defensor consegue bloquear ou atacar

### Knockdown (HP/HK)
- [ ] Receber HP → personagem cai ao chão (knockdown)
- [ ] Receber HK → knockdown com knockback maior
- [ ] Personagem fica no chão ~1.2 segundos
- [ ] Ao se levantar: **30 frames de invencibilidade** (não pode ser acertado)
- [ ] Após os iframes: pode ser acertado normalmente

### Hitstop
- [ ] Ao acertar LP/LK: breve congelamento (~8 frames) em ambos
- [ ] Ao acertar HP/HK: congelamento maior (~12 frames)
- [ ] Durante hitstop: nenhum movimento acontece

---

## 🎮 SUPER METER

- [ ] Barra azul aparece abaixo das healthbars para ambos os jogadores
- [ ] Acertar um hit → barra aumenta ~15%
- [ ] Receber um hit → barra aumenta ~10%
- [ ] Barra não passa de 100%
- [ ] Barra reseta para 0 ao início de cada round

---

## 🏆 SISTEMA DE ROUNDS

### Durante o Round
- [ ] Timer conta de 99 até 0
- [ ] Indicadores de round (★☆) aparecem abaixo das healthbars
- [ ] Vencer round → estrela preenche no lado do vencedor
- [ ] HUD mostra "Round 1", "Round 2", "Round 3" corretamente

### Encerramento de Round
- [ ] Vida chega a 0 → round encerra imediatamente
- [ ] Timer chega a 0 → quem tem mais vida vence o round
- [ ] Timer chega a 0 com vida igual → empate (sem crash)
- [ ] Fighters congelam ao encerrar o round

### Fluxo Best-of-3
- [ ] Overlay "VIP VENCEU!" / "MDK VENCEU!" aparece com contagem regressiva
- [ ] Após 5 segundos → próximo round reinicia
- [ ] Ao vencer 2 rounds → vai para TelaResultado (sem recarregar arena)

---

## 🎨 VISUAIS E JUICE

### Healthbars
- [ ] **Lag bar amarela**: ao receber dano, barra principal cai imediato, amarela drena devagar
- [ ] Lag bar funciona para P1 (esq→dir) e P2 (dir→esq)
- [ ] Chip damage também aparece na lag bar

### Partículas e Shake
- [ ] Acertar LP/LK → partículas no ponto de impacto
- [ ] Acertar HP/HK → partículas + screen shake mais forte
- [ ] Screen shake retorna ao normal suavemente

### Sprites
- [ ] VIP e MDK com sprites reais (não retângulos coloridos)
- [ ] Sprite vira com flip_h ao mudar de direção
- [ ] MDK começa virado para a esquerda (olhando VIP)

---

## 🔊 ÁUDIO

- [ ] Música de fundo toca desde o Menu Principal
- [ ] Slider de volume no menu funciona
- [ ] **Pulo** → som de whoosh
- [ ] **Aterrissagem** → som de impacto surdo
- [ ] **LP/LK acertando** → som leve
- [ ] **HP/HK acertando** → som pesado
- [ ] **Bloquear** → som metálico
- [ ] **Morte** → som grave

---

## 🗺️ ARENA E CÂMERA

### Corner Clamp
- [ ] Fighter não sai pela borda esquerda da tela
- [ ] Fighter não sai pela borda direita da tela
- [ ] Pressionar contra a parede → para no limite (40px da borda)

### Câmera
- [ ] Câmera suaviza em direção ao ponto médio dos dois fighters
- [ ] Câmera não mostra área além dos limites da arena
- [ ] Background com parallax se move com o ponto médio

---

## ⏸️ PAUSA

- [ ] **ESC** durante a luta → menu de pausa aparece centralizado
- [ ] Jogo congela durante a pausa (`get_tree().paused = true`)
- [ ] Slider de volume na pausa funciona
- [ ] **Continuar** → jogo retoma do ponto exato
- [ ] **Menu Principal** na pausa → vai para o menu sem erros
- [ ] **ESC** novamente → fecha a pausa (equivalente a Continuar)

---

## 🐛 REGRESSÃO — BUGS CORRIGIDOS

Confirmar que os bugs anteriores **não voltaram**:

- [ ] MDK não nasce com sprite virado para o lado errado
- [ ] Sprite de ambos acompanha a direção de movimento imediatamente
- [ ] Spam de LP não prende o defensor infinitamente
- [ ] Não aparece quadrado vermelho ao receber hit
- [ ] P2 não começa com menos vida que P1 (MDK tem 1100 HP, VIP tem 1000)
- [ ] Screen shake funciona (câmera treme em heavy hits)
- [ ] Sem erros no console do Godot durante uma partida completa

---

## 📋 RESULTADO FINAL

| Categoria | Total | ✅ Passou | ❌ Falhou |
|---|---|---|---|
| Fluxo de Telas | 21 | | |
| Combate — Base | 18 | | |
| Dano e Stun | 12 | | |
| Super Meter | 5 | | |
| Rounds | 11 | | |
| Visuais | 9 | | |
| Áudio | 8 | | |
| Arena e Câmera | 7 | | |
| Pausa | 7 | | |
| Regressão | 7 | | |
| **TOTAL** | **105** | | |

> **Critério de aprovação:** ≥ 95 testes passando (≥ 90%).
> Qualquer ❌ em Regressão ou Combate Base deve ser corrigido antes do push.

---

*Última atualização: v0.1.2*
