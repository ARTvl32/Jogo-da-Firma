# Los Candidos — Histórico de Atualizações

---

## v0.1 — Base do Jogo

### Sistema de Combate
- `FighterBase` — classe base de todos os personagens; gerencia estado, física, input e animação
- `ComponenteCombate` — frame data de ataques (hitbox, dano, knockback), sistema de prioridade de estado
- `ComponenteVida` — vida atual/máxima, sinal `vida_alterada`, sinal `morreu`
- `ControladorAnimacao` — sincroniza estado do fighter com as animações do AnimationPlayer
- `Hitbox` / `Hurtbox` — áreas de colisão separadas para detecção de golpes

### Personagens
- **MDK** — personagem jogável P2; movimentação, pulo, ataques leve/pesado/especial
- **VIP** — personagem jogável P1; movimentação, pulo, ataques leve/pesado/especial

### Arena
- Cena de combate com chão (StaticBody2D), paredes laterais e câmera com suavização horizontal
- `ScreenShake` — tremor de câmera proporcional ao dano do golpe
- `ParticulasHit` / `EfeitoHit` — efeito visual de impacto nos acertos

### Menus
- `MenuPrincipal` — tela inicial com botões Versus, Opções e Sair
- `SelecaoPersonagem` — tela de seleção de personagens para P1 e P2
- `TelaResultado` — tela básica de fim de partida com placar e botões Revanche / Menu Principal

### HUD
- Barras de vida (P1 e P2), timer de round, label de round atual
- Exibição de contador de combo (mínimo 2 hits)

### Sistemas
- `GameManager` — autoload singleton; controla personagens selecionados, placar de rounds, vencedor e transições de cena
- Regra de vitória: melhor de 3 rounds (`rounds_para_vencer = 2`)
- Recarga de cena entre rounds; transição para `TelaResultado` ao fim da partida

---

## v0.1.1 — Conteúdo e Polimento

### Sprites e Visuais
- Integração dos sprites **Martial Hero 2** (MDK) e **Martial Hero 3** (VIP) nos personagens
- Background da arena substituído pelo tileset **NightForest**
- Escala dos sprites ajustada para aproximadamente 300 px de altura nos dois personagens
- Remoção do tint de cor (cor sólida sobreposta) aplicado anteriormente nos sprites
- Sprite de chão substituído por `TextureRect` com modo TILE, usando o arquivo `floor_tile.png` (padrão de onda estilizado), eliminando o chão monocromático anterior

### Correções de Física e Animação
- **Fix:** virada de sprite agora responde ao input de direção do jogador, e não apenas à posição relativa do oponente
- **Fix:** `sprite.flip_h` inicializado corretamente em `_ready()` com base em `olhando_direita`, eliminando o frame de sprite invertido ao iniciar a cena
- **Fix:** remoção do quadrado vermelho de debug que aparecia na tela ao personagem receber um hit (hitbox visual de `CollisionShape2D` desativado em produção)

### Áudio Procedural (`GeradorSom`)
- Criação do autoload `GeradorSom` com síntese procedural de áudio via `AudioStreamWAV` (PCM 16-bit)
- SFX implementados: `hit_leve`, `hit_pesado`, `block`, `pulo`, `aterrissagem`, `morte`, `menu`
- Música de fundo épica gerada proceduralmente (progressão Am–F–G–Am, BPM 110, loop de 8 s) com baixo pulsado, pad de acordes com vibrato, melodia pentatônica menor e bateria (kick/snare)
- Volume dos SFX reduzido em 30% para equilíbrio com a música (`OFFSET_SFX_DB = -3.1 dB`)
- **Fix:** removida declaração `class_name GeradorSom` que conflitava com o nome do autoload e impedia o carregamento do script
- **Fix:** resolvido erro de parse causado por `PackedByteArray` sendo passado por valor em funções auxiliares; escrita de bytes internalizada em cada função geradora
- **Fix:** constante `AudioStreamWAV.FORMAT_16_BIT` inacessível nesta build do Godot; substituída pelo literal inteiro `1`

### Menu Principal — Redesign
- Fonte do título alterada para **City Burn** (`assets/fonts/cityburn.ttf`)
- Subtítulo alterado de `-Jogo de Luta-` para `- Ultimate Fighting -`
- Botões com largura reduzida (220 px) e bordas arredondadas (`corner_radius = 12`)
- Painel de Opções in-menu com slider de volume (0–100 %), label de porcentagem e botão Fechar
- Lógica de sincronização do slider com o `AudioServer` (barramento Master)

### HUD In-Game — Redesign (Street Fighter style)
- Barra de vida do P1: teal vibrante (`Color(0.08, 0.82, 0.7)`)
- Barra de vida do P2: âmbar (`Color(1, 0.74, 0)`), preenchimento direita→esquerda (`fill_mode = 1`)
- Fundo das barras: StyleBoxFlat escuro com cantos arredondados
- Timer centralizado em painel com borda branca e cantos arredondados; font_size 38
- Label de round abaixo do timer (menor, cinza)
- Nomes dos personagens exibidos acima das barras com fonte City Burn, coloridos na cor do respectivo jogador
- Nomes carregados dinamicamente de `FighterBase.nome_exibicao` — qualquer personagem futuro basta definir essa variável

### Menu de Pausa In-Game
- Acionado por `Escape` durante a luta; pausado via `get_tree().paused = true`
- Painel centralizado com título "PAUSA", botão Continuar, slider de volume com label de %, separador e botão Menu Principal
- **Fix:** menu aparecia deslocado para um canto inacessível quando o HUD era instanciado dentro de um `Node2D`; corrigido adicionando um `CenterContainer` de largura total como pai do painel, garantindo centralização correta em qualquer resolução

### Telas de Vitória
- **Overlay de round** (vitórias intermediárias): painel semitransparente exibido diretamente na arena com nome do vencedor na sua cor (teal/âmbar), label "ROUND X" e contagem regressiva animada de 5 a 1; ao atingir 0 recarrega a cena para o próximo round
- **Tela de resultado** (fim de partida — `TelaResultado`): tela emphática com fundo azul-escuro, "VITÓRIA" em City Burn pequeno, nome do vencedor em City Burn 88 px colorido, placar de rounds e três botões:
  - **REVANCHE** — reinicia o placar e volta direto à arena com os mesmos personagens
  - **SELEÇÃO DE PERSONAGEM** — reseta a partida e vai para a tela de seleção
  - **MENU PRINCIPAL** — retorna ao menu inicial

---

## v0.1.2 — Polimento de Combate (em progresso)

### Correções de Facing / Sprite
- **Fix:** `sprite.flip_h` agora inicializado em `_ready()` com base em `olhando_direita` — MDK não nascia mais virado para o lado errado
- **Fix:** `_atualizar_facing()` refatorado para priorizar o input de direção do jogador; quando parado, vira para o oponente (comportamento anterior); restrição de `is_on_floor()` removida para permitir virada no ar

### Chip Damage ao Bloquear
- `ComponenteVida.aplicar_dano()` recebe novo parâmetro `pode_matar: bool` (default `true`) — permite aplicar dano sem matar o personagem
- HP e HK bloqueados causam **8% de chip damage** (mínimo 1 HP); LP e LK bloqueados continuam sem chip
- Chip damage nunca mata — vida para em 1 HP
- `levou_hit` emitido com `dano = 0` ao bloquear, permitindo que sistemas futuros (HUD, super meter) reajam ao evento

### Sistema de Knockdown (HP/HK) e correção de loop infinito
- **Fix (frame data):** hitstun de LP reduzido de 12 → 8 (vantagem no hit = 0, não encadeia em si mesmo); LK de 14 → 10 (vantagem = -1). Encadeamento infinito por spam de light attacks eliminado matematicamente
- **Novo estado `KNOCKDOWN`** adicionado à FSM de `ComponenteCombate`
- HP e HK agora causam knockdown (derrubam o defensor) em vez de hitstun simples — knockback forte (`Vector2(400,-200)` e `Vector2(460,-240)`)
- Defensor permanece no chão por 70 frames (~1.2 s) durante o knockdown, sem poder agir
- Ao se levantar: 30 frames de invencibilidade (`iframes`) — hurtbox desativada via `set_deferred`, não pode ser acertado durante a recuperação
- Atacante não pode acertar alvo em iframes (checagem em `_on_hit_conectado`)
- `ControladorAnimacao` mapeia `KNOCKDOWN → "hurt"` (fallback visual enquanto animação dedicada não existe)

### HUD — Lag Bar e Indicadores de Round
- **Lag bar KOF-style:** duas `ProgressBar` amarelas (`LagBar1`/`LagBar2`) inseridas atrás das barras principais; ao receber dano a barra principal cai imediatamente, a amarela drena ~90 HP/s até igualar — torna o dano recebido visualmente legível
- **Indicadores de round:** `HBoxContainer` (`RoundsP1`/`RoundsP2`) exibidos logo abaixo das healthbars com estrelas ★ (preenchidas, amarelas) e ☆ (vazias, cinza); atualizados em `conectar_fighters()` e a cada `_encerrar_round()` na Arena

### Ataques no Ar e Corner Clamp
- **Ataques no ar (LP/HP):** `_processar_input()` libera LP e HP durante JUMP/FALL; LK/HK continuam exclusivos do chão (sem animação aérea dedicada na v0.1.2); `_iniciar_ataque()` não zera `velocity.x` quando no ar — personagem mantém momento do pulo
- **Corner clamp:** `global_position.x` travado entre `40` e `1240` px após cada `move_and_slide()` — fighters não saem da tela; câmera da Arena limitada ao intervalo `[200, 1080]` para não mostrar área além dos limites

### Tela de Controles e Super Meter
- **Tela de Controles** (`TelaControles.tscn`): acessível via botão "CONTROLES" no menu principal; exibe grid de ações vs. teclas de P1 e P2; permite rebind clicando no botão da tecla e pressionando a nova; botão "Restaurar" reverte aos padrões; Esc cancela rebind em andamento
- **Super meter:** barra azul fina (`SuperBar1`/`SuperBar2`, 12 px de altura) exibida abaixo das healthbars; carrega +15% ao acertar golpes e +10% ao receber dano; reseta a 0 ao início de cada round; base estrutural para specials da v0.2 (consumo ainda não implementado)
- **CLAUDE_3.md** gerado com roadmap da v0.1.3: 8 partes com estimativas de tokens, cobrindo hit flash, overlay FIGHT!/KO!, rematch rápido, damage numbers, landing recovery, super move, guard break, throw/grab e modo treino
