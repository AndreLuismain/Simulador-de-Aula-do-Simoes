; ============================================================================
; TRAVESSIA AV. SANCA
; ============================================================================
; Disciplina : SSC0511/SSC0513 - Arquitetura de Computadores I
; Processador: ICMC (RISC, 16 bits) - Prof. Eduardo do Valle Simoes (USP Sao Carlos)
; Arquivo    : JOGO.ASM
;
; DESCRICAO GERAL
; ----------------
; Jogo no estilo "Frogger" ambientado em Sao Carlos. O jogador (E) e um
; estudante da EESC que precisa atravessar a Avenida Trabalhador Sao-carlense,
; desviando de onibus (O), bicicletas (B) e capivaras (C) que se movem
; horizontalmente em 3 faixas da avenida.
;
; O jogador comeca na calcada de baixo da tela (linha 9) e vence o jogo ao
; alcancar a calcada de cima (linha 0, a "calcada da EESC"). Se em algum
; momento a posicao do jogador coincidir com a de um obstaculo, o jogo
; termina em derrota.
;
; ORGANIZACAO DA TELA (MEMORIA DE VIDEO)
; ---------------------------------------
; A tela e tratada como uma matriz de 20 colunas x 10 linhas (200 posicoes
; de memoria), varrida "linha a linha" (row-major), comecando no endereco
; VIDEO_BASE. A posicao de qualquer celula (linha Y, coluna X) seria, em
; teoria:
;
;       endereco = VIDEO_BASE + (Y * 20) + X
;
; Como o processador ICMC eh RISC e o conjunto de instrucoes base nao inclui
; MULT, EVITAMOS calcular Y*20 em tempo de execucao. Em vez disso, guardamos
; diretamente o ENDERECO DE VIDEO de cada elemento (jogador e obstaculos)
; como uma variavel, e o atualizamos por SOMA/SUBTRACAO:
;   - Mover 1 coluna para a direita  -> soma 1 ao endereco
;   - Mover 1 coluna para a esquerda -> subtrai 1 do endereco
;   - Mover 1 linha para baixo       -> soma LARGURA (20) ao endereco
;   - Mover 1 linha para cima        -> subtrai LARGURA (20) do endereco
;
; Isso permite implementar todo o jogo usando apenas ADD, SUB, CMP, JEQ e
; JMP, sem depender de multiplicacao/divisao.
;
; ATENCAO - PREMISSAS QUE DEVEM SER CONFERIDAS NO SEU SIMULADOR
; ----------------------------------------------------------------
; 1) VIDEO_BASE (4096) e o endereco que assumimos ser o inicio da memoria de
;    video exibida na tela do Simulador ICMC. Confira no seu simulador
;    (janela de memoria / documentacao da disciplina) qual e o endereco
;    real. IMPORTANTE: este dialeto de assembly (assim como Neander/Ahmes/
;    Ramses) normalmente NAO aceita expressoes/contas na declaracao de
;    dados, apenas numeros literais. Por isso, todos os enderecos derivados
;    de VIDEO_BASE (linhas, obstaculos, jogador, mensagens finais) foram
;    calculados a mao e estao escritos como numeros literais na area de
;    dados - cada um com um comentario mostrando a formula usada. Se o
;    endereco real do seu simulador for diferente de 4096, recalcule e
;    substitua manualmente cada um desses literais usando as formulas
;    indicadas nos comentarios.
; 2) Assumimos que LOAD/STORE aceitam dois modos de enderecamento:
;       (a) DIRETO:   LOAD Rd, ROTULO      /  STORE ROTULO, Rd
;       (b) INDIRETO: LOAD Rd, [Rend]      /  STORE [Rend], Rd
;    O modo indireto (b) e usado SOMENTE nos lacos que percorrem varias
;    posicoes de video (Apagar_Tela e o desenho das duas calcadas em
;    Desenhar_Cenario), pois sem ele seria necessario escrever um STORE
;    literal para cada uma das 200 celulas da tela. Se a sintaxe de
;    enderecamento indireto do seu simulador for diferente (ex.: outro
;    caractere em vez de colchetes, ou uma instrucao separada), ajuste
;    apenas essas linhas - todas estao marcadas com "(indireto)".
; 3) Assumimos que "IN Rd" faz uma leitura BLOQUEANTE do teclado (o programa
;    fica parado esperando uma tecla) e devolve o codigo ASCII da tecla em
;    Rd. Por isso o jogo funciona "por turnos": a cada tecla pressionada,
;    o mundo (obstaculos) avanca um passo. Caso o IN do seu simulador exija
;    um numero de porta/dispositivo como segundo operando, ajuste a linha
;    "IN R1" dentro de Ler_Teclado.
; 4) Todas as instrucoes de ULA (ADD/SUB/CMP) sao usadas no formato de
;    3 operandos com registradores (ex.: ADD Rd, Rs1, Rs2), tipico de
;    arquiteturas RISC. Constantes so entram no processador via LOADN.
;
; CONVENCAO DE REGISTRADORES
; ---------------------------
; Nenhum registrador guarda estado "global" entre chamadas de sub-rotina:
; cada sub-rotina LE da memoria (LOAD) as variaveis de que precisa logo no
; inicio, e GRAVA (STORE) os resultados de volta na memoria antes do RET.
; Isso evita bugs de "registrador sujo" ao encadear varios CALL. Dentro de
; cada sub-rotina, os registradores R1-R7 sao usados como variaveis
; temporarias; o papel de cada um esta explicado no cabecalho de comentario
; de cada sub-rotina e nas linhas de codigo.
; ============================================================================

; ============================================================================
; TRAVESSIA EESC - A VINGANCA (VERSAO OTIMIZADA)
; ============================================================================
; Processador: ICMC (RISC, 16 bits) - Prof. Eduardo do Valle Simoes
; Arquivo    : JOGO.ASM
;
; DESCRICAO GERAL
; ----------------
; O jogador 'E' (Estudante de Engenharia Mecanica) precisa atravessar a 
; Avenida Trabalhador Sao-carlense, desviando de onibus (O), bicicletas (B) 
; e capivaras (C).
;
; O QUE MUDOU PARA FICAR BOM:
; 1. A tela e de 40 colunas x 30 linhas (0 a 1199).
; 2. O cenario fixo (calcadas) e desenhado UMA UNICA VEZ no inicio.
; 3. O Loop Principal apaga e redesenha APENAS o jogador e os obstaculos.
;    Isso elimina totalmente a tela piscando (flickering).
; 4. A leitura do teclado usa 'inchar' e as limitacoes de borda voltaram.
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

; ---- Obstaculo 1: Onibus 'O' (Linha 10) -----------------------------------
obst1_addr : var #1
static obst1_addr + #0, #400   ; Posicao inicial = (10 * 40) + 0
obst1_ini : var #1
static obst1_ini + #0, #400    ; Limite esquerdo da faixa 1
obst1_fim : var #1
static obst1_fim + #0, #440    ; Limite direito (fim da faixa 1)

; ---- Obstaculo 2: Bicicleta 'B' (Linha 15) --------------------------------
obst2_addr : var #1
static obst2_addr + #0, #615   ; Posicao inicial = (15 * 40) + 15
obst2_ini : var #1
static obst2_ini + #0, #600    ; Limite esquerdo da faixa 2
obst2_fim : var #1
static obst2_fim + #0, #640    ; Limite direito (fim da faixa 2)

; ---- Obstaculo 3: Capivara 'C' (Linha 20) ---------------------------------
obst3_addr : var #1
static obst3_addr + #0, #830   ; Posicao inicial = (20 * 40) + 30
obst3_ini : var #1
static obst3_ini + #0, #800    ; Limite esquerdo da faixa 3
obst3_fim : var #1
static obst3_fim + #0, #840    ; Limite direito (fim da faixa 3)

; ---- Mensagens Finais -----------------------------------------------------
msg_vitoria : string " CHEGOU NA EESC! VITORIA! \0"
msg_derrota : string " ATROPELADO! FIM DE JOGO! \0"

; ============================================================================
; PROGRAMA PRINCIPAL
; ============================================================================
INICIO:
    call Apagar_Tela            ; Limpa lixo da memoria
    call Desenhar_Cenario_Fixo  ; Desenha calcadas apenas uma vez
    call Desenhar_Dinamicos     ; Desenha os personagens pela primeira vez

LOOP_PRINCIPAL:
    call Apagar_Dinamicos       ; 1. Imprime ' ' em cima de onde eles estao AGORA
    
    call Ler_Teclado            ; 2. Calcula nova posicao do Jogador
    call Mover_Obstaculos       ; 3. Calcula nova posicao dos Inimigos
    
    call Desenhar_Dinamicos     ; 4. Desenha todo mundo nas NOVAS posicoes
    
    call Testar_Colisao         ; 5. Verifica se alguem bateu
    call Testar_Vitoria         ; 6. Verifica se o jogador venceu
    
    call Atraso_Jogo            ; 7. Pequeno delay para o jogo ser jogavel
    
    jmp LOOP_PRINCIPAL          ; Repete o ciclo

; ============================================================================
; SUBROTINAS DO JOGO
; ============================================================================

; ----------------------------------------------------------------------------
; Apagar_Tela - Limpa todas as 1200 posicoes com espaco
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
; Desenhar_Cenario_Fixo - Desenha as duas calcadas (# em cima, - embaixo)
; ----------------------------------------------------------------------------
Desenhar_Cenario_Fixo:
    push r0
    push r1
    push r2
    
    ; Desenha Calcada EESC (Linha 0: pos 0 a 39)
    loadn r0, #0
    loadn r1, #40
    loadn r2, #'#'
DC_Topo:
    cmp r0, r1
    jeq DC_Base_Prep
    outchar r2, r0
    inc r0
    jmp DC_Topo
    
DC_Base_Prep:
    ; Desenha Calcada de Saida (Linha 29: pos 1160 a 1199)
    loadn r0, #1160
    loadn r1, #1200
    loadn r2, #'-'
DC_Base:
    cmp r0, r1
    jeq DC_Fim
    outchar r2, r0
    inc r0
    jmp DC_Base

DC_Fim:
    pop r2
    pop r1
    pop r0
    rts

; ----------------------------------------------------------------------------
; Apagar_Dinamicos - Substitui as posicoes atuais por ' ' antes de mover
; ----------------------------------------------------------------------------
Apagar_Dinamicos:
    push r0
    push r1
    
    loadn r0, #' '
    
    load r1, player_addr
    outchar r0, r1
    
    load r1, obst1_addr
    outchar r0, r1
    
    load r1, obst2_addr
    outchar r0, r1
    
    load r1, obst3_addr
    outchar r0, r1
    
    pop r1
    pop r0
    rts

; ----------------------------------------------------------------------------
; Desenhar_Dinamicos - Desenha jogador e obstaculos em suas posicoes atuais
; ----------------------------------------------------------------------------
Desenhar_Dinamicos:
    push r0
    push r1
    
    loadn r0, #'O'
    load r1, obst1_addr
    outchar r0, r1
    
    loadn r0, #'B'
    load r1, obst2_addr
    outchar r0, r1
    
    loadn r0, #'C'
    load r1, obst3_addr
    outchar r0, r1
    
    ; Desenha jogador por ultimo para ficar sobreposto se houver colisao visual
    loadn r0, #'E'
    load r1, player_addr
    outchar r0, r1

    pop r1
    pop r0
    rts

; ----------------------------------------------------------------------------
; Ler_Teclado - Controle W,A,S,D usando as limitacoes criadas no seu arquivo
; ----------------------------------------------------------------------------
Ler_Teclado:
    push r0
    push r1
    push r2
    push r3
    
    inchar r0
    loadn r1, #255
    cmp r0, r1
    jeq LT_Sair         ; Se 255, nenhuma tecla foi apertada
    
    ; Compara teclas
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
    loadn r2, #0
    cmp r1, r2
    jeq LT_Sair         ; Se ja esta no Y = 0, nao sobe
    dec r1
    store py, r1
    load r2, player_addr
    loadn r3, #40
    sub r2, r2, r3      ; Addr -= 40
    store player_addr, r2
    jmp LT_Sair

LT_Baixo:
    load r1, py
    loadn r2, #29
    cmp r1, r2
    jeq LT_Sair         ; Se ja esta no Y = 29, nao desce
    inc r1
    store py, r1
    load r2, player_addr
    loadn r3, #40
    add r2, r2, r3      ; Addr += 40
    store player_addr, r2
    jmp LT_Sair

LT_Esquerda:
    load r1, px
    loadn r2, #0
    cmp r1, r2
    jeq LT_Sair         ; Se ja esta no X = 0, nao vai a esquerda
    dec r1
    store px, r1
    load r2, player_addr
    dec r2              ; Addr -= 1
    store player_addr, r2
    jmp LT_Sair

LT_Direita:
    load r1, px
    loadn r2, #39
    cmp r1, r2
    jeq LT_Sair         ; Se ja esta no X = 39, nao vai a direita
    inc r1
    store px, r1
    load r2, player_addr
    inc r2              ; Addr += 1
    store player_addr, r2

LT_Sair:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; ----------------------------------------------------------------------------
; Mover_Obstaculos - Avanca os obstaculos com Wrap Around
; ----------------------------------------------------------------------------
Mover_Obstaculos:
    push r0
    push r1
    
    ; Move Obst1
    load r0, obst1_addr
    inc r0
    load r1, obst1_fim
    cmp r0, r1
    jne MO_1
    load r0, obst1_ini      ; Wrap-around: volta pro inicio da linha
MO_1:
    store obst1_addr, r0
    
    ; Move Obst2
    load r0, obst2_addr
    inc r0
    load r1, obst2_fim
    cmp r0, r1
    jne MO_2
    load r0, obst2_ini
MO_2:
    store obst2_addr, r0

    ; Move Obst3
    load r0, obst3_addr
    inc r0
    load r1, obst3_fim
    cmp r0, r1
    jne MO_3
    load r0, obst3_ini
MO_3:
    store obst3_addr, r0

    pop r1
    pop r0
    rts

; ----------------------------------------------------------------------------
; Testar_Colisao - Se endereco do jogador bater com obstaculos, fim de jogo
; ----------------------------------------------------------------------------
Testar_Colisao:
    push r0
    push r1
    
    load r0, player_addr
    
    load r1, obst1_addr
    cmp r0, r1
    jeq TC_Bateu
    
    load r1, obst2_addr
    cmp r0, r1
    jeq TC_Bateu
    
    load r1, obst3_addr
    cmp r0, r1
    jeq TC_Bateu

    pop r1
    pop r0
    rts

TC_Bateu:
    call Apagar_Tela
    loadn r0, #567          ; Meio da tela
    loadn r1, #msg_derrota  
    loadn r2, #2304         ; Vermelho 
    call Imprimestr
    halt

; ----------------------------------------------------------------------------
; Testar_Vitoria - Se o jogador alcancar o topo (linha 0), ele vence
; ----------------------------------------------------------------------------
Testar_Vitoria:
    push r0
    push r1
    
    load r0, py
    loadn r1, #0
    cmp r0, r1
    jne TV_Fim              ; Se PY != 0, ainda ta na rua
    
    call Apagar_Tela
    loadn r0, #567          ; Meio da tela
    loadn r1, #msg_vitoria
    loadn r2, #512          ; Verde
    call Imprimestr
    halt

TV_Fim:
    pop r1
    pop r0
    rts

; ----------------------------------------------------------------------------
; Atraso_Jogo - Simples laco para desacelerar a execucao
; ----------------------------------------------------------------------------
Atraso_Jogo:
    push r0
    loadn r0, #8000
AJ_Loop:
    dec r0
    jnz AJ_Loop
    pop r0
    rts

; ----------------------------------------------------------------------------
; SUBROTINA DO PROFESSOR (Para mensagens finais)
; ----------------------------------------------------------------------------
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
    
    ; ----------------------------------------------------------------------------
; Desenhar_Cenario_Fixo - Desenha os predios, a logo da USP e a rua
; ----------------------------------------------------------------------------
Desenhar_Cenario_Fixo:
    push r0
    push r1
    push r2
    push r3

    ; 1. Desenha o Ceu/Fundo dos predios (Linhas 0 e 1 vazias)
    
    ; 2. Escreve " U S P " centralizado no topo (Linha 1, aprox pos 56)
    loadn r0, #56
    loadn r2, #2816          ; Cor: Amarelo
    
    loadn r1, #'U'
    add r3, r1, r2
    outchar r3, r0
    inc r0
    inc r0                   ; Pula um espaco
    
    loadn r1, #'S'
    add r3, r1, r2
    outchar r3, r0
    inc r0
    inc r0
    
    loadn r1, #'P'
    add r3, r1, r2
    outchar r3, r0

    ; 3. Desenha a base da USP / Muro (Linha 2 inteira com '#')
    loadn r0, #80
    loadn r1, #120           ; Ate o fim da linha 2
    loadn r2, #'#'
    loadn r3, #512           ; Cor: Verde (Muro/Arvores do campus)
    add r2, r2, r3           ; Soma caractere com a cor
DC_Muro:
    cmp r0, r1
    jeq DC_Base_Prep
    outchar r2, r0
    inc r0
    jmp DC_Muro
    
DC_Base_Prep:
    ; 4. Desenha Calcada de Saida do estudante (Linha 29 com '-')
    loadn r0, #1160
    loadn r1, #1200
    loadn r2, #'-'
    loadn r3, #2048          ; Cor: Cinza
    add r2, r2, r3
DC_Base:
    cmp r0, r1
    jeq DC_Fim
    outchar r2, r0
    inc r0
    jmp DC_Base

DC_Fim:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; ----------------------------------------------------------------------------
; Desenhar_Dinamicos - Desenha os personagens COM CORES
; Tabela: Verde(512), Amarelo(2816), Azul(3072), Vermelho(2304)
; ----------------------------------------------------------------------------
Desenhar_Dinamicos:
    push r0
    push r1
    push r2
    
    ; Desenha Obstaculo 1 (Onibus 'O' -> AMARELO)
    loadn r0, #'O'
    loadn r2, #2816          ; Cor Amarela
    add r0, r0, r2           ; Char + Cor
    load r1, obst1_addr
    outchar r0, r1
    
    ; Desenha Obstaculo 2 (Carro 1 'B' -> AZUL)
    loadn r0, #'B'
    loadn r2, #3072          ; Cor Azul
    add r0, r0, r2
    load r1, obst2_addr
    outchar r0, r1
    
    ; Desenha Obstaculo 3 (Carro 2 'C' -> VERMELHO)
    loadn r0, #'C'
    loadn r2, #2304          ; Cor Vermelha
    add r0, r0, r2
    load r1, obst3_addr
    outchar r0, r1
    
    ; Desenha jogador 'E' -> VERDE (Fica sobreposto se bater)
    loadn r0, #'E'
    loadn r2, #512           ; Cor Verde
    add r0, r0, r2
    load r1, player_addr
    outchar r0, r1

    pop r2
    pop r1
    pop r0
    rts