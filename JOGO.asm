; ============================================================================
; TRAVESSIA AV. SANCA - VERSAO COM PIXEL ART E CORES (CARROS/ONIBUS/PREDIOS)
; ============================================================================
; Processador: ICMC (RISC, 16 bits)
; Arquivo    : JOGO.ASM
;
; MAPA DA TELA: 40 colunas x 30 linhas (enderecos 0 a 1199, onde
;               endereco = linha*40 + coluna)
;
; PALETA DE CORES USADA (mesmo padrao do codigo original: cor*256, somada
; ao codigo ASCII do caractere antes do OUTCHAR):
;   512  = Verde     (jogador)
;   2048 = Cinza      (predios/calcada/carro 3/cabeca do jogador)
;   2304 = Vermelho   (carro 1)
;   2816 = Amarelo    (onibus 1)
;   3072 = Azul       (predios/carro 2)
;   3840 = Branco     (onibus 2 "SC" e letreiro USP) -> OBS: valor obtido
;          seguindo o mesmo padrao (indice*256) dos demais; se no simulador
;          o branco tiver outro codigo, e so trocar aqui.
;
; OBSTACULOS (5 no total, cada um e' um "sprite" de varias celulas na MESMA
; linha, todas se movendo para a direita e voltando ao inicio da faixa).
; Os caracteres foram escolhidos com base no MAPA REAL DE BITMAP do
; charmap.mif (fonte 8x8): 'o'/'O' sao circulos (usados como rodas), '}' e'
; um BLOCO TOTALMENTE PREENCHIDO (usado como carroceria/corpo solido):
;   Onibus Amarelo "o}}}o" - linha 6  - largura 5 (roda-corpo-corpo-corpo-roda)
;   Carro  Vermelho "o}o"  - linha 11 - largura 3 (roda-corpo-roda)
;   Onibus Branco  "oSCo"  - linha 16 - largura 4 (roda-S-C-roda, mantem a marcacao "SC")
;   Carro  Azul    "o}o"   - linha 21 - largura 3
;   Carro  Cinza   "o}o"   - linha 26 - largura 3
;
; JOGADOR: sprite de 2 celulas (cabeca 'o' em cima + corpo '}' embaixo, bloco
;          solido), representando o boneco pixelado visto de costas.
;
; CENARIO (predios da linha de chegada): linha 1 usa '#' (padrao de grade do
;          charmap, parece janelas) e linha 2 usa '}' (bloco solido, parede).
; ============================================================================

jmp INICIO

; ============================================================================
; AREA DE DADOS - VARIAVEIS E CONSTANTES DO JOGO
; ============================================================================

; ---- Estado do Jogador (Comeca na base da tela, linha 29, meio da rua) ----
px : var #1
static px + #0, #20          ; Coluna X atual (0 a 39)

py : var #1
static py + #0, #29          ; Linha Y atual (0 a 29)

player_addr : var #1
static player_addr + #0, #1180 ; Endereco na tela = (29 * 40) + 20

; ---- Obstaculo 1: Onibus Amarelo "[BUS]" (Linha 6, largura 5) ------------
ob1_addr : var #1
static ob1_addr + #0, #240     ; Posicao inicial = (6*40)+0
ob1_ini : var #1
static ob1_ini + #0, #240      ; Limite esquerdo da faixa (coluna 0)
ob1_fim : var #1
static ob1_fim + #0, #275      ; Limite direito (coluna 35 - respeita largura 5)

; ---- Obstaculo 2: Carro Vermelho "[o]" (Linha 11, largura 3) -------------
ob2_addr : var #1
static ob2_addr + #0, #448     ; Posicao inicial = (11*40)+8
ob2_ini : var #1
static ob2_ini + #0, #440      ; Limite esquerdo da faixa (coluna 0)
ob2_fim : var #1
static ob2_fim + #0, #477      ; Limite direito (coluna 37 - respeita largura 3)

; ---- Obstaculo 3: Onibus Branco "[SC]" (Linha 16, largura 4) ------------
ob3_addr : var #1
static ob3_addr + #0, #656     ; Posicao inicial = (16*40)+16
ob3_ini : var #1
static ob3_ini + #0, #640      ; Limite esquerdo da faixa (coluna 0)
ob3_fim : var #1
static ob3_fim + #0, #676      ; Limite direito (coluna 36 - respeita largura 4)

; ---- Obstaculo 4: Carro Azul "(o)" (Linha 21, largura 3) -----------------
ob4_addr : var #1
static ob4_addr + #0, #864     ; Posicao inicial = (21*40)+24
ob4_ini : var #1
static ob4_ini + #0, #840      ; Limite esquerdo da faixa (coluna 0)
ob4_fim : var #1
static ob4_fim + #0, #877      ; Limite direito (coluna 37 - respeita largura 3)

; ---- Obstaculo 5: Carro Cinza "<o>" (Linha 26, largura 3) ----------------
ob5_addr : var #1
static ob5_addr + #0, #1072    ; Posicao inicial = (26*40)+32
ob5_ini : var #1
static ob5_ini + #0, #1040     ; Limite esquerdo da faixa (coluna 0)
ob5_fim : var #1
static ob5_fim + #0, #1077     ; Limite direito (coluna 37 - respeita largura 3)

; ---- Mensagens Finais -----------------------------------------------------
msg_vitoria : string " CHEGOU NA USP! AGORA FORMAR! \0"
msg_derrota : string " ATROPELADO! FIM DE JOGO! \0"

; ============================================================================
; PROGRAMA PRINCIPAL
; ============================================================================
INICIO:
    call Apagar_Tela            ; Limpa lixo da memoria
    call Desenhar_Cenario_Fixo  ; Desenha calcada, predios e letreiro da USP
    call Desenhar_Dinamicos     ; Desenha jogador e os 5 obstaculos pela 1a vez

LOOP_PRINCIPAL:
    call Apagar_Dinamicos       ; 1. Apaga jogador e obstaculos da posicao ATUAL
    
    call Ler_Teclado            ; 2. Calcula nova posicao do Jogador
    call Mover_Obstaculos       ; 3. Calcula nova posicao dos obstaculos
    
    call Desenhar_Dinamicos     ; 4. Desenha todo mundo nas NOVAS posicoes COM COR
    
    call Testar_Colisao         ; 5. Verifica se o jogador bateu em algum obstaculo
    call Testar_Vitoria         ; 6. Verifica se o jogador venceu
    
    call Atraso_Jogo            ; 7. Pequeno delay para o jogo ser jogavel
    
    jmp LOOP_PRINCIPAL          ; Repete o ciclo

; ============================================================================
; SUBROTINAS DO JOGO
; ============================================================================

; ----------------------------------------------------------------------------
; Apagar_Tela: preenche toda a tela (0 a 1199) com espaco em branco.
; Registradores: r0 = contador/endereco | r1 = limite | r2 = caractere ' '
; ----------------------------------------------------------------------------
Apagar_Tela:
    push r0
    push r1
    push r2
    loadn r0, #0
    loadn r1, #1200
    loadn r2, #' '
AT_Loop:
    cmp r0, r1
    jeq AT_Fim
    outchar r2, r0
    inc r0
    jmp AT_Loop
AT_Fim:
    pop r2
    pop r1
    pop r0
    rts

; ----------------------------------------------------------------------------
; Desenhar_Cenario_Fixo: desenha os elementos que NUNCA se movem:
;   - Linha 1: fachada de 5 predios lado a lado (cinza/azul alternados)
;              com "USP" centralizado em BRANCO por cima do predio do meio
;   - Linha 2: base dos mesmos 5 predios (linha de chegada)
;   - Linha 29: calcada de saida (ponto de partida do jogador)
; Registradores: r0 = endereco atual | r1 = endereco limite
;                r2 = caractere/valor final (char+cor) | r3 = cor / caractere
; ----------------------------------------------------------------------------
Desenhar_Cenario_Fixo:
    push r0
    push r1
    push r2
    push r3

    ; ================= LINHA 1 - FACHADA DOS PREDIOS (5 predios) =================
    ; Predio 1 (cinza) - colunas 0-7 -> enderecos 40-47
    loadn r0, #40
    loadn r1, #48
    loadn r2, #'#'               ; '#' no charmap = padrao de grade (janelas)
    loadn r3, #2048             ; Cor: Cinza
    add r2, r2, r3
DCF_P1:
    cmp r0, r1
    jeq DCF_P2_Prep
    outchar r2, r0
    inc r0
    jmp DCF_P1

DCF_P2_Prep:
    ; Predio 2 (azul) - colunas 8-15 -> enderecos 48-55
    loadn r0, #48
    loadn r1, #56
    loadn r2, #'#'
    loadn r3, #3072             ; Cor: Azul
    add r2, r2, r3
DCF_P2:
    cmp r0, r1
    jeq DCF_P3_Prep
    outchar r2, r0
    inc r0
    jmp DCF_P2

DCF_P3_Prep:
    ; Predio 3 (cinza) - colunas 16-23 -> enderecos 56-63 (recebe o "USP" por cima)
    loadn r0, #56
    loadn r1, #64
    loadn r2, #'#'
    loadn r3, #2048             ; Cor: Cinza
    add r2, r2, r3
DCF_P3:
    cmp r0, r1
    jeq DCF_P4_Prep
    outchar r2, r0
    inc r0
    jmp DCF_P3

DCF_P4_Prep:
    ; Predio 4 (azul) - colunas 24-31 -> enderecos 64-71
    loadn r0, #64
    loadn r1, #72
    loadn r2, #'#'
    loadn r3, #3072             ; Cor: Azul
    add r2, r2, r3
DCF_P4:
    cmp r0, r1
    jeq DCF_P5_Prep
    outchar r2, r0
    inc r0
    jmp DCF_P4

DCF_P5_Prep:
    ; Predio 5 (cinza) - colunas 32-39 -> enderecos 72-79
    loadn r0, #72
    loadn r1, #80
    loadn r2, #'#'
    loadn r3, #2048             ; Cor: Cinza
    add r2, r2, r3
DCF_P5:
    cmp r0, r1
    jeq DCF_USP_Prep
    outchar r2, r0
    inc r0
    jmp DCF_P5

DCF_USP_Prep:
    ; ============= "USP" CENTRALIZADO EM BRANCO (sobrepoe o predio 3) =============
    loadn r0, #58                ; Coluna 18 da linha 1 = (1*40)+18
    loadn r3, #3840              ; Cor: Branco

    loadn r1, #'U'
    add r2, r1, r3
    outchar r2, r0
    inc r0

    loadn r1, #'S'
    add r2, r1, r3
    outchar r2, r0
    inc r0

    loadn r1, #'P'
    add r2, r1, r3
    outchar r2, r0

    ; ================= LINHA 2 - BASE DOS PREDIOS (linha de chegada) ==============
    ; Mesma disposicao de 5 predios, cores alinhadas com a linha 1
    ; Predio 1 (cinza) - enderecos 80-87
    loadn r0, #80
    loadn r1, #88
    loadn r2, #'}'               ; '}' no charmap = bloco totalmente preenchido
    loadn r3, #2048
    add r2, r2, r3
DCF_B1:
    cmp r0, r1
    jeq DCF_B2_Prep
    outchar r2, r0
    inc r0
    jmp DCF_B1

DCF_B2_Prep:
    ; Predio 2 (azul) - enderecos 88-95
    loadn r0, #88
    loadn r1, #96
    loadn r2, #'}'
    loadn r3, #3072
    add r2, r2, r3
DCF_B2:
    cmp r0, r1
    jeq DCF_B3_Prep
    outchar r2, r0
    inc r0
    jmp DCF_B2

DCF_B3_Prep:
    ; Predio 3 (cinza) - enderecos 96-103
    loadn r0, #96
    loadn r1, #104
    loadn r2, #'}'
    loadn r3, #2048
    add r2, r2, r3
DCF_B3:
    cmp r0, r1
    jeq DCF_B4_Prep
    outchar r2, r0
    inc r0
    jmp DCF_B3

DCF_B4_Prep:
    ; Predio 4 (azul) - enderecos 104-111
    loadn r0, #104
    loadn r1, #112
    loadn r2, #'}'
    loadn r3, #3072
    add r2, r2, r3
DCF_B4:
    cmp r0, r1
    jeq DCF_B5_Prep
    outchar r2, r0
    inc r0
    jmp DCF_B4

DCF_B5_Prep:
    ; Predio 5 (cinza) - enderecos 112-119
    loadn r0, #112
    loadn r1, #120
    loadn r2, #'}'
    loadn r3, #2048
    add r2, r2, r3
DCF_B5:
    cmp r0, r1
    jeq DCF_Calcada_Prep
    outchar r2, r0
    inc r0
    jmp DCF_B5

DCF_Calcada_Prep:
    ; ================= LINHA 29 - CALCADA DE SAIDA (ponto de partida) =============
    loadn r0, #1160
    loadn r1, #1200
    loadn r2, #'-'
    loadn r3, #2048              ; Cor: Cinza
    add r2, r2, r3
DCF_Calcada:
    cmp r0, r1
    jeq DCF_Fim
    outchar r2, r0
    inc r0
    jmp DCF_Calcada

DCF_Fim:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; ----------------------------------------------------------------------------
; Apagar_Dinamicos: apaga (escreve espaco) em cima de todas as celulas onde o
; jogador e os 5 obstaculos estao ATUALMENTE, antes de recalcular as posicoes.
; Registradores: r0 = caractere ' ' | r1 = endereco da celula | r2 = deslocamento (40)
; ----------------------------------------------------------------------------
Apagar_Dinamicos:
    push r0
    push r1
    push r2

    loadn r0, #' '               ; r0 = caractere vazio
    loadn r2, #40                ; r2 = deslocamento de 1 linha (para a cabeca)

    ; ---- Jogador: apaga corpo e cabeca ----
    load r1, player_addr
    outchar r0, r1                ; Apaga o corpo
    sub r1, r1, r2
    outchar r0, r1                ; Apaga a cabeca (uma linha acima do corpo)

    ; ---- Onibus Amarelo (5 celulas) ----
    load r1, ob1_addr
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1

    ; ---- Carro Vermelho (3 celulas) ----
    load r1, ob2_addr
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1

    ; ---- Onibus Branco (4 celulas) ----
    load r1, ob3_addr
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1

    ; ---- Carro Azul (3 celulas) ----
    load r1, ob4_addr
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1

    ; ---- Carro Cinza (3 celulas) ----
    load r1, ob5_addr
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1

    pop r2
    pop r1
    pop r0
    rts

; ----------------------------------------------------------------------------
; Desenhar_Dinamicos: desenha o jogador e os 5 obstaculos em suas posicoes
; ATUAIS, cada um com seu desenho (varios caracteres) e cor.
; Registradores: r0 = valor final (char+cor) | r1 = endereco da celula
;                r2 = caractere puro | r3 = cor
; ----------------------------------------------------------------------------
Desenhar_Dinamicos:
    push r0
    push r1
    push r2
    push r3

    ; ---- Onibus Amarelo "o}}}o" (linha 6) - roda-corpo solido-corpo-corpo-roda ----
    load r1, ob1_addr
    loadn r3, #2816              ; Cor: Amarelo
    loadn r2, #'o'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'}'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'}'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'}'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'o'
    add r0, r2, r3
    outchar r0, r1

    ; ---- Carro Vermelho "o}o" (linha 11) - roda-corpo solido-roda ----
    load r1, ob2_addr
    loadn r3, #2304              ; Cor: Vermelho
    loadn r2, #'o'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'}'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'o'
    add r0, r2, r3
    outchar r0, r1

    ; ---- Onibus Branco "oSCo" (linha 16) - roda-S-C-roda ----
    load r1, ob3_addr
    loadn r3, #3840              ; Cor: Branco
    loadn r2, #'o'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'S'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'C'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'o'
    add r0, r2, r3
    outchar r0, r1

    ; ---- Carro Azul "o}o" (linha 21) - roda-corpo solido-roda ----
    load r1, ob4_addr
    loadn r3, #3072              ; Cor: Azul
    loadn r2, #'o'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'}'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'o'
    add r0, r2, r3
    outchar r0, r1

    ; ---- Carro Cinza "o}o" (linha 26) - roda-corpo solido-roda ----
    load r1, ob5_addr
    loadn r3, #2048               ; Cor: Cinza
    loadn r2, #'o'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'}'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'o'
    add r0, r2, r3
    outchar r0, r1

    ; ---- Jogador: boneco pixelado de costas (2 celulas: corpo + cabeca) ----
    ; Corpo (verde) na posicao atual do jogador - '}' e' um bloco solido
    ; (torso), mais parecido com um sprite de pixel art do que uma letra
    load r1, player_addr
    loadn r2, #'}'
    loadn r3, #512                ; Cor: Verde
    add r0, r2, r3
    outchar r0, r1

    ; Cabeca (cinza) uma linha acima do corpo
    loadn r3, #40
    sub r1, r1, r3
    loadn r2, #'o'
    loadn r3, #2048                ; Cor: Cinza (cabelo)
    add r0, r2, r3
    outchar r0, r1

    pop r3
    pop r2
    pop r1
    pop r0
    rts

; ----------------------------------------------------------------------------
; Ler_Teclado: le a tecla pressionada (W/A/S/D) e atualiza px, py e
; player_addr de acordo. (Logica identica a original, nao foi alterada.)
; ----------------------------------------------------------------------------
Ler_Teclado:
    push r0
    push r1
    push r2
    push r3
    
    inchar r0
    loadn r1, #255
    cmp r0, r1
    jeq LT_Sair
    
    loadn r1, #119      ; 'w'
    cmp r0, r1
    jeq LT_Cima
    
    loadn r1, #115      ; 's'
    cmp r0, r1
    jeq LT_Baixo
    
    loadn r1, #97       ; 'a'
    cmp r0, r1
    jeq LT_Esquerda
    
    loadn r1, #100      ; 'd'
    cmp r0, r1
    jeq LT_Direita
    
    jmp LT_Sair

LT_Cima:
    load r1, py
    loadn r2, #2
    cmp r1, r2
    jeq LT_Sair         ; Se ja esta no muro da USP (linha 2), nao sobe mais
    dec r1
    store py, r1
    load r2, player_addr
    loadn r3, #40
    sub r2, r2, r3
    store player_addr, r2
    jmp LT_Sair

LT_Baixo:
    load r1, py
    loadn r2, #29
    cmp r1, r2
    jeq LT_Sair
    inc r1
    store py, r1
    load r2, player_addr
    loadn r3, #40
    add r2, r2, r3
    store player_addr, r2
    jmp LT_Sair

LT_Esquerda:
    load r1, px
    loadn r2, #0
    cmp r1, r2
    jeq LT_Sair
    dec r1
    store px, r1
    load r2, player_addr
    dec r2
    store player_addr, r2
    jmp LT_Sair

LT_Direita:
    load r1, px
    loadn r2, #39
    cmp r1, r2
    jeq LT_Sair
    inc r1
    store px, r1
    load r2, player_addr
    inc r2
    store player_addr, r2

LT_Sair:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; ----------------------------------------------------------------------------
; Mover_Obstaculos: avanca cada obstaculo 1 coluna para a direita; ao chegar
; no limite da faixa (fim), volta para o inicio (ini). Mesma logica original,
; repetida para os 5 obstaculos.
; Registradores: r0 = endereco novo | r1 = limite da faixa
; ----------------------------------------------------------------------------
Mover_Obstaculos:
    push r0
    push r1

    load r0, ob1_addr
    inc r0
    load r1, ob1_fim
    cmp r0, r1
    jne MO_1
    load r0, ob1_ini
MO_1:
    store ob1_addr, r0

    load r0, ob2_addr
    inc r0
    load r1, ob2_fim
    cmp r0, r1
    jne MO_2
    load r0, ob2_ini
MO_2:
    store ob2_addr, r0

    load r0, ob3_addr
    inc r0
    load r1, ob3_fim
    cmp r0, r1
    jne MO_3
    load r0, ob3_ini
MO_3:
    store ob3_addr, r0

    load r0, ob4_addr
    inc r0
    load r1, ob4_fim
    cmp r0, r1
    jne MO_4
    load r0, ob4_ini
MO_4:
    store ob4_addr, r0

    load r0, ob5_addr
    inc r0
    load r1, ob5_fim
    cmp r0, r1
    jne MO_5
    load r0, ob5_ini
MO_5:
    store ob5_addr, r0

    pop r1
    pop r0
    rts

; ----------------------------------------------------------------------------
; Testar_Colisao: verifica se a celula do CORPO do jogador (player_addr)
; coincide com alguma das celulas ocupadas pelos 5 obstaculos.
; Registradores: r0 = endereco do jogador | r1 = endereco da celula testada
; ----------------------------------------------------------------------------
Testar_Colisao:
    push r0
    push r1

    load r0, player_addr

    ; ---- Onibus Amarelo (5 celulas) ----
    load r1, ob1_addr
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu

    ; ---- Carro Vermelho (3 celulas) ----
    load r1, ob2_addr
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu

    ; ---- Onibus Branco (4 celulas) ----
    load r1, ob3_addr
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu

    ; ---- Carro Azul (3 celulas) ----
    load r1, ob4_addr
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu

    ; ---- Carro Cinza (3 celulas) ----
    load r1, ob5_addr
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu

    pop r1
    pop r0
    rts

TC_Bateu:
    call Apagar_Tela
    loadn r0, #567          
    loadn r1, #msg_derrota  
    loadn r2, #2304         ; Vermelho 
    call Imprimestr
    halt

; ----------------------------------------------------------------------------
; Testar_Vitoria: verifica se o jogador chegou na linha 2 (base dos predios).
; (Logica identica a original, nao foi alterada - tela de vitoria a ajustar
; depois.)
; ----------------------------------------------------------------------------
Testar_Vitoria:
    push r0
    push r1
    
    load r0, py
    loadn r1, #2
    cmp r0, r1
    jne TV_Fim              ; Se PY != 2, ainda nao pisou no campus
    
    call Apagar_Tela
    loadn r0, #567
    loadn r1, #msg_vitoria
    loadn r2, #512          ; Verde
    call Imprimestr
    halt

TV_Fim:
    pop r1
    pop r0
    rts

Atraso_Jogo:
    push r0
    push r1
    
    loadn r1, #20        ; MULTIPLICADOR: Aumente aqui (ex: 10, 15, 20) para ficar MUITO mais lento
AJ_Fora:
    loadn r0, #10000    ; Contador interno
AJ_Dentro:
    dec r0
    jnz AJ_Dentro       ; Fica travado aqui ate r0 zerar
    
    dec r1
    jnz AJ_Fora         ; Repete o contador de 10000 várias vezes (baseado no r1)
    
    pop r1
    pop r0
    rts
AJ_Loop:
    dec r0
    jnz AJ_Loop
    pop r0
    rts

Imprimestr:
    push r0
    push r1
    push r2
    push r3
    push r4
    
    loadn r3, #'\0'
ImprimestrLoop: 
    loadi r4, r1
    cmp r4, r3
    jeq ImprimestrSai
    add r4, r2, r4
    outchar r4, r0
    inc r0
    inc r1
    jmp ImprimestrLoop
    
ImprimestrSai:  
    pop r4  
    pop r3
    pop r2
    pop r1
    pop r0
    rts