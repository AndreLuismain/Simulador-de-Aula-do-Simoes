; ============================================================================
; SIMULADOR DE AULA DO SIMOES - EDICAO ARCADE
; ============================================================================

jmp LOBBY

; ============================================================================
; VARIAVEIS E CONSTANTES DO JOGO
; ============================================================================

px : var #1
static px + #0, #20

py : var #1
static py + #0, #29

player_addr : var #1
static player_addr + #0, #1180

; Quadro de animacao do jogador (0 ou 1). Alternado a cada movimento em
; Ler_Teclado e usado em Desenhar_Dinamicos para trocar entre os dois
; sprites do corpo/pernas do personagem ('w' e 'y'), dando a ilusao de
; passos andando (uma perna fica mais comprida, a outra mais curta, e
; alterna a cada passo para frente)
player_frame : var #1
static player_frame + #0, #0

; Atraso atual do jogo (usado em Atraso_Jogo). Comeca em 15 e diminui uma
; unidade cada vez que o jogador vence uma travessia (ate um piso minimo
; de 3), fazendo os carros ficarem mais rapidos a cada fase
atraso_var : var #1
static atraso_var + #0, #15

; Vidas restantes do jogador (coracoes). Comeca em 3; ao ser atingido
; por um obstaculo, perde 1 e volta para o inicio; ao chegar em 0, fim
; de jogo de verdade (tela de derrota)
vidas : var #1
static vidas + #0, #3

; Fase atual (1, 2 ou 3). Define qual banner aparece na linha de chegada
; (USP / ICMC / SIMOES). Ao vencer a fase 3, volta para a fase 1
fase : var #1
static fase + #0, #1

; Pista extra (9a pista), liberada a partir da fase 2, ocupando o vao
; que antes ficava em branco entre a ultima pista normal e a calcada
; inicial (linhas 22-27). Vem em direcao ALEATORIA (direita ou esquerda)
; toda vez que e liberada/reativada
ob9_addr : var #1
static ob9_addr + #0, #960
ob9_ini : var #1
static ob9_ini + #0, #960
ob9_fim : var #1
static ob9_fim + #0, #997
ob9_dir : var #1
static ob9_dir + #0, #0          ; 0 = direita, 1 = esquerda (contramao)
ob9_ativo : var #1
static ob9_ativo + #0, #0        ; 0 = ainda nao liberada, 1 = ativa

; Semente pseudo-aleatoria: cresce sozinha a cada rodada do loop principal.
; Nao existe instrucao de numero aleatorio nesta CPU, entao usamos a
; paridade (par/impar) deste contador no momento em que a pista extra e
; liberada para sortear a direcao dela
rng_seed : var #1
static rng_seed + #0, #0

; Quantas fases (1 ou 2) o jogador ja venceu na tela de check-in antes de
; "morcegar" (voltar pro lobby). Mostrado no lobby como "X/3". Zerado ao
; comecar um novo jogo pelo lobby ou ao completar as 3 fases (vitoria final)
fases_vencidas : var #1
static fases_vencidas + #0, #0

; ---- Estado do Menu Arcade (Lobby) e Recorde da Sessao ----
menu_sel : var #1
static menu_sel + #0, #0         ; 0 = JOGAR, 1 = COMO JOGAR, 2 = CREDITOS
menu_anim : var #1
static menu_anim + #0, #0        ; alterna 0/1 para piscar estrelas e setas
menu_car1 : var #1
static menu_car1 + #0, #4        ; coluna do onibus animado no menu (2..33)
menu_car2 : var #1
static menu_car2 + #0, #20       ; coluna do carro animado no menu (2..34)
recorde : var #1
static recorde + #0, #0          ; maior pontuacao atingida na sessao

; ---- Modo reverso ("caca ao chip do Simoes") ----
; reverso = 0 (jogo normal) ou 1 (voltando da linha de chegada ate o
; inicio, passando pelas 3 fases na ordem contraria: 3 -> 2 -> 1)
reverso : var #1
static reverso + #0, #0

; Chip colecionavel: aparece uma vez, em posicao aleatoria, quando o
; modo reverso comeca. chip_ativo=1 enquanto ele ainda nao foi
; encontrado; chip_addr guarda o endereco onde ele esta na tela
chip_ativo : var #1
static chip_ativo + #0, #0
chip_addr : var #1
static chip_addr + #0, #0
chip_py : var #1
static chip_py + #0, #2

; Marca que o chip ja foi encontrado (modo reverso). A partir daqui o
; objetivo deixa de ser "chegar em py=29 procurando" e passa a ser
; "voltar pra sala" (py=2, fase travada em 3/SIMOES)
chip_encontrado : var #1
static chip_encontrado + #0, #0

; ---- Pontuacao ----
pontuacao : var #1
static pontuacao + #0, #0

; ---- Cronometro (1 min por fase, +3min ao entrar no modo reverso) ----
; tempo_seg = segundos restantes; tempo_frames = contador auxiliar que
; acumula voltas do loop principal ate completar "1 segundo"
tempo_seg : var #1
static tempo_seg + #0, #60
tempo_frames : var #1
static tempo_frames + #0, #0

; 8 linhas "interessantes" onde o chip pode aparecer - pontas do mapa,
; passeios e linha de chegada, cobrindo pistas de carro, grama e calcada
chip_linha0 : var #1
static chip_linha0 + #0, #2
chip_linha1 : var #1
static chip_linha1 + #0, #11
chip_linha2 : var #1
static chip_linha2 + #0, #14
chip_linha3 : var #1
static chip_linha3 + #0, #18
chip_linha4 : var #1
static chip_linha4 + #0, #20
chip_linha5 : var #1
static chip_linha5 + #0, #24
chip_linha6 : var #1
static chip_linha6 + #0, #28
chip_linha7 : var #1
static chip_linha7 + #0, #29

; LIMITES DOS OBSTACULOS:
; Se a linha comeca em X e termina em X+39, e o obstaculo tem tamanho T,
; O limite direito (Fim) = (X+39) - (T-1)

; ---- Obstaculo 8: Linha 20, larg 4 ----
ob8_addr : var #1
static ob8_addr + #0, #800
ob8_ini : var #1
static ob8_ini + #0, #800
ob8_fim : var #1
static ob8_fim + #0, #836

; ---- Obstaculo 7: Linha 18, larg 3 ----
ob7_addr : var #1
static ob7_addr + #0, #725
ob7_ini : var #1
static ob7_ini + #0, #720
ob7_fim : var #1
static ob7_fim + #0, #757

; ---- Obstaculo 6: Linha 16, larg 5 ----
ob6_addr : var #1
static ob6_addr + #0, #640
ob6_ini : var #1
static ob6_ini + #0, #640
ob6_fim : var #1
static ob6_fim + #0, #675

; ---- Obstaculo 5: Linha 14, larg 3 ----
ob5_addr : var #1
static ob5_addr + #0, #570
ob5_ini : var #1
static ob5_ini + #0, #560
ob5_fim : var #1
static ob5_fim + #0, #597

; ---- Obstaculo 4: Linha 10, larg 3 ----
ob4_addr : var #1
static ob4_addr + #0, #415
ob4_ini : var #1
static ob4_ini + #0, #400
ob4_fim : var #1
static ob4_fim + #0, #437

; ---- Obstaculo 3: Linha 8, larg 4 ----
ob3_addr : var #1
static ob3_addr + #0, #325
ob3_ini : var #1
static ob3_ini + #0, #320
ob3_fim : var #1
static ob3_fim + #0, #356

; ---- Obstaculo 2: Linha 6, larg 3 ----
ob2_addr : var #1
static ob2_addr + #0, #245
ob2_ini : var #1
static ob2_ini + #0, #240
ob2_fim : var #1
static ob2_fim + #0, #277

; ---- Obstaculo 1: Linha 4, larg 5 ----
ob1_addr : var #1
static ob1_addr + #0, #176
ob1_ini : var #1
static ob1_ini + #0, #160
ob1_fim : var #1
static ob1_fim + #0, #195

; ============================================================================
; STRINGS DAS TELAS E INTERFACES
; ============================================================================

; ---- Tela Inicial Arcade (Lobby) ----
msg_cabecalho_inst : string "ICMC - USP  *  ARCADE\0"
msg_titulo_p1 : string "SIMULADOR DE AULA \0"
msg_titulo_p2 : string "DO SIMOES\0"
msg_subtitulo : string "TRAVESSIA DO CAMPUS!\0"
msg_recorde_lbl : string "RECORDE:\0"
msg_vidas_lbl : string "VIDAS:\0"
msg_fases_lbl : string "FASES:\0"
msg_btn_jogar : string "JOGAR\0"
msg_btn_comojogar : string "COMO JOGAR\0"
msg_btn_creditos : string "CREDITOS\0"
msg_lobby_enter : string "APERTE ENTER OU ESPACO\0"
msg_lobby_dica : string "W/S: MOVER   1/2/3: ATALHO\0"

; ---- Tela Como Jogar ----
msg_cj_titulo : string "COMO JOGAR\0"
msg_cj_ctrl : string "CONTROLES:\0"
msg_cj_wasd : string "W/A/S/D : MOVER O ALUNO\0"
msg_cj_cm : string "C / M   : CONTINUAR OU MORCEGAR\0"
msg_cj_sn : string "S / N   : BUSCAR CHIP OU SAIR\0"
msg_cj_fases : string "AS 3 FASES:\0"
msg_cj_f1 : string "1. USP   :\0"
msg_cj_f1d : string "AVENIDA MOVIMENTADA\0"
msg_cj_f2 : string "2. ICMC  :\0"
msg_cj_f2d : string "ENTRADA DO CAMPUS\0"
msg_cj_f3 : string "3. SIMOES:\0"
msg_cj_f3d : string "PATIO LOTADO!\0"
msg_cj_regras : string "REGRAS E PONTOS:\0"
msg_cj_vidas : string "3 VIDAS\0"
msg_cj_tempo : string "60S POR FASE\0"
msg_cj_pts1 : string "+10 PASSO  +20 GRAMA  +50 FASE\0"
msg_cj_pts2 : string "BONUS DE TEMPO E VIDAS NO FIM!\0"
msg_cj_rev : string "MODO REVERSO (CHIP DO SIMOES):\0"
msg_cj_rev1 : string "ACHE O CHIP PERDIDO E VOLTE\0"
msg_cj_rev2 : string "ATE A SALA ANTES DO TEMPO ZERAR\0"
msg_btn_voltar : string "VOLTAR (ENTER)\0"

; ---- Tela Creditos ----
msg_cr_titulo : string "CREDITOS DO JOGO\0"
msg_cr_equipe : string "DESENVOLVIDO POR:\0"
msg_cr_dev1 : string "ANDRE LUIS\0"
msg_cr_dev2 : string "DANIEL CHAVES\0"
msg_cr_dev3 : string "JOAO VITOR\0"
msg_cr_dev4 : string "VINICCIUS FARIA\0"
msg_cr_dev5 : string "YURI OBA\0"
msg_cr_hom : string "HOMENAGEM E ORIENTACAO:\0"
msg_cr_prof : string "PROF. EDUARDO DO VALLE SIMOES\0"
msg_cr_usp : string "ICMC - USP  |  ARQ. COMPUTADORES\0"

; ---- Popups de Jogo, Check-in, Derrota e Vitoria ----
msg_vitoria : string "FASE CONCLUIDA! +50 PTS\0"
msg_vitoria_sub : string "MANDOU BEM NA TRAVESSIA!\0"
msg_derrota : string "ATROPELADO! FIM DE JOGO!\0"
msg_derrota_sub : string "TENTE ATRAVESSAR NOVAMENTE!\0"
msg_pts_finais : string "PONTOS FINAIS:\0"
msg_rec_atual : string "MELHOR MARCA :\0"

msg_ck_titulo : string "CHECK-IN DE FASE\0"
msg_ck_pts : string "PONTUACAO ATUAL:\0"
msg_ck_pergunta : string "DECIDA SEU PROXIMO PASSO:\0"
msg_ck_btn_c : string "(C) CONTINUAR RUMO A AULA\0"
msg_ck_btn_m : string "(M) MORCEGAR (IR PRO MENU)\0"

msg_puto_tit : string "CHEGOU NA SALA DO SIMOES!\0"
msg_puto1 : string "MAS O SIMOES ESTA BRAVO PORQUE\0"
msg_puto2 : string "PERDERAM O CHIP DELE NO CAMINHO!\0"
msg_puto3 : string "VOLTE PELO CAMPUS PROCURANDO!\0"
msg_opcao_s : string "(S) BUSCAR O CHIP (+3 MIN)\0"
msg_opcao_esc : string "(N) IGNORAR E IR EMBORA\0"

msg_chip_label : string " CHIP DO SIMOES -> \0"
msg_chip_achado1 : string "VOCE ACHOU O CHIP DO SIMOES!\0"
msg_chip_achado2 : string "VOLTE ATE A SALA E ENTREGUE!\0"

msg_rev_tit : string "MISSAO CUMPRIDA! NOTA 10!\0"
msg_reverso_fim : string "VOCE VOLTOU! O SIMOES ESTA EM PAZ.\0"
msg_rev_sub : string "O CHIP FOI ENTREGUE COM SUCESSO!\0"
msg_fim_enter : string "APERTE ENTER PARA CONTINUAR\0"

; ============================================================================
; PROGRAMA PRINCIPAL
; ============================================================================
INICIO:
    call Apagar_Tela
    call Desenhar_Cenario_Fixo
    call Desenhar_Dinamicos
    call Desenhar_HUD

LOOP_PRINCIPAL:
    call Apagar_Dinamicos
    call Ler_Teclado
    call Mover_Obstaculos
    call Desenhar_Banner_Chegada
    call Desenhar_Dinamicos
    call Testar_Colisao
    call Testar_Chip
    call Testar_Vitoria
    call Atualizar_Cronometro
    call Testar_Tempo
    call Desenhar_HUD
    call Atraso_Jogo
    jmp LOOP_PRINCIPAL

; ============================================================================
; SUBROTINAS DE MOLDURAS E INTERFACE GRAFICA ARCADE
; ============================================================================

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

; Desenha uma janela/moldura dupla estilo gabinete arcade limpando o interior.
; Entrada: r0 = linha topo (y1), r1 = col esq (x1),
;          r2 = linha base (y2), r3 = col dir (x2), r4 = cor
Desenhar_Caixa_Dupla:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6
    push r7

    ; Calcula r5 = y1 * 40
    loadn r5, #0
    mov r6, r0
DCD_MultY1:
    loadn r7, #0
    cmp r6, r7
    jeq DCD_MultY1_Fim
    loadn r7, #40
    add r5, r5, r7
    dec r6
    jmp DCD_MultY1
DCD_MultY1_Fim:

    ; 1. Limpa todo o retangulo interno (y de r0 ate r2, x de r1 ate r3)
    mov r6, r0
    push r5
DCD_Clear_Lin:
    cmp r6, r2
    jgr DCD_Clear_Fim
    mov r7, r1
DCD_Clear_Col:
    cmp r7, r3
    jgr DCD_Clear_ProxLin
    push r0
    add r0, r5, r7
    push r1
    loadn r1, #' '
    outchar r1, r0
    pop r1
    pop r0
    inc r7
    jmp DCD_Clear_Col
DCD_Clear_ProxLin:
    loadn r7, #40
    add r5, r5, r7
    inc r6
    jmp DCD_Clear_Lin
DCD_Clear_Fim:
    pop r5

    ; 2. Borda superior (linha y1, endereco base r5)
    add r6, r5, r1
    loadn r7, #3                 ; canto sup esq
    add r7, r7, r4
    outchar r7, r6

    mov r7, r1
    inc r7
DCD_Topo_Loop:
    cmp r7, r3
    jeq DCD_Topo_Dir
    jgr DCD_Topo_Dir
    add r6, r5, r7
    push r0
    loadn r0, #8                 ; barra dupla horizontal
    add r0, r0, r4
    outchar r0, r6
    pop r0
    inc r7
    jmp DCD_Topo_Loop
DCD_Topo_Dir:
    add r6, r5, r3
    loadn r7, #5                 ; canto sup dir
    add r7, r7, r4
    outchar r7, r6

    ; 3. Laterais verticais (linhas y1+1 ate y2-1)
    mov r6, r0
    inc r6
    mov r7, r5
    push r0
    loadn r0, #40
    add r7, r7, r0
    pop r0
DCD_Meio_Loop:
    cmp r6, r2
    jeq DCD_Base
    jgr DCD_Base
    push r0
    push r6
    loadn r0, #9                 ; barra dupla vertical
    add r0, r0, r4
    add r6, r7, r1
    outchar r0, r6
    add r6, r7, r3
    outchar r0, r6
    loadn r0, #40
    add r7, r7, r0
    pop r6
    pop r0
    inc r6
    jmp DCD_Meio_Loop

    ; 4. Borda inferior (linha y2, endereco base em r7)
DCD_Base:
    add r6, r7, r1
    loadn r5, #6                 ; canto inf esq
    add r5, r5, r4
    outchar r5, r6

    mov r5, r1
    inc r5
DCD_Base_Loop:
    cmp r5, r3
    jeq DCD_Base_Dir
    jgr DCD_Base_Dir
    add r6, r7, r5
    push r0
    loadn r0, #8                 ; barra dupla horizontal
    add r0, r0, r4
    outchar r0, r6
    pop r0
    inc r5
    jmp DCD_Base_Loop
DCD_Base_Dir:
    add r6, r7, r3
    loadn r5, #7                 ; canto inf dir
    add r5, r5, r4
    outchar r5, r6

    pop r7
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; Desenha um botao de 3 linhas de altura (linha simples fina #25..#30).
; Entrada: r0 = linha topo (y), r1 = coluna esq (x), r2 = largura, r3 = cor
Desenhar_Botao:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6
    push r7

    ; r4 = y * 40 + x
    loadn r4, #0
    mov r5, r0
DB_Mult:
    loadn r6, #0
    cmp r5, r6
    jeq DB_Mult_Fim
    loadn r6, #40
    add r4, r4, r6
    dec r5
    jmp DB_Mult
DB_Mult_Fim:
    add r4, r4, r1               ; r4 = topo esq

    ; r5 = largura interna = r2 - 2
    mov r5, r2
    dec r5
    dec r5

    ; --- Linha de cima do botao ---
    mov r6, r4
    loadn r7, #25                ; canto sup esq fino
    add r7, r7, r3
    outchar r7, r6
    inc r6

    mov r0, r5
DB_Top_Loop:
    loadn r7, #0
    cmp r0, r7
    jeq DB_Top_Fim
    loadn r7, #29                ; horizontal fina
    add r7, r7, r3
    outchar r7, r6
    inc r6
    dec r0
    jmp DB_Top_Loop
DB_Top_Fim:
    loadn r7, #26                ; canto sup dir fino
    add r7, r7, r3
    outchar r7, r6

    ; --- Linha do meio do botao ---
    loadn r7, #40
    add r6, r4, r7
    loadn r7, #30                ; vertical fina
    add r7, r7, r3
    outchar r7, r6
    inc r6

    mov r0, r5
DB_Mid_Loop:
    loadn r7, #0
    cmp r0, r7
    jeq DB_Mid_Fim
    loadn r7, #' '
    outchar r7, r6
    inc r6
    dec r0
    jmp DB_Mid_Loop
DB_Mid_Fim:
    loadn r7, #30                ; vertical fina
    add r7, r7, r3
    outchar r7, r6

    ; --- Linha de baixo do botao ---
    loadn r7, #80
    add r6, r4, r7
    loadn r7, #27                ; canto inf esq fino
    add r7, r7, r3
    outchar r7, r6
    inc r6

    mov r0, r5
DB_Bot_Loop:
    loadn r7, #0
    cmp r0, r7
    jeq DB_Bot_Fim
    loadn r7, #29                ; horizontal fina
    add r7, r7, r3
    outchar r7, r6
    inc r6
    dec r0
    jmp DB_Bot_Loop
DB_Bot_Fim:
    loadn r7, #28                ; canto inf dir fino
    add r7, r7, r3
    outchar r7, r6

    pop r7
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; Desenha uma linha divisoria horizontal de caracteres repetidos.
; Entrada: r0 = endereco inicial, r1 = quantidade, r2 = caractere+cor
Desenhar_Linha_Horiz:
    push r0
    push r1
    push r2
    push r3
    loadn r3, #0
DLH_Loop:
    cmp r1, r3
    jeq DLH_Fim
    outchar r2, r0
    inc r0
    dec r1
    jmp DLH_Loop
DLH_Fim:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; Espera um pequeno intervalo de animacao para telas de menu lendo o teclado
; continuamente (sem travar nem perder cliques). Devolve a tecla em r0 (ou 255).
Aguardar_Ou_Ler_Menu:
    push r1
    push r2
    push r3

    loadn r2, #32
AOLM_Fora:
    ; avanca rng_seed continuamente enquanto o jogador navega no menu
    load r3, rng_seed
    inc r3
    loadn r1, #1000
    cmp r3, r1
    jgr AOLM_RngReset
    jeq AOLM_RngReset
    jmp AOLM_RngStore
AOLM_RngReset:
    loadn r3, #0
AOLM_RngStore:
    store rng_seed, r3

    inchar r0
    loadn r1, #255
    cmp r0, r1
    jne AOLM_Sair

    loadn r1, #350
AOLM_Dentro:
    dec r1
    jnz AOLM_Dentro

    dec r2
    jnz AOLM_Fora

    loadn r0, #255
AOLM_Sair:
    pop r3
    pop r2
    pop r1
    rts

; Atualiza o recorde da sessao caso pontuacao > recorde
Atualizar_Recorde:
    push r0
    push r1
    load r0, pontuacao
    load r1, recorde
    cmp r0, r1
    jgr AR_Novo
    jmp AR_Fim
AR_Novo:
    store recorde, r0
AR_Fim:
    pop r1
    pop r0
    rts

; ============================================================================
; SUBROTINAS DE CENARIO E HUD DO JOGO
; ============================================================================

; Desenha os 3 coracoes de vida no canto superior esquerdo (enderecos 0,1,2):
; coracao vermelho cheio ('h') para vidas ativas e coracao vazado cinza (#18)
; para vidas perdidas
Desenhar_Vidas:
    push r0
    push r1
    push r2
    push r3
    push r4

    loadn r2, #'h'
    loadn r3, #2304
    add r2, r2, r3          ; r2 = coracao vermelho cheio

    loadn r4, #18
    loadn r3, #2048
    add r4, r4, r3          ; r4 = coracao vazio cinza

    load r3, vidas

    ; slot 0 (endereco 0)
    loadn r0, #0
    loadn r1, #1
    cmp r3, r1
    jgr DV_S0_Cheio
    jeq DV_S0_Cheio
    outchar r4, r0
    jmp DV_S1
DV_S0_Cheio:
    outchar r2, r0
DV_S1:
    ; slot 1 (endereco 1)
    loadn r0, #1
    loadn r1, #2
    cmp r3, r1
    jgr DV_S1_Cheio
    jeq DV_S1_Cheio
    outchar r4, r0
    jmp DV_S2
DV_S1_Cheio:
    outchar r2, r0
DV_S2:
    ; slot 2 (endereco 2)
    loadn r0, #2
    loadn r1, #3
    cmp r3, r1
    jgr DV_S2_Cheio
    jeq DV_S2_Cheio
    outchar r4, r0
    jmp DV_Fim
DV_S2_Cheio:
    outchar r2, r0
DV_Fim:
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; Desenha o portal central da linha de chegada (linha 2) de acordo com a fase
Desenhar_Banner_Chegada:
    push r0
    push r1
    push r2
    push r3

    load r3, fase
    loadn r1, #1
    cmp r3, r1
    jeq DBC_USP
    loadn r1, #2
    cmp r3, r1
    jeq DBC_ICMC
    jmp DBC_SIMOES

DBC_USP:
    ; Portal: ? U S P ? (enderecos 96..104)
    loadn r0, #96
    loadn r1, #9
    loadn r2, #2816              ; amarelo ouro
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #' '
    outchar r1, r0
    inc r0
    loadn r1, #'U'               ; branco puro (#0)
    outchar r1, r0
    inc r0
    loadn r1, #' '
    outchar r1, r0
    inc r0
    loadn r1, #'S'
    outchar r1, r0
    inc r0
    loadn r1, #' '
    outchar r1, r0
    inc r0
    loadn r1, #'P'
    outchar r1, r0
    inc r0
    loadn r1, #' '
    outchar r1, r0
    inc r0
    loadn r1, #9
    add r1, r1, r2
    outchar r1, r0
    jmp DBC_Fim

DBC_ICMC:
    ; Portal: ? I C M C ? (enderecos 95..105)
    loadn r0, #95
    loadn r1, #9
    loadn r2, #2816              ; borda ouro
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #' '
    outchar r1, r0
    inc r0
    loadn r2, #3584              ; letras aqua
    loadn r1, #'I'
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #' '
    outchar r1, r0
    inc r0
    loadn r1, #'C'
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #' '
    outchar r1, r0
    inc r0
    loadn r1, #'M'
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #' '
    outchar r1, r0
    inc r0
    loadn r1, #'C'
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #' '
    outchar r1, r0
    inc r0
    loadn r1, #9
    loadn r2, #2816
    add r1, r1, r2
    outchar r1, r0
    jmp DBC_Fim

DBC_SIMOES:
    ; Portal: ? S I M O E S ? (enderecos 95..104)
    loadn r0, #95
    loadn r1, #9
    loadn r2, #2816
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #' '
    outchar r1, r0
    inc r0
    loadn r1, #'S'
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #'I'
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #'M'
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #'O'
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #'E'
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #'S'
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #' '
    outchar r1, r0
    inc r0
    loadn r1, #9
    add r1, r1, r2
    outchar r1, r0

DBC_Fim:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; Desenha o HUD dinamico (cronometro com icone, pontuacao com trofeu e fase)
Desenhar_HUD:
    push r0
    push r1
    push r2
    push r3

    ; Icone de relogio na coluna 35 da linha 0
    loadn r0, #35
    loadn r1, #20
    loadn r2, #2816              ; relogio dourado
    add r1, r1, r2
    outchar r1, r0

    ; --- Cronometro (canto superior direito, colunas 36-39 da linha 0).
    ; Pisca a cor a cada segundo: impar = branco puro (#0), par = vermelho (#2304) ---
    load r0, tempo_seg
HUD_Tempo_Paridade:
    loadn r1, #2
    cmp r0, r1
    jgr HUD_Tempo_Sub
    jeq HUD_Tempo_Sub
    jmp HUD_Tempo_ParidadeFim
HUD_Tempo_Sub:
    sub r0, r0, r1
    jmp HUD_Tempo_Paridade
HUD_Tempo_ParidadeFim:
    loadn r1, #0
    cmp r0, r1
    jeq HUD_Tempo_Par
    loadn r2, #0                 ; impar = branco puro
    jmp HUD_Tempo_CorFeita
HUD_Tempo_Par:
    loadn r2, #2304              ; par = vermelho
HUD_Tempo_CorFeita:
    loadn r0, #36
    load r1, tempo_seg
    call Imprimir_Numero

    ; --- Pontuacao (canto inferior direito, icone trofeu em 1195 + 4 digitos 1196-1199) ---
    load r0, player_addr
    loadn r1, #1195
    cmp r0, r1
    jeq HUD_SemTrofeu
    loadn r0, #1195
    loadn r1, #19                ; trofeu
    loadn r2, #2816              ; dourado
    add r1, r1, r2
    outchar r1, r0
HUD_SemTrofeu:
    loadn r0, #1196
    load r1, pontuacao
    loadn r2, #0                 ; branco puro
    call Imprimir_Numero

    ; --- Indicador de fase "X/3" (canto inferior esquerdo, linha 29, colunas 0-2) ---
    loadn r0, #1160
    load r1, fase
    loadn r2, #'0'
    add r1, r1, r2
    loadn r2, #2816              ; amarelo ouro
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #'/'
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #'3'
    add r1, r1, r2
    outchar r1, r0

    pop r3
    pop r2
    pop r1
    pop r0
    rts

Desenhar_Cenario_Fixo:
    push r0
    push r1
    push r2
    push r3
    push r4

    ; 1. Horizonte tematico conforme a fase (linhas 0 e 1)
    load r3, fase
    loadn r2, #1
    cmp r3, r2
    jeq DCF_Horiz_Fase1
    loadn r2, #2
    cmp r3, r2
    jeq DCF_Horiz_Fase2
    jmp DCF_Horiz_Fase3

DCF_Horiz_Fase1:
    ; Fase 1 (USP / Cidade): predios coloridos com janelas acesas + estrelas no ceu
    loadn r0, #3
    loadn r1, #9
    loadn r2, #0
    loadn r3, #17                ; telhado
    loadn r4, #1024              ; azul marinho
    call Desenhar_Bloco_Predio

    loadn r0, #11
    loadn r1, #16
    loadn r2, #0
    loadn r3, #17
    loadn r4, #256               ; marrom tijolo
    call Desenhar_Bloco_Predio

    loadn r0, #23
    loadn r1, #28
    loadn r2, #0
    loadn r3, #17
    loadn r4, #1536              ; teal
    call Desenhar_Bloco_Predio

    loadn r0, #30
    loadn r1, #34
    loadn r2, #0
    loadn r3, #17
    loadn r4, #1024
    call Desenhar_Bloco_Predio

    ; Estrelas no ceu entre os predios (linha 0)
    loadn r1, #24
    loadn r2, #2816
    add r1, r1, r2
    loadn r0, #10
    outchar r1, r0
    loadn r0, #19
    outchar r1, r0
    loadn r0, #29
    outchar r1, r0

    ; Linha 1: corpo dos predios com janelas acesas (#16)
    loadn r0, #0
    loadn r1, #9
    loadn r2, #40
    loadn r3, #16
    loadn r4, #1024
    call Desenhar_Bloco_Predio

    loadn r0, #10
    loadn r1, #16
    loadn r2, #40
    loadn r3, #16
    loadn r4, #256
    call Desenhar_Bloco_Predio

    loadn r0, #23
    loadn r1, #29
    loadn r2, #40
    loadn r3, #16
    loadn r4, #1536
    call Desenhar_Bloco_Predio

    loadn r0, #30
    loadn r1, #40
    loadn r2, #40
    loadn r3, #16
    loadn r4, #1024
    call Desenhar_Bloco_Predio
    jmp DCF_Horiz_Fim

DCF_Horiz_Fase2:
    ; Fase 2 (ICMC): predios azuis/teal do instituto + arvores verdes do campus
    loadn r0, #4
    loadn r1, #11
    loadn r2, #0
    loadn r3, #16
    loadn r4, #1536              ; teal ICMC
    call Desenhar_Bloco_Predio

    loadn r0, #27
    loadn r1, #34
    loadn r2, #0
    loadn r3, #16
    loadn r4, #3072              ; azul ICMC
    call Desenhar_Bloco_Predio

    loadn r0, #4
    loadn r1, #11
    loadn r2, #40
    loadn r3, #16
    loadn r4, #1536
    call Desenhar_Bloco_Predio

    loadn r0, #27
    loadn r1, #34
    loadn r2, #40
    loadn r3, #16
    loadn r4, #3072
    call Desenhar_Bloco_Predio

    ; Arvores verdes nos cantos e junto ao portal do ICMC
    loadn r1, #14                ; arvore
    loadn r2, #2560              ; verde lima
    add r1, r1, r2
    loadn r0, #41
    outchar r1, r0
    loadn r0, #42
    outchar r1, r0
    loadn r0, #52
    outchar r1, r0
    loadn r0, #65
    outchar r1, r0
    loadn r0, #76
    outchar r1, r0
    loadn r0, #78
    outchar r1, r0
    jmp DCF_Horiz_Fim

DCF_Horiz_Fase3:
    ; Fase 3 (SIMOES): patio aberto arborizado do campus
    loadn r1, #14                ; arvore
    loadn r2, #2560              ; verde lima
    add r1, r1, r2
    loadn r0, #5
    outchar r1, r0
    loadn r0, #9
    outchar r1, r0
    loadn r0, #14
    outchar r1, r0
    loadn r0, #25
    outchar r1, r0
    loadn r0, #30
    outchar r1, r0
    loadn r0, #43
    outchar r1, r0
    loadn r0, #47
    outchar r1, r0
    loadn r0, #52
    outchar r1, r0
    loadn r0, #67
    outchar r1, r0
    loadn r0, #72
    outchar r1, r0
    loadn r0, #77
    outchar r1, r0

    ; Tufos de grama no patio (linha 1)
    loadn r1, #15
    loadn r2, #768               ; oliva
    add r1, r1, r2
    loadn r0, #45
    outchar r1, r0
    loadn r0, #50
    outchar r1, r0
    loadn r0, #69
    outchar r1, r0
    loadn r0, #75
    outchar r1, r0

DCF_Horiz_Fim:
    ; 2. Faixa quadriculada de chegada na linha 2 (enderecos 80..119) + Portal
    loadn r0, #80
    loadn r1, #40
    loadn r2, #12                ; bandeira quadriculada 4x4
    loadn r3, #1792              ; prata brilhante
    add r2, r2, r3
    call Desenhar_Linha_Horiz
    call Desenhar_Banner_Chegada

    ; 3. Meio-fio superior (linha 3, enderecos 120..159)
    loadn r0, #120
    loadn r1, #40
    loadn r2, #'='
    loadn r3, #1792              ; prata
    add r2, r2, r3
    call Desenhar_Linha_Horiz

    ; 4. Tracejados Divisorios das Ruas (prata nas faixas comuns, amarelo no eixo central!)
    loadn r0, #200
    loadn r3, #1792              ; linha 5: prata
    call Desenhar_Linha_Pontilhada

    loadn r0, #280
    loadn r3, #2816              ; linha 7: amarelo eixo central!
    call Desenhar_Linha_Pontilhada

    loadn r0, #360
    loadn r3, #1792              ; linha 9: prata
    call Desenhar_Linha_Pontilhada

    loadn r0, #520
    loadn r3, #2048              ; linha 13: borda do canteiro
    call Desenhar_Linha_Pontilhada

    loadn r0, #600
    loadn r3, #1792              ; linha 15: prata
    call Desenhar_Linha_Pontilhada

    loadn r0, #680
    loadn r3, #2816              ; linha 17: amarelo eixo central!
    call Desenhar_Linha_Pontilhada

    loadn r0, #760
    loadn r3, #1792              ; linha 19: prata
    call Desenhar_Linha_Pontilhada

    loadn r0, #840
    loadn r3, #2048              ; linha 21: fim da avenida
    call Desenhar_Linha_Pontilhada

    ; 5. Textura de asfalto (a cada 4 colunas) nas 8 pistas principais
    loadn r0, #160
    call Desenhar_Asfalto
    loadn r0, #240
    call Desenhar_Asfalto
    loadn r0, #320
    call Desenhar_Asfalto
    loadn r0, #400
    call Desenhar_Asfalto
    loadn r0, #560
    call Desenhar_Asfalto
    loadn r0, #640
    call Desenhar_Asfalto
    loadn r0, #720
    call Desenhar_Asfalto
    loadn r0, #800
    call Desenhar_Asfalto

    ; Se a 9a pista surpresa (linha 24) estiver ativa, desenha faixas de alerta!
    load r0, ob9_ativo
    loadn r1, #0
    cmp r0, r1
    jeq DCF_SemPista9
    loadn r0, #920               ; linha 23: alerta vermelho
    loadn r3, #2304
    call Desenhar_Linha_Pontilhada
    loadn r0, #960               ; linha 24: asfalto
    call Desenhar_Asfalto
    loadn r0, #1000              ; linha 25: alerta vermelho
    loadn r3, #2304
    call Desenhar_Linha_Pontilhada
DCF_SemPista9:

    ; 6. Canteiro central verde (linhas 11 e 12)
    loadn r0, #440
    loadn r1, #40
    loadn r2, #15                ; tufos de grama
    loadn r3, #2560              ; verde lima vivo!
    add r2, r2, r3
    call Desenhar_Linha_Horiz

    loadn r0, #480
    loadn r1, #40
    loadn r2, #'='
    loadn r3, #768               ; verde oliva!
    add r2, r2, r3
    call Desenhar_Linha_Horiz

    ; 7. Calcada inicial (linha 28 prata, linha 29 cinza)
    loadn r0, #1120
    loadn r1, #40
    loadn r2, #'='
    loadn r3, #1792
    add r2, r2, r3
    call Desenhar_Linha_Horiz

    loadn r0, #1160
    loadn r1, #40
    loadn r2, #'='
    loadn r3, #2048
    add r2, r2, r3
    call Desenhar_Linha_Horiz

    call Desenhar_Vidas
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; Auxiliar para desenhar blocos de predios/janelas no horizonte:
; r0 = col ini, r1 = col fim, r2 = offset linha (0 ou 40), r3 = glifo, r4 = cor
Desenhar_Bloco_Predio:
    push r0
    push r1
    push r2
    push r3
    push r4
    add r0, r0, r2
    add r1, r1, r2
    add r3, r3, r4
DBP_Loop:
    cmp r0, r1
    jeq DBP_Fim
    outchar r3, r0
    inc r0
    jmp DBP_Loop
DBP_Fim:
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; Desenha linha tracejada a cada 2 colunas (colunas pares).
; Entrada: r0 = endereco inicial da linha, r3 = cor
Desenhar_Linha_Pontilhada:
    push r0
    push r1
    push r2
    push r3
    loadn r1, #40
    add r1, r0, r1
    loadn r2, #'-'
    add r2, r2, r3
DLP_Loop:
    cmp r0, r1
    jgr DLP_Fim
    jeq DLP_Fim
    outchar r2, r0
    inc r0
    inc r0
    jmp DLP_Loop
DLP_Fim:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; Espalha o granulado de asfalto ('x') a cada 4 colunas (addr & 3 == 0),
; em perfeita sincronia com Apagar_Celula_Pista para nunca sumir!
Desenhar_Asfalto:
    push r0
    push r1
    push r2
    push r3
    loadn r1, #40
    add r1, r0, r1
    loadn r2, #'x'
    loadn r3, #2048
    add r2, r2, r3
DA_Loop:
    cmp r0, r1
    jgr DA_Fim
    jeq DA_Fim
    outchar r2, r0
    inc r0
    inc r0
    inc r0
    inc r0
    jmp DA_Loop
DA_Fim:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; Apaga uma celula de pista de veiculos (endereco em r1), preservando o
; granulado de asfalto ('x') nas colunas multiplas de 4!
Apagar_Celula_Pista:
    push r0
    push r2
    loadn r2, #3
    and r2, r1, r2
    loadn r0, #0
    cmp r2, r0
    jeq ACP_Fleck
    loadn r0, #' '
    outchar r0, r1
    jmp ACP_Fim
ACP_Fleck:
    loadn r0, #'x'
    loadn r2, #2048
    add r0, r0, r2
    outchar r0, r1
ACP_Fim:
    pop r2
    pop r0
    rts

; Descobre o fundo exato de uma celula da tela:
; Entrada: r1 = linha (0..29), r2 = endereco exato da celula (0..1199)
; Saida:   r0 = caractere + cor original daquela celula
Fundo_Da_Celula:
    push r1
    push r2
    push r3

    loadn r3, #29
    cmp r1, r3
    jeq FDC_Calcada29

    loadn r3, #28
    cmp r1, r3
    jeq FDC_Calcada28

    loadn r3, #3
    cmp r1, r3
    jeq FDC_Calcada28

    loadn r3, #2
    cmp r1, r3
    jeq FDC_Chegada

    loadn r3, #11
    cmp r1, r3
    jeq FDC_Grama11

    loadn r3, #12
    cmp r1, r3
    jeq FDC_Grama12

    ; Pistas de asfalto principais
    loadn r3, #4
    cmp r1, r3
    jeq FDC_Asfalto
    loadn r3, #6
    cmp r1, r3
    jeq FDC_Asfalto
    loadn r3, #8
    cmp r1, r3
    jeq FDC_Asfalto
    loadn r3, #10
    cmp r1, r3
    jeq FDC_Asfalto
    loadn r3, #14
    cmp r1, r3
    jeq FDC_Asfalto
    loadn r3, #16
    cmp r1, r3
    jeq FDC_Asfalto
    loadn r3, #18
    cmp r1, r3
    jeq FDC_Asfalto
    loadn r3, #20
    cmp r1, r3
    jeq FDC_Asfalto

    ; Tracejados prata (linhas 5, 9, 15, 19)
    loadn r3, #5
    cmp r1, r3
    jeq FDC_TracPrata
    loadn r3, #9
    cmp r1, r3
    jeq FDC_TracPrata
    loadn r3, #15
    cmp r1, r3
    jeq FDC_TracPrata
    loadn r3, #19
    cmp r1, r3
    jeq FDC_TracPrata

    ; Tracejados amarelos centrais (linhas 7, 17)
    loadn r3, #7
    cmp r1, r3
    jeq FDC_TracAmarelo
    loadn r3, #17
    cmp r1, r3
    jeq FDC_TracAmarelo

    ; Tracejados cinza de borda (linhas 13, 21)
    loadn r3, #13
    cmp r1, r3
    jeq FDC_TracCinza
    loadn r3, #21
    cmp r1, r3
    jeq FDC_TracCinza

    ; Regiao da pista 9 surpresa (linhas 23, 24, 25 quando ob9_ativo == 1)
    load r0, ob9_ativo
    loadn r3, #0
    cmp r0, r3
    jeq FDC_Vazio

    loadn r3, #24
    cmp r1, r3
    jeq FDC_Asfalto
    loadn r3, #23
    cmp r1, r3
    jeq FDC_TracAlerta
    loadn r3, #25
    cmp r1, r3
    jeq FDC_TracAlerta

FDC_Vazio:
    loadn r0, #' '
    jmp FDC_Fim

FDC_Calcada29:
    loadn r0, #'='
    loadn r3, #2048
    add r0, r0, r3
    jmp FDC_Fim

FDC_Calcada28:
    loadn r0, #'='
    loadn r3, #1792
    add r0, r0, r3
    jmp FDC_Fim

FDC_Chegada:
    loadn r0, #12
    loadn r3, #1792
    add r0, r0, r3
    jmp FDC_Fim

FDC_Grama11:
    loadn r0, #15
    loadn r3, #2560
    add r0, r0, r3
    jmp FDC_Fim

FDC_Grama12:
    loadn r0, #'='
    loadn r3, #768
    add r0, r0, r3
    jmp FDC_Fim

FDC_Asfalto:
    loadn r3, #3
    and r3, r2, r3
    loadn r0, #0
    cmp r3, r0
    jne FDC_Vazio
    loadn r0, #'x'
    loadn r3, #2048
    add r0, r0, r3
    jmp FDC_Fim

FDC_TracPrata:
    loadn r3, #1
    and r3, r2, r3
    loadn r0, #0
    cmp r3, r0
    jne FDC_Vazio
    loadn r0, #'-'
    loadn r3, #1792
    add r0, r0, r3
    jmp FDC_Fim

FDC_TracAmarelo:
    loadn r3, #1
    and r3, r2, r3
    loadn r0, #0
    cmp r3, r0
    jne FDC_Vazio
    loadn r0, #'-'
    loadn r3, #2816
    add r0, r0, r3
    jmp FDC_Fim

FDC_TracCinza:
    loadn r3, #1
    and r3, r2, r3
    loadn r0, #0
    cmp r3, r0
    jne FDC_Vazio
    loadn r0, #'-'
    loadn r3, #2048
    add r0, r0, r3
    jmp FDC_Fim

FDC_TracAlerta:
    loadn r3, #1
    and r3, r2, r3
    loadn r0, #0
    cmp r3, r0
    jne FDC_Vazio
    loadn r0, #'-'
    loadn r3, #2304
    add r0, r0, r3

FDC_Fim:
    pop r3
    pop r2
    pop r1
    rts

; ============================================================================
; LOGICA DO CHIP, PONTUACAO E NUMEROS
; ============================================================================

Sortear_Chip:
    push r0
    push r1
    push r2
    push r3

    ; indice da linha = rng_seed mod 8
    load r0, rng_seed
SC_Mod8:
    loadn r1, #8
    cmp r0, r1
    jgr SC_Mod8_Sub
    jeq SC_Mod8_Sub
    jmp SC_Mod8_Fim
SC_Mod8_Sub:
    sub r0, r0, r1
    jmp SC_Mod8
SC_Mod8_Fim:
    loadn r1, #0
    cmp r0, r1
    jeq SC_Linha0
    loadn r1, #1
    cmp r0, r1
    jeq SC_Linha1
    loadn r1, #2
    cmp r0, r1
    jeq SC_Linha2
    loadn r1, #3
    cmp r0, r1
    jeq SC_Linha3
    loadn r1, #4
    cmp r0, r1
    jeq SC_Linha4
    loadn r1, #5
    cmp r0, r1
    jeq SC_Linha5
    loadn r1, #6
    cmp r0, r1
    jeq SC_Linha6
    jmp SC_Linha7

SC_Linha0:
    load r2, chip_linha0
    jmp SC_Linha_Feito
SC_Linha1:
    load r2, chip_linha1
    jmp SC_Linha_Feito
SC_Linha2:
    load r2, chip_linha2
    jmp SC_Linha_Feito
SC_Linha3:
    load r2, chip_linha3
    jmp SC_Linha_Feito
SC_Linha4:
    load r2, chip_linha4
    jmp SC_Linha_Feito
SC_Linha5:
    load r2, chip_linha5
    jmp SC_Linha_Feito
SC_Linha6:
    load r2, chip_linha6
    jmp SC_Linha_Feito
SC_Linha7:
    load r2, chip_linha7

SC_Linha_Feito:
    store chip_py, r2

    ; coluna = (rng_seed mod 20) + 19  ->  intervalo 19-38
    load r0, rng_seed
SC_Mod20:
    loadn r1, #20
    cmp r0, r1
    jgr SC_Mod20_Sub
    jeq SC_Mod20_Sub
    jmp SC_Mod20_Fim
SC_Mod20_Sub:
    sub r0, r0, r1
    jmp SC_Mod20
SC_Mod20_Fim:
    loadn r1, #19
    add r0, r0, r1             ; r0 = coluna sorteada (19-38)

    ; endereco = linha*40 + coluna
    loadn r3, #0
SC_Mult_Loop:
    loadn r1, #0
    cmp r2, r1
    jeq SC_Mult_Fim
    loadn r1, #40
    add r3, r3, r1
    dec r2
    jmp SC_Mult_Loop
SC_Mult_Fim:
    add r3, r3, r0
    store chip_addr, r3
    loadn r0, #1
    store chip_ativo, r0

    pop r3
    pop r2
    pop r1
    pop r0
    rts

; Imprime um numero de 0 a 9999 como 4 digitos decimais (com zeros a esquerda).
; r0 = endereco inicial na tela, r1 = numero, r2 = cor
Imprimir_Numero:
    push r0
    push r1
    push r2
    push r3
    push r4

    loadn r3, #0
    loadn r4, #1000
IN_Milhares:
    cmp r1, r4
    jgr IN_Milhares_Sub
    jeq IN_Milhares_Sub
    jmp IN_Milhares_Fim
IN_Milhares_Sub:
    sub r1, r1, r4
    inc r3
    jmp IN_Milhares
IN_Milhares_Fim:
    loadn r4, #'0'
    add r4, r4, r3
    add r4, r4, r2
    outchar r4, r0
    inc r0

    loadn r3, #0
    loadn r4, #100
IN_Centenas:
    cmp r1, r4
    jgr IN_Centenas_Sub
    jeq IN_Centenas_Sub
    jmp IN_Centenas_Fim
IN_Centenas_Sub:
    sub r1, r1, r4
    inc r3
    jmp IN_Centenas
IN_Centenas_Fim:
    loadn r4, #'0'
    add r4, r4, r3
    add r4, r4, r2
    outchar r4, r0
    inc r0

    loadn r3, #0
    loadn r4, #10
IN_Dezenas:
    cmp r1, r4
    jgr IN_Dezenas_Sub
    jeq IN_Dezenas_Sub
    jmp IN_Dezenas_Fim
IN_Dezenas_Sub:
    sub r1, r1, r4
    inc r3
    jmp IN_Dezenas
IN_Dezenas_Fim:
    loadn r4, #'0'
    add r4, r4, r3
    add r4, r4, r2
    outchar r4, r0
    inc r0

    loadn r4, #'0'
    add r4, r4, r1
    add r4, r4, r2
    outchar r4, r0

    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; Soma r0 pontos a pontuacao (limite 9999) e atualiza o recorde da sessao
Somar_Pontos:
    push r0
    push r1
    push r2
    load r1, pontuacao
    add r1, r1, r0
    loadn r2, #9999
    cmp r1, r2
    jgr SP_Clamp
    jmp SP_Store
SP_Clamp:
    loadn r1, #9999
SP_Store:
    store pontuacao, r1
    call Atualizar_Recorde
    pop r2
    pop r1
    pop r0
    rts

Pontuar_Movimento:
    push r0
    push r1
    push r2

    load r0, reverso
    loadn r1, #0
    cmp r0, r1
    jeq PM_CimaEhFrente

    load r0, chip_encontrado
    loadn r1, #1
    cmp r0, r1
    jeq PM_CimaEhFrente

    loadn r1, #0
    cmp r3, r1
    jeq PM_Fim
    jmp PM_Ponto

PM_CimaEhFrente:
    loadn r1, #1
    cmp r3, r1
    jne PM_Fim

PM_Ponto:
    loadn r0, #10
    call Somar_Pontos

PM_Fim:
    pop r2
    pop r1
    pop r0
    rts

Multiplicar_E_Somar_Pontos:
    push r1
    push r2
    push r3
    loadn r3, #0
MSP_Loop:
    loadn r2, #0
    cmp r0, r2
    jeq MSP_Aplica
    add r3, r3, r1
    dec r0
    jmp MSP_Loop
MSP_Aplica:
    add r0, r3, r2
    pop r3
    pop r2
    pop r1
    call Somar_Pontos
    rts

; ============================================================================
; RENDERIZACAO DE ELEMENTOS DINAMICOS (OBSTACULOS, CHIP E JOGADOR)
; ============================================================================

Apagar_Dinamicos:
    push r0
    push r1
    push r2
    push r3

    ; Jogador: restaura perfeitamente o fundo da celula do corpo e da cabeca
    load r1, py
    load r2, player_addr
    call Fundo_Da_Celula
    outchar r0, r2

    load r1, py
    dec r1
    load r2, player_addr
    loadn r3, #40
    sub r2, r2, r3
    call Fundo_Da_Celula
    outchar r0, r2

    ; OB 1 (5 celulas)
    load r1, ob1_addr
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista

    ; OB 2 (3 celulas)
    load r1, ob2_addr
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista

    ; OB 3 (4 celulas)
    load r1, ob3_addr
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista

    ; OB 4 (3 celulas)
    load r1, ob4_addr
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista

    ; OB 5 (3 celulas)
    load r1, ob5_addr
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista

    ; OB 6 (5 celulas)
    load r1, ob6_addr
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista

    ; OB 7 (3 celulas)
    load r1, ob7_addr
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista

    ; OB 8 (4 celulas)
    load r1, ob8_addr
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista

    ; OB9 (pista extra)
    load r1, ob9_ativo
    loadn r2, #0
    cmp r1, r2
    jeq AD_Obs9_Fim
    load r1, ob9_addr
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista
    inc r1
    call Apagar_Celula_Pista
AD_Obs9_Fim:

    ; Chip colecionavel (modo reverso): restaura o fundo real da linha do chip!
    load r3, chip_ativo
    loadn r2, #0
    cmp r3, r2
    jeq AD_Chip_Fim

    load r1, chip_py
    load r2, chip_addr
    loadn r3, #19
    sub r2, r2, r3
    loadn r3, #0
AD_Chip_Label_Loop:
    push r1
    loadn r1, #20
    cmp r3, r1
    pop r1
    jeq AD_Chip_Fim
    call Fundo_Da_Celula
    outchar r0, r2
    inc r2
    inc r3
    jmp AD_Chip_Label_Loop

AD_Chip_Fim:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

Desenhar_Dinamicos:
    push r0
    push r1
    push r2
    push r3

    load r3, fase
    loadn r2, #1
    cmp r3, r2
    jeq DD_Obs_Fase1
    loadn r2, #2
    cmp r3, r2
    jeq DD_Obs_Fase2
    jmp DD_Obs_Fase3

DD_Obs_Fase1:
    ; OB1: Onibus Circular USP Amarelo Ouro (5 celulas com janelas #1 e #2)
    load r1, ob1_addr
    loadn r3, #2816              ; amarelo ouro!
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #1                 ; janela dupla
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #2                 ; janela panoramica
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #1
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1

    ; OB2: Carro Esportivo Vermelho (3 celulas)
    load r1, ob2_addr
    loadn r3, #2304
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'}'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1

    ; OB3: Onibus Urbano Aqua (4 celulas com janelas #1 e #2)
    load r1, ob3_addr
    loadn r3, #3584              ; aqua
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #1
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #2
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1

    ; OB4: Carro Azul Eletrico (3 celulas)
    load r1, ob4_addr
    loadn r3, #3072
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'}'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1

    ; OB5: Carro Fuchsia Neon (3 celulas)
    load r1, ob5_addr
    loadn r3, #3328              ; rosa/fuchsia
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'}'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1

    ; OB6: Onibus Prata Articulado (5 celulas com janelas)
    load r1, ob6_addr
    loadn r3, #1792              ; prata
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #1
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #2
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #1
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1

    ; OB7: Carro Verde Lima (3 celulas)
    load r1, ob7_addr
    loadn r3, #2560
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'}'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1

    ; OB8: Van Vermelha (4 celulas com janelas #1 e #2)
    load r1, ob8_addr
    loadn r3, #2304
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #1
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #2
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1
    jmp DD_Obs_Fim

DD_Obs_Fase2:
    ; OB1: Onibus Circular do Campus (Amarelo)
    load r1, ob1_addr
    loadn r3, #2816
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #1
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #2
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #1
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1

    ; OB2: Moto Vermelha
    load r1, ob2_addr
    loadn r3, #2304
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'q'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1

    ; OB3: Van do ICMC Prata
    load r1, ob3_addr
    loadn r3, #1792
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #1
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #2
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1

    ; OB4: Moto Fuchsia
    load r1, ob4_addr
    loadn r3, #3328
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'q'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1

    ; OB5: Carro Azul
    load r1, ob5_addr
    loadn r3, #3072
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'}'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1

    ; OB6: Grupo de alunos atravessando (Aqua)
    load r1, ob6_addr
    loadn r3, #3584
    loadn r2, #'m'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'n'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'m'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'n'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'m'
    add r0, r2, r3
    outchar r0, r1

    ; OB7: Carro Verde Lima
    load r1, ob7_addr
    loadn r3, #2560
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'}'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1

    ; OB8: Van Vermelha
    load r1, ob8_addr
    loadn r3, #2304
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #1
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #2
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1
    jmp DD_Obs_Fim

DD_Obs_Fase3:
    ; OB1: Alunos apressados (Amarelo)
    load r1, ob1_addr
    loadn r3, #2816
    loadn r2, #'m'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'n'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'p'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'n'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'m'
    add r0, r2, r3
    outchar r0, r1

    ; OB2: Alunos com cadeira (Vermelho)
    load r1, ob2_addr
    loadn r3, #2304
    loadn r2, #'m'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'p'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'m'
    add r0, r2, r3
    outchar r0, r1

    ; OB3: Grupo correndo (Aqua)
    load r1, ob3_addr
    loadn r3, #3584
    loadn r2, #'n'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'n'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'n'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'n'
    add r0, r2, r3
    outchar r0, r1

    ; OB4: Alunos com cadeira (Fuchsia)
    load r1, ob4_addr
    loadn r3, #3328
    loadn r2, #'p'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'m'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'p'
    add r0, r2, r3
    outchar r0, r1

    ; OB5: Alunos (Prata)
    load r1, ob5_addr
    loadn r3, #1792
    loadn r2, #'m'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'m'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'n'
    add r0, r2, r3
    outchar r0, r1

    ; OB6: Grupo grande correndo (Verde Lima)
    load r1, ob6_addr
    loadn r3, #2560
    loadn r2, #'n'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'m'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'n'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'m'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'n'
    add r0, r2, r3
    outchar r0, r1

    ; OB7: Alunos (Amarelo)
    load r1, ob7_addr
    loadn r3, #2816
    loadn r2, #'m'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'n'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'m'
    add r0, r2, r3
    outchar r0, r1

    ; OB8: Alunos com cadeira/correndo (Vermelho)
    load r1, ob8_addr
    loadn r3, #2304
    loadn r2, #'p'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'n'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'p'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'n'
    add r0, r2, r3
    outchar r0, r1

DD_Obs_Fim:

    ; OB9 (pista extra em direcao aleatoria) - carro de alerta Fuchsia!
    load r3, ob9_ativo
    loadn r2, #0
    cmp r3, r2
    jeq DD_Obs9_Fim
    load r1, ob9_addr
    loadn r3, #3328
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'}'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1
DD_Obs9_Fim:

    ; Chip colecionavel (modo reverso) - brilha em Dourado (#2816)!
    load r3, chip_ativo
    loadn r2, #0
    cmp r3, r2
    jeq DD_Chip_Fim

    load r1, chip_addr
    loadn r3, #2816
    loadn r2, #'k'
    add r0, r2, r3
    outchar r0, r1

    load r2, player_frame
    loadn r3, #1
    cmp r2, r3
    jne DD_Chip_Fim

    load r1, chip_addr
    loadn r2, #19
    sub r0, r1, r2
    loadn r1, #msg_chip_label
    loadn r2, #2816
    call Imprimestr

DD_Chip_Fim:

    ; ---- JOGADOR (Calca Branca #0 + Camisa/Mochila Aqua #3584) ----
    load r1, player_addr
    load r2, player_frame
    loadn r3, #0
    cmp r2, r3
    jeq DD_Jog_Frame0
    loadn r2, #'y'          ; quadro 1: perna direita esticada
    jmp DD_Jog_Frame_Fim
DD_Jog_Frame0:
    loadn r2, #'w'          ; quadro 0: perna esquerda esticada
DD_Jog_Frame_Fim:
    loadn r3, #0            ; branco puro (#0) para contraste maximo!
    add r0, r2, r3
    outchar r0, r1

    loadn r3, #40
    sub r1, r1, r3
    load r2, player_frame
    loadn r3, #0
    cmp r2, r3
    jeq DD_Jog_Torso_Frame0
    loadn r2, #'j'          ; quadro 1: braco esquerdo esticado
    jmp DD_Jog_Torso_Fim
DD_Jog_Torso_Frame0:
    loadn r2, #'@'          ; quadro 0: braco direito esticado
DD_Jog_Torso_Fim:
    loadn r3, #3584         ; aqua vibrante (#3584)!
    add r0, r2, r3
    outchar r0, r1

    pop r3
    pop r2
    pop r1
    pop r0
    rts

Alternar_Frame_Jogador:
    push r0
    push r1
    load r0, player_frame
    loadn r1, #0
    cmp r0, r1
    jeq AFJ_Set1
    loadn r0, #0
    jmp AFJ_Store
AFJ_Set1:
    loadn r0, #1
AFJ_Store:
    store player_frame, r0
    pop r1
    pop r0
    rts

; ============================================================================
; CONTROLES E MOVIMENTACAO
; ============================================================================

Ler_Teclado:
    push r0
    push r1
    push r2
    push r3

    inchar r0
    loadn r1, #255
    cmp r0, r1
    jeq LT_Sair

    loadn r1, #'w'
    cmp r0, r1
    jeq LT_Cima
    loadn r1, #'W'
    cmp r0, r1
    jeq LT_Cima

    loadn r1, #'s'
    cmp r0, r1
    jeq LT_Baixo
    loadn r1, #'S'
    cmp r0, r1
    jeq LT_Baixo

    loadn r1, #'a'
    cmp r0, r1
    jeq LT_Esquerda
    loadn r1, #'A'
    cmp r0, r1
    jeq LT_Esquerda

    loadn r1, #'d'
    cmp r0, r1
    jeq LT_Direita
    loadn r1, #'D'
    cmp r0, r1
    jeq LT_Direita
    jmp LT_Sair

LT_Cima:
    load r1, py
    loadn r2, #2
    cmp r1, r2
    jeq LT_Sair
    dec r1
    store py, r1
    load r2, player_addr
    loadn r3, #40
    sub r2, r2, r3
    store player_addr, r2
    call Alternar_Frame_Jogador

    loadn r3, #1
    call Pontuar_Movimento
    load r1, py
    loadn r2, #11
    cmp r1, r2
    jne LT_Cima_SemMeio
    loadn r0, #20
    call Somar_Pontos
LT_Cima_SemMeio:
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
    call Alternar_Frame_Jogador

    loadn r3, #0
    call Pontuar_Movimento
    load r1, py
    loadn r2, #11
    cmp r1, r2
    jne LT_Baixo_SemMeio
    loadn r0, #20
    call Somar_Pontos
LT_Baixo_SemMeio:
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
    call Alternar_Frame_Jogador
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
    call Alternar_Frame_Jogador

LT_Sair:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

Mover_Obstaculos:
    push r0
    push r1

    load r0, rng_seed
    inc r0
    loadn r1, #1000
    cmp r0, r1
    jgr RNG_Reset
    jeq RNG_Reset
    jmp RNG_Store
RNG_Reset:
    loadn r0, #0
RNG_Store:
    store rng_seed, r0

    load r0, ob1_addr
    inc r0
    load r1, ob1_fim
    cmp r0, r1
    jgr MO_1_Reset
    jmp MO_1_Store
MO_1_Reset:
    load r0, ob1_ini
MO_1_Store:
    store ob1_addr, r0

    load r0, ob2_addr
    inc r0
    load r1, ob2_fim
    cmp r0, r1
    jgr MO_2_Reset
    jmp MO_2_Store
MO_2_Reset:
    load r0, ob2_ini
MO_2_Store:
    store ob2_addr, r0

    load r0, ob3_addr
    inc r0
    load r1, ob3_fim
    cmp r0, r1
    jgr MO_3_Reset
    jmp MO_3_Store
MO_3_Reset:
    load r0, ob3_ini
MO_3_Store:
    store ob3_addr, r0

    load r0, ob4_addr
    inc r0
    load r1, ob4_fim
    cmp r0, r1
    jgr MO_4_Reset
    jmp MO_4_Store
MO_4_Reset:
    load r0, ob4_ini
MO_4_Store:
    store ob4_addr, r0

    load r0, ob5_addr
    inc r0
    load r1, ob5_fim
    cmp r0, r1
    jgr MO_5_Reset
    jmp MO_5_Store
MO_5_Reset:
    load r0, ob5_ini
MO_5_Store:
    store ob5_addr, r0

    load r0, ob6_addr
    inc r0
    load r1, ob6_fim
    cmp r0, r1
    jgr MO_6_Reset
    jmp MO_6_Store
MO_6_Reset:
    load r0, ob6_ini
MO_6_Store:
    store ob6_addr, r0

    load r0, ob7_addr
    inc r0
    load r1, ob7_fim
    cmp r0, r1
    jgr MO_7_Reset
    jmp MO_7_Store
MO_7_Reset:
    load r0, ob7_ini
MO_7_Store:
    store ob7_addr, r0

    load r0, ob8_addr
    inc r0
    load r1, ob8_fim
    cmp r0, r1
    jgr MO_8_Reset
    jmp MO_8_Store
MO_8_Reset:
    load r0, ob8_ini
MO_8_Store:
    store ob8_addr, r0

    load r0, ob9_ativo
    loadn r1, #0
    cmp r0, r1
    jeq MO_9_Fim

    load r1, ob9_dir
    loadn r0, #0
    cmp r1, r0
    jeq MO_9_Direita

    load r0, ob9_addr
    dec r0
    load r1, ob9_ini
    cmp r0, r1
    jgr MO_9_Store
    jeq MO_9_Store
    load r0, ob9_fim
    jmp MO_9_Store

MO_9_Direita:
    load r0, ob9_addr
    inc r0
    load r1, ob9_fim
    cmp r0, r1
    jgr MO_9_Reset
    jmp MO_9_Store
MO_9_Reset:
    load r0, ob9_ini
MO_9_Store:
    store ob9_addr, r0
MO_9_Fim:

    pop r1
    pop r0
    rts

; ============================================================================
; COLISAO, CRONOMETRO E CONDICOES DE VITORIA
; ============================================================================

Testar_Chip:
    push r0
    push r1
    push r2
    push r3
    push r4

    load r0, chip_ativo
    loadn r1, #0
    cmp r0, r1
    jeq TCP_Fim

    load r0, player_addr
    load r1, chip_addr
    cmp r0, r1
    jne TCP_Fim

    loadn r0, #0
    store chip_ativo, r0

    loadn r0, #1
    store chip_encontrado, r0
    loadn r0, #3
    store fase, r0

    ; Popup Arcade estilizado anunciando que achou o chip!
    loadn r0, #9
    loadn r1, #3
    loadn r2, #18
    loadn r3, #36
    loadn r4, #2816              ; moldura dourada
    call Desenhar_Caixa_Dupla

    loadn r0, #459
    loadn r1, #'k'
    loadn r2, #3584              ; icone chip aqua
    add r1, r1, r2
    outchar r1, r0

    loadn r0, #526
    loadn r1, #msg_chip_achado1
    loadn r2, #2816
    call Imprimestr

    loadn r0, #606
    loadn r1, #msg_chip_achado2
    loadn r2, #0
    call Imprimestr

    call Atraso_Jogo
    call Atraso_Jogo
    call Atraso_Jogo

    call Apagar_Tela
    call Desenhar_Cenario_Fixo
    call Desenhar_Dinamicos
    call Desenhar_HUD

TCP_Fim:
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

Atualizar_Cronometro:
    push r0
    push r1

    load r0, tempo_frames
    inc r0
    loadn r1, #20
    cmp r0, r1
    jgr AC_NovoSegundo
    jeq AC_NovoSegundo
    store tempo_frames, r0
    jmp AC_Fim

AC_NovoSegundo:
    loadn r0, #0
    store tempo_frames, r0

    load r0, tempo_seg
    loadn r1, #0
    cmp r0, r1
    jeq AC_Fim
    dec r0
    store tempo_seg, r0

AC_Fim:
    pop r1
    pop r0
    rts

Testar_Tempo:
    push r0
    push r1

    load r0, tempo_seg
    loadn r1, #0
    cmp r0, r1
    jne TT_Fim

    loadn r0, #60
    store tempo_seg, r0

    load r0, vidas
    dec r0
    store vidas, r0

    loadn r1, #0
    cmp r0, r1
    jeq TC_GameOver

    call Piscar_Jogador

    loadn r0, #20
    store px, r0
    loadn r0, #29
    store py, r0
    loadn r0, #1180
    store player_addr, r0
    loadn r0, #0
    store player_frame, r0

    call Desenhar_Vidas
    call Desenhar_Dinamicos

TT_Fim:
    pop r1
    pop r0
    rts

Testar_Colisao:
    push r0
    push r1

    load r0, player_addr

    ; OB 1
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

    ; OB 2
    load r1, ob2_addr
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu

    ; OB 3
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

    ; OB 4
    load r1, ob4_addr
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu

    ; OB 5
    load r1, ob5_addr
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu

    ; OB 6
    load r1, ob6_addr
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

    ; OB 7
    load r1, ob7_addr
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu

    ; OB 8
    load r1, ob8_addr
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

    ; OB9 (pista extra)
    load r1, ob9_ativo
    push r2
    loadn r2, #0
    cmp r1, r2
    pop r2
    jeq TC_Obs9_Fim
    load r1, ob9_addr
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu
    inc r1
    cmp r0, r1
    jeq TC_Bateu
TC_Obs9_Fim:

    pop r1
    pop r0
    rts

TC_Bateu:
    load r0, vidas
    dec r0
    store vidas, r0

    loadn r1, #0
    cmp r0, r1
    jeq TC_GameOver

    call Piscar_Jogador

    loadn r0, #20
    store px, r0
    loadn r0, #29
    store py, r0
    loadn r0, #1180
    store player_addr, r0
    loadn r0, #0
    store player_frame, r0

    call Desenhar_Vidas
    call Desenhar_Dinamicos

    pop r1
    pop r0
    rts

TC_GameOver:
    call Atualizar_Recorde
    call Apagar_Tela

    ; Moldura Arcade de Game Over (linhas 7..21, cols 4..35)
    loadn r0, #7
    loadn r1, #4
    loadn r2, #21
    loadn r3, #35
    loadn r4, #2304              ; vermelho intenso
    call Desenhar_Caixa_Dupla

    ; Icones de caveira (#31) no topo do card
    loadn r0, #378
    loadn r1, #31
    loadn r2, #2816
    add r1, r1, r2
    outchar r1, r0
    loadn r0, #381
    outchar r1, r0

    loadn r0, #448
    loadn r1, #msg_derrota
    loadn r2, #2304
    call Imprimestr

    loadn r0, #527
    loadn r1, #msg_derrota_sub
    loadn r2, #1792
    call Imprimestr

    loadn r0, #649
    loadn r1, #msg_pts_finais
    loadn r2, #2816
    call Imprimestr
    loadn r0, #665
    load r1, pontuacao
    loadn r2, #0
    call Imprimir_Numero

    loadn r0, #729
    loadn r1, #msg_rec_atual
    loadn r2, #3584
    call Imprimestr
    loadn r0, #745
    load r1, recorde
    loadn r2, #0
    call Imprimir_Numero

    call Atraso_Jogo
    call Atraso_Jogo
    call Atraso_Jogo
    call Atraso_Jogo

    ; Descarta o contexto de Testar_Colisao / Testar_Tempo (2 regs + 1 ret = 3 pops)
    pop r0
    pop r1
    pop r2

    loadn r0, #1
    store fase, r0
    loadn r0, #15
    store atraso_var, r0
    loadn r0, #3
    store vidas, r0
    loadn r0, #0
    store ob9_ativo, r0
    loadn r0, #0
    store fases_vencidas, r0
    loadn r0, #0
    store reverso, r0
    loadn r0, #0
    store chip_ativo, r0
    loadn r0, #0
    store chip_encontrado, r0
    loadn r0, #0
    store pontuacao, r0
    loadn r0, #60
    store tempo_seg, r0
    loadn r0, #0
    store tempo_frames, r0

    jmp LOBBY

Piscar_Jogador:
    push r0
    push r1
    push r2
    push r3
    loadn r3, #6
PJ_Loop:
    load r1, py
    load r2, player_addr
    call Fundo_Da_Celula
    outchar r0, r2

    load r1, py
    dec r1
    load r2, player_addr
    push r3
    loadn r3, #40
    sub r2, r2, r3
    pop r3
    call Fundo_Da_Celula
    outchar r0, r2
    call Atraso_Jogo

    load r1, player_addr
    load r2, player_frame
    loadn r0, #0
    cmp r2, r0
    jeq PJ_Frame0
    loadn r0, #'y'
    jmp PJ_Frame_Fim
PJ_Frame0:
    loadn r0, #'w'
PJ_Frame_Fim:
    loadn r2, #2304              ; pisca em vermelho ao levar dano!
    add r0, r0, r2
    outchar r0, r1

    load r2, player_frame
    loadn r0, #0
    cmp r2, r0
    jeq PJ_TorsoFrame0
    loadn r2, #'j'
    jmp PJ_TorsoFrame_Fim
PJ_TorsoFrame0:
    loadn r2, #'@'
PJ_TorsoFrame_Fim:
    loadn r0, #2304
    add r2, r2, r0
    load r1, player_addr
    loadn r0, #40
    sub r1, r1, r0
    outchar r2, r1
    call Atraso_Jogo

    dec r3
    jnz PJ_Loop

    ; Limpa o sprite vermelho final no local do impacto antes de reposicionar
    load r1, py
    load r2, player_addr
    call Fundo_Da_Celula
    outchar r0, r2

    load r1, py
    dec r1
    load r2, player_addr
    loadn r3, #40
    sub r2, r2, r3
    call Fundo_Da_Celula
    outchar r0, r2

    pop r3
    pop r2
    pop r1
    pop r0
    rts

; Card rapido de Fase Concluida
Mostrar_Card_Fase_Concluida:
    push r0
    push r1
    push r2
    push r3
    push r4

    loadn r0, #10
    loadn r1, #4
    loadn r2, #17
    loadn r3, #35
    loadn r4, #2560              ; verde lima
    call Desenhar_Caixa_Dupla

    loadn r0, #489
    loadn r1, #msg_vitoria
    loadn r2, #2816              ; dourado
    call Imprimestr

    loadn r0, #568
    loadn r1, #msg_vitoria_sub
    loadn r2, #0
    call Imprimestr

    call Atraso_Jogo
    call Atraso_Jogo
    call Atraso_Jogo

    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

Testar_Vitoria:
    push r0
    push r1
    push r2

    load r2, reverso
    loadn r1, #0
    cmp r2, r1
    jeq TV_Modo_Normal

    ; ========================================================================
    ; MODO REVERSO
    ; ========================================================================
    load r2, chip_encontrado
    loadn r1, #1
    cmp r2, r1
    jeq TV_Reverso_ComChip

    load r0, py
    loadn r1, #29
    cmp r0, r1
    jne TV_Fim

    loadn r0, #50
    call Somar_Pontos
    call Mostrar_Card_Fase_Concluida

    load r0, fase
    loadn r1, #1
    cmp r0, r1
    jeq TV_Reverso_Completo

    load r0, fases_vencidas
    inc r0
    store fases_vencidas, r0

    pop r2
    pop r1
    pop r0
    pop r3
    jmp TELA_CHECKIN

TV_Reverso_Completo:
    pop r2
    pop r1
    pop r0
    pop r3
    jmp TELA_REVERSO_FIM

TV_Reverso_ComChip:
    load r0, py
    loadn r1, #2
    cmp r0, r1
    jne TV_Fim

    load r0, tempo_seg
    loadn r1, #10
    call Multiplicar_E_Somar_Pontos

    load r0, vidas
    dec r0
    loadn r1, #50
    call Multiplicar_E_Somar_Pontos

    pop r2
    pop r1
    pop r0
    pop r3
    jmp TELA_REVERSO_FIM

    ; ========================================================================
    ; MODO NORMAL
    ; ========================================================================
TV_Modo_Normal:
    load r0, py
    loadn r1, #2
    cmp r0, r1
    jne TV_Fim

    loadn r0, #50
    call Somar_Pontos
    call Mostrar_Card_Fase_Concluida

    load r0, fase
    loadn r1, #3
    cmp r0, r1
    jeq TV_Ir_Final

    load r0, fases_vencidas
    inc r0
    store fases_vencidas, r0

    pop r2
    pop r1
    pop r0
    pop r3
    jmp TELA_CHECKIN

TV_Ir_Final:
    load r0, tempo_seg
    loadn r1, #10
    call Multiplicar_E_Somar_Pontos

    load r0, vidas
    dec r0
    loadn r1, #50
    call Multiplicar_E_Somar_Pontos

    pop r2
    pop r1
    pop r0
    pop r3
    jmp TELA_VITORIA_FINAL

TV_Fim:
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; TELA DE CHECK-IN - aparece ao vencer a fase 1 ou a fase 2
; ============================================================================
TELA_CHECKIN:
    call Apagar_Tela

    ; Moldura dupla principal (y=4..25, x=3..36)
    loadn r0, #4
    loadn r1, #3
    loadn r2, #25
    loadn r3, #36
    loadn r4, #3584              ; aqua
    call Desenhar_Caixa_Dupla

    ; Trofeus e titulo
    loadn r0, #250
    loadn r1, #19
    loadn r2, #2816
    add r1, r1, r2
    outchar r1, r0
    loadn r0, #269
    outchar r1, r0

    loadn r0, #252
    loadn r1, #msg_ck_titulo
    loadn r2, #2816
    call Imprimestr

    ; Divisoria
    loadn r0, #285
    loadn r1, #30
    loadn r2, #29
    loadn r3, #1536
    add r2, r2, r3
    call Desenhar_Linha_Horiz

    ; Pontuacao atual
    loadn r0, #368
    loadn r1, #msg_ck_pts
    loadn r2, #1792
    call Imprimestr
    loadn r0, #386
    load r1, pontuacao
    loadn r2, #0
    call Imprimir_Numero

    ; Pergunta
    loadn r0, #487
    loadn r1, #msg_ck_pergunta
    loadn r2, #0
    call Imprimestr

    ; Botao (C) Continuar
    loadn r0, #14
    loadn r1, #5
    loadn r2, #30
    loadn r3, #2560              ; verde lima
    call Desenhar_Botao
    loadn r0, #607
    loadn r1, #msg_ck_btn_c
    loadn r2, #0
    call Imprimestr

    ; Botao (M) Morcegar
    loadn r0, #19
    loadn r1, #5
    loadn r2, #30
    loadn r3, #2816              ; amarelo ouro
    call Desenhar_Botao
    loadn r0, #807
    loadn r1, #msg_ck_btn_m
    loadn r2, #0
    call Imprimestr

TCK_Espera:
    inchar r0
    loadn r1, #255
    cmp r0, r1
    jeq TCK_Espera
    loadn r1, #'c'
    cmp r0, r1
    jeq TCK_Continuar
    loadn r1, #'C'
    cmp r0, r1
    jeq TCK_Continuar
    loadn r1, #'m'
    cmp r0, r1
    jeq TCK_Morcegar
    loadn r1, #'M'
    cmp r0, r1
    jeq TCK_Morcegar
    jmp TCK_Espera

TCK_Continuar:
    load r0, atraso_var
    loadn r1, #3
    cmp r0, r1
    jeq TCK_SemReduzir
    dec r0
    store atraso_var, r0
TCK_SemReduzir:

    load r0, reverso
    loadn r1, #0
    cmp r0, r1
    jeq TCK_Avanca

    load r0, fase
    dec r0
    store fase, r0
    jmp TCK_Fase_Feito

TCK_Avanca:
    load r0, fase
    inc r0
    store fase, r0

TCK_Fase_Feito:
    load r0, fase
    loadn r1, #1
    cmp r0, r1
    jeq TCK_Obs9_Desativa

    loadn r0, #1
    store ob9_ativo, r0

    load r2, rng_seed
TCK_Obs9_Paridade:
    loadn r1, #2
    cmp r2, r1
    jgr TCK_Obs9_Sub
    jeq TCK_Obs9_Sub
    jmp TCK_Obs9_ParidadeFim
TCK_Obs9_Sub:
    sub r2, r2, r1
    jmp TCK_Obs9_Paridade
TCK_Obs9_ParidadeFim:
    store ob9_dir, r2

    loadn r1, #0
    cmp r2, r1
    jeq TCK_Obs9_Direita
    load r0, ob9_fim
    store ob9_addr, r0
    jmp TCK_Obs9_Fim
TCK_Obs9_Direita:
    load r0, ob9_ini
    store ob9_addr, r0
    jmp TCK_Obs9_Fim

TCK_Obs9_Desativa:
    loadn r0, #0
    store ob9_ativo, r0

TCK_Obs9_Fim:
    load r0, reverso
    loadn r1, #0
    cmp r0, r1
    jeq TCK_Reinicio_Normal

    loadn r0, #20
    store px, r0
    loadn r0, #2
    store py, r0
    loadn r0, #100
    store player_addr, r0
    loadn r0, #0
    store player_frame, r0
    jmp TCK_Reinicio_Feito

TCK_Reinicio_Normal:
    loadn r0, #20
    store px, r0
    loadn r0, #29
    store py, r0
    loadn r0, #1180
    store player_addr, r0
    loadn r0, #0
    store player_frame, r0

TCK_Reinicio_Feito:
    call Apagar_Tela
    call Desenhar_Cenario_Fixo
    call Desenhar_Dinamicos
    call Desenhar_HUD

    jmp LOOP_PRINCIPAL

TCK_Morcegar:
    loadn r0, #1
    store fase, r0
    loadn r0, #15
    store atraso_var, r0
    loadn r0, #3
    store vidas, r0
    loadn r0, #0
    store ob9_ativo, r0
    loadn r0, #0
    store reverso, r0
    loadn r0, #0
    store chip_ativo, r0
    loadn r0, #0
    store chip_encontrado, r0
    loadn r0, #0
    store pontuacao, r0
    loadn r0, #60
    store tempo_seg, r0
    loadn r0, #0
    store tempo_frames, r0

    jmp LOBBY

; ============================================================================
; TELA DE VITORIA FINAL (FASE 3) - O SIMOES PERCEBEU A FALTA DO CHIP!
; ============================================================================
TELA_VITORIA_FINAL:
    call Apagar_Tela

    ; Moldura dupla vermelha de alerta (y=2..27, x=2..37)
    loadn r0, #2
    loadn r1, #2
    loadn r2, #27
    loadn r3, #37
    loadn r4, #2304
    call Desenhar_Caixa_Dupla

    loadn r0, #167
    loadn r1, #msg_puto_tit
    loadn r2, #2816
    call Imprimestr

    loadn r0, #285
    loadn r1, #msg_puto1
    loadn r2, #2304
    call Imprimestr
    loadn r0, #324
    loadn r1, #msg_puto2
    loadn r2, #2304
    call Imprimestr
    loadn r0, #405
    loadn r1, #msg_puto3
    loadn r2, #0
    call Imprimestr

    ; Carinha de bravo do Simoes ('v') + icone do chip ('k')
    loadn r0, #498
    loadn r1, #'v'
    loadn r2, #2304
    add r1, r1, r2
    outchar r1, r0

    loadn r0, #501
    loadn r1, #'k'
    loadn r2, #2816
    add r1, r1, r2
    outchar r1, r0

    ; Botao (S) Buscar o Chip
    loadn r0, #15
    loadn r1, #5
    loadn r2, #30
    loadn r3, #2560
    call Desenhar_Botao
    loadn r0, #647
    loadn r1, #msg_opcao_s
    loadn r2, #0
    call Imprimestr

    ; Botao (N) Ignorar (aceita N, I ou ESC #27)
    loadn r0, #20
    loadn r1, #5
    loadn r2, #30
    loadn r3, #1792
    call Desenhar_Botao
    loadn r0, #848
    loadn r1, #msg_opcao_esc
    loadn r2, #1792
    call Imprimestr

TVF_Espera:
    inchar r0
    loadn r1, #255
    cmp r0, r1
    jeq TVF_Espera
    loadn r1, #'s'
    cmp r0, r1
    jeq TVF_Volta
    loadn r1, #'S'
    cmp r0, r1
    jeq TVF_Volta
    loadn r1, #'n'
    cmp r0, r1
    jeq TVF_Ignora
    loadn r1, #'N'
    cmp r0, r1
    jeq TVF_Ignora
    loadn r1, #'i'
    cmp r0, r1
    jeq TVF_Ignora
    loadn r1, #'I'
    cmp r0, r1
    jeq TVF_Ignora
    loadn r1, #27
    cmp r0, r1
    jeq TVF_Ignora
    jmp TVF_Espera

TVF_Volta:
    loadn r0, #1
    store reverso, r0
    loadn r0, #0
    store chip_encontrado, r0
    loadn r0, #3
    store fase, r0
    loadn r0, #15
    store atraso_var, r0
    loadn r0, #3
    store vidas, r0

    loadn r0, #1
    store ob9_ativo, r0
    load r2, rng_seed
TVF_Obs9_Paridade:
    loadn r1, #2
    cmp r2, r1
    jgr TVF_Obs9_Sub
    jeq TVF_Obs9_Sub
    jmp TVF_Obs9_ParidadeFim
TVF_Obs9_Sub:
    sub r2, r2, r1
    jmp TVF_Obs9_Paridade
TVF_Obs9_ParidadeFim:
    store ob9_dir, r2
    loadn r1, #0
    cmp r2, r1
    jeq TVF_Obs9_Direita
    load r0, ob9_fim
    store ob9_addr, r0
    jmp TVF_Obs9_Fim
TVF_Obs9_Direita:
    load r0, ob9_ini
    store ob9_addr, r0
TVF_Obs9_Fim:

    call Sortear_Chip

    loadn r0, #180
    store tempo_seg, r0
    loadn r0, #0
    store tempo_frames, r0

    loadn r0, #20
    store px, r0
    loadn r0, #2
    store py, r0
    loadn r0, #100
    store player_addr, r0
    loadn r0, #0
    store player_frame, r0

    jmp INICIO

TVF_Ignora:
    loadn r0, #1
    store fase, r0
    loadn r0, #15
    store atraso_var, r0
    loadn r0, #3
    store vidas, r0
    loadn r0, #0
    store ob9_ativo, r0
    loadn r0, #0
    store fases_vencidas, r0
    loadn r0, #0
    store reverso, r0
    loadn r0, #0
    store chip_ativo, r0
    loadn r0, #0
    store chip_encontrado, r0
    loadn r0, #0
    store pontuacao, r0
    loadn r0, #60
    store tempo_seg, r0
    loadn r0, #0
    store tempo_frames, r0

    jmp LOBBY

; ============================================================================
; TELA DE FIM DO MODO REVERSO - O SIMOES ESTA EM PAZ!
; ============================================================================
TELA_REVERSO_FIM:
    call Atualizar_Recorde
    call Apagar_Tela

    ; Moldura dourada de grande conquista (y=3..26, x=2..37)
    loadn r0, #3
    loadn r1, #2
    loadn r2, #26
    loadn r3, #37
    loadn r4, #2816
    call Desenhar_Caixa_Dupla

    ; Trofeus e estrelas
    loadn r0, #205
    loadn r1, #19
    loadn r2, #2816
    add r1, r1, r2
    outchar r1, r0
    loadn r0, #233
    outchar r1, r0

    loadn r0, #207
    loadn r1, #msg_rev_tit
    loadn r2, #2816
    call Imprimestr

    ; Rosto feliz do Simoes (#23) + chip ('k')
    loadn r0, #338
    loadn r1, #23
    loadn r2, #2560
    add r1, r1, r2
    outchar r1, r0

    loadn r0, #341
    loadn r1, #'k'
    loadn r2, #3584
    add r1, r1, r2
    outchar r1, r0

    loadn r0, #403
    loadn r1, #msg_reverso_fim
    loadn r2, #2560
    call Imprimestr

    loadn r0, #484
    loadn r1, #msg_rev_sub
    loadn r2, #0
    call Imprimestr

    loadn r0, #609
    loadn r1, #msg_pts_finais
    loadn r2, #2816
    call Imprimestr
    loadn r0, #625
    load r1, pontuacao
    loadn r2, #0
    call Imprimir_Numero

    loadn r0, #689
    loadn r1, #msg_rec_atual
    loadn r2, #3584
    call Imprimestr
    loadn r0, #705
    load r1, recorde
    loadn r2, #0
    call Imprimir_Numero

    loadn r0, #886
    loadn r1, #msg_fim_enter
    loadn r2, #2816
    call Imprimestr

TRF_Espera:
    call Aguardar_Ou_Ler_Menu
    loadn r1, #255
    cmp r0, r1
    jeq TRF_Espera

    loadn r0, #1
    store fase, r0
    loadn r0, #15
    store atraso_var, r0
    loadn r0, #3
    store vidas, r0
    loadn r0, #0
    store ob9_ativo, r0
    loadn r0, #0
    store fases_vencidas, r0
    loadn r0, #0
    store reverso, r0
    loadn r0, #0
    store chip_ativo, r0
    loadn r0, #0
    store chip_encontrado, r0
    loadn r0, #0
    store pontuacao, r0
    loadn r0, #60
    store tempo_seg, r0
    loadn r0, #0
    store tempo_frames, r0

    jmp LOBBY

; ============================================================================
; TELA INICIAL ESTILO ARCADE (LOBBY) - JOGAR / COMO JOGAR / CREDITOS
; ============================================================================
LOBBY:
    call Apagar_Tela

    ; 1. Gabinete Arcade externo em Teal (#1536)
    loadn r0, #0
    loadn r1, #0
    loadn r2, #29
    loadn r3, #39
    loadn r4, #1536
    call Desenhar_Caixa_Dupla

    ; Subtitulo institucional no topo (linha 1)
    loadn r0, #49
    loadn r1, #msg_cabecalho_inst
    loadn r2, #1792
    call Imprimestr

    ; 2. Marquee Duplo Dourado do Titulo (y=2..5, x=3..36)
    loadn r0, #2
    loadn r1, #3
    loadn r2, #5
    loadn r3, #36
    loadn r4, #2816
    call Desenhar_Caixa_Dupla

    loadn r0, #126
    loadn r1, #msg_titulo_p1
    loadn r2, #0                 ; branco puro
    call Imprimestr
    loadn r0, #144
    loadn r1, #msg_titulo_p2
    loadn r2, #2816              ; amarelo ouro
    call Imprimestr

    ; Microchips decorativos + subtitulo na linha 4
    loadn r0, #167
    loadn r1, #'k'
    loadn r2, #2560
    add r1, r1, r2
    outchar r1, r0
    loadn r0, #192
    outchar r1, r0

    loadn r0, #170
    loadn r1, #msg_subtitulo
    loadn r2, #3584              ; aqua
    call Imprimestr

    ; 3. Barra de Status Arcade (linha 6): Recorde + Fases/Vidas
    loadn r0, #243
    loadn r1, #19                ; trofeu
    loadn r2, #2816
    add r1, r1, r2
    outchar r1, r0

    loadn r0, #245
    loadn r1, #msg_recorde_lbl
    loadn r2, #2816
    call Imprimestr

    loadn r0, #254
    load r1, recorde
    loadn r2, #0
    call Imprimir_Numero

    load r3, fases_vencidas
    loadn r2, #0
    cmp r3, r2
    jeq LOBBY_MostrarVidas

    loadn r0, #264
    loadn r1, #msg_fases_lbl
    loadn r2, #2560
    call Imprimestr
    load r0, fases_vencidas
    loadn r1, #'0'
    add r0, r0, r1
    loadn r1, #0
    add r0, r0, r1
    loadn r1, #271
    outchar r0, r1
    inc r1
    loadn r0, #'/'
    outchar r0, r1
    inc r1
    loadn r0, #'3'
    outchar r0, r1
    jmp LOBBY_MiniPista

LOBBY_MostrarVidas:
    loadn r0, #265
    loadn r1, #msg_vidas_lbl
    loadn r2, #1792
    call Imprimestr
    loadn r0, #'h'
    loadn r1, #2304
    add r0, r0, r1
    loadn r1, #272
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1

LOBBY_MiniPista:
    ; 4. Mini-avenida decorativa animada dentro do gabinete (linhas 8..10, cols 2..37)
    loadn r0, #322
    loadn r1, #358
    loadn r2, #'-'
    loadn r3, #2048
    add r2, r2, r3
LMP_Top:
    cmp r0, r1
    jgr LMP_Top_Fim
    jeq LMP_Top_Fim
    outchar r2, r0
    inc r0
    inc r0
    jmp LMP_Top
LMP_Top_Fim:
    loadn r0, #402
    loadn r1, #438
LMP_Bot:
    cmp r0, r1
    jgr LMP_Bot_Fim
    jeq LMP_Bot_Fim
    outchar r2, r0
    inc r0
    inc r0
    jmp LMP_Bot
LMP_Bot_Fim:

    ; Rodape fixo de dicas (linha 27)
    loadn r0, #1087
    loadn r1, #msg_lobby_dica
    loadn r2, #2048
    call Imprimestr

    call Desenhar_Botoes_Lobby

LOBBY_Loop:
    call Animar_Lobby
    call Aguardar_Ou_Ler_Menu

    loadn r1, #255
    cmp r0, r1
    jeq LOBBY_Loop

    ; Navegacao pra cima (W/w)
    loadn r1, #'w'
    cmp r0, r1
    jeq LOBBY_Sobe
    loadn r1, #'W'
    cmp r0, r1
    jeq LOBBY_Sobe

    ; Navegacao pra baixo (S/s)
    loadn r1, #'s'
    cmp r0, r1
    jeq LOBBY_Desce
    loadn r1, #'S'
    cmp r0, r1
    jeq LOBBY_Desce

    ; Confirmar opcao selecionada (ENTER #13 ou ESPACO #32)
    loadn r1, #13
    cmp r0, r1
    jeq LOBBY_Confirmar
    loadn r1, #' '
    cmp r0, r1
    jeq LOBBY_Confirmar

    ; Atalhos diretos 1, 2, 3
    loadn r1, #'1'
    cmp r0, r1
    jeq LOBBY_Atalho1
    loadn r1, #'2'
    cmp r0, r1
    jeq LOBBY_Atalho2
    loadn r1, #'3'
    cmp r0, r1
    jeq LOBBY_Atalho3

    jmp LOBBY_Loop

LOBBY_Sobe:
    load r0, menu_sel
    loadn r1, #0
    cmp r0, r1
    jeq LOBBY_Sobe_Wrap
    dec r0
    jmp LOBBY_MudouSel
LOBBY_Sobe_Wrap:
    loadn r0, #2
    jmp LOBBY_MudouSel

LOBBY_Desce:
    load r0, menu_sel
    loadn r1, #2
    cmp r0, r1
    jeq LOBBY_Desce_Wrap
    inc r0
    jmp LOBBY_MudouSel
LOBBY_Desce_Wrap:
    loadn r0, #0

LOBBY_MudouSel:
    store menu_sel, r0
    call Desenhar_Botoes_Lobby
    jmp LOBBY_Loop

LOBBY_Atalho1:
    loadn r0, #0
    store menu_sel, r0
    jmp LOBBY_Iniciar_Partida
LOBBY_Atalho2:
    loadn r0, #1
    store menu_sel, r0
    jmp TELA_COMO_JOGAR
LOBBY_Atalho3:
    loadn r0, #2
    store menu_sel, r0
    jmp TELA_CREDITOS

LOBBY_Confirmar:
    load r0, menu_sel
    loadn r1, #0
    cmp r0, r1
    jeq LOBBY_Iniciar_Partida
    loadn r1, #1
    cmp r0, r1
    jeq TELA_COMO_JOGAR
    jmp TELA_CREDITOS

LOBBY_Iniciar_Partida:
    loadn r0, #1
    store fase, r0
    loadn r0, #15
    store atraso_var, r0
    loadn r0, #3
    store vidas, r0
    loadn r0, #0
    store ob9_ativo, r0
    loadn r0, #0
    store reverso, r0
    loadn r0, #0
    store chip_ativo, r0
    loadn r0, #0
    store chip_encontrado, r0
    loadn r0, #0
    store pontuacao, r0
    loadn r0, #60
    store tempo_seg, r0
    loadn r0, #0
    store tempo_frames, r0
    loadn r0, #20
    store px, r0
    loadn r0, #29
    store py, r0
    loadn r0, #1180
    store player_addr, r0
    loadn r0, #0
    store player_frame, r0

    jmp INICIO

; Desenha os 3 botoes interativos do Lobby destacando o selecionado (menu_sel)
Desenhar_Botoes_Lobby:
    push r0
    push r1
    push r2
    push r3
    push r4

    ; Limpa colunas laterais onde ficam as setas seletoras (? e ?)
    loadn r1, #' '
    loadn r0, #527
    outchar r1, r0
    loadn r0, #528
    outchar r1, r0
    loadn r0, #551
    outchar r1, r0
    loadn r0, #552
    outchar r1, r0

    loadn r0, #687
    outchar r1, r0
    loadn r0, #688
    outchar r1, r0
    loadn r0, #711
    outchar r1, r0
    loadn r0, #712
    outchar r1, r0

    loadn r0, #847
    outchar r1, r0
    loadn r0, #848
    outchar r1, r0
    loadn r0, #871
    outchar r1, r0
    loadn r0, #872
    outchar r1, r0

    load r4, menu_sel

    ; --- Botao 0: JOGAR (y=12, x=10, larg=20) ---
    loadn r1, #0
    cmp r4, r1
    jeq DBL_B0_Ativo
    loadn r0, #12
    loadn r1, #10
    loadn r2, #20
    loadn r3, #1536
    call Desenhar_Botao
    loadn r0, #537
    loadn r1, #msg_btn_jogar
    loadn r2, #1792
    call Imprimestr
    jmp DBL_B1
DBL_B0_Ativo:
    loadn r0, #12
    loadn r1, #10
    loadn r2, #20
    loadn r3, #2816              ; borda dourada
    call Desenhar_Botao
    loadn r0, #537
    loadn r1, #msg_btn_jogar
    loadn r2, #0                 ; texto branco brilhante
    call Imprimestr

DBL_B1:
    ; --- Botao 1: COMO JOGAR (y=16, x=10, larg=20) ---
    loadn r1, #1
    cmp r4, r1
    jeq DBL_B1_Ativo
    loadn r0, #16
    loadn r1, #10
    loadn r2, #20
    loadn r3, #1536
    call Desenhar_Botao
    loadn r0, #695
    loadn r1, #msg_btn_comojogar
    loadn r2, #1792
    call Imprimestr
    jmp DBL_B2
DBL_B1_Ativo:
    loadn r0, #16
    loadn r1, #10
    loadn r2, #20
    loadn r3, #2816
    call Desenhar_Botao
    loadn r0, #695
    loadn r1, #msg_btn_comojogar
    loadn r2, #0
    call Imprimestr

DBL_B2:
    ; --- Botao 2: CREDITOS (y=20, x=10, larg=20) ---
    loadn r1, #2
    cmp r4, r1
    jeq DBL_B2_Ativo
    loadn r0, #20
    loadn r1, #10
    loadn r2, #20
    loadn r3, #1536
    call Desenhar_Botao
    loadn r0, #856
    loadn r1, #msg_btn_creditos
    loadn r2, #1792
    call Imprimestr
    jmp DBL_Fim
DBL_B2_Ativo:
    loadn r0, #20
    loadn r1, #10
    loadn r2, #20
    loadn r3, #2816
    call Desenhar_Botao
    loadn r0, #856
    loadn r1, #msg_btn_creditos
    loadn r2, #0
    call Imprimestr

DBL_Fim:
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; Atualiza a animacao viva do Lobby (estrelas piscando, setas pulsando e
; veiculos trafegando na mini-avenida da linha 9)
Animar_Lobby:
    push r0
    push r1
    push r2
    push r3

    ; Alterna menu_anim (0 <-> 1)
    load r0, menu_anim
    loadn r1, #0
    cmp r0, r1
    jeq AL_Set1
    loadn r0, #0
    jmp AL_SaveAnim
AL_Set1:
    loadn r0, #1
AL_SaveAnim:
    store menu_anim, r0

    ; 1. Estrelas nos 4 cantos do gabinete + prompt inferior
    loadn r1, #0
    cmp r0, r1
    jeq AL_Cores0
    loadn r2, #2816              ; estrelas ouro
    loadn r3, #2560              ; prompt lima
    jmp AL_DesenhaLuzes
AL_Cores0:
    loadn r2, #3584              ; estrelas aqua
    loadn r3, #2816              ; prompt ouro
AL_DesenhaLuzes:
    loadn r1, #24
    add r1, r1, r2
    loadn r0, #42
    outchar r1, r0
    loadn r0, #77
    outchar r1, r0
    loadn r0, #1122
    outchar r1, r0
    loadn r0, #1157
    outchar r1, r0

    loadn r0, #1009
    loadn r1, #msg_lobby_enter
    mov r2, r3
    call Imprimestr

    ; 2. Setas ? e ? pulsando ao lado do botao selecionado
    load r0, menu_sel
    loadn r1, #0
    cmp r0, r1
    jeq AL_SetaB0
    loadn r1, #1
    cmp r0, r1
    jeq AL_SetaB1
    loadn r2, #847               ; base esq botao 2
    loadn r3, #871               ; base dir botao 2
    jmp AL_DesenhaSeta
AL_SetaB0:
    loadn r2, #527
    loadn r3, #551
    jmp AL_DesenhaSeta
AL_SetaB1:
    loadn r2, #687
    loadn r3, #711

AL_DesenhaSeta:
    loadn r1, #' '
    outchar r1, r2
    inc r2
    outchar r1, r2
    dec r2
    outchar r1, r3
    inc r3
    outchar r1, r3
    dec r3

    load r0, menu_anim
    loadn r1, #1
    cmp r0, r1
    jeq AL_SetaPerto
    inc r3
    jmp AL_PlotSeta
AL_SetaPerto:
    inc r2
AL_PlotSeta:
    loadn r0, #21                ; ?
    loadn r1, #2816
    add r0, r0, r1
    outchar r0, r2
    loadn r0, #22                ; ?
    add r0, r0, r1
    outchar r0, r3

    ; 3. Mini-avenida animada na linha 9 (cols 2..37 = enderecos 362..397)
    loadn r0, #362
    loadn r1, #36
    loadn r2, #' '
    call Desenhar_Linha_Horiz

    ; Move onibus amarelo (larg 4, cols 2..34)
    load r0, menu_car1
    inc r0
    loadn r1, #34
    cmp r0, r1
    jgr AL_ResetCar1
    jmp AL_SaveCar1
AL_ResetCar1:
    loadn r0, #2
AL_SaveCar1:
    store menu_car1, r0

    loadn r1, #360
    add r1, r1, r0
    loadn r3, #2816
    loadn r2, #'['
    add r2, r2, r3
    outchar r2, r1
    inc r1
    loadn r2, #1
    add r2, r2, r3
    outchar r2, r1
    inc r1
    loadn r2, #2
    add r2, r2, r3
    outchar r2, r1
    inc r1
    loadn r2, #']'
    add r2, r2, r3
    outchar r2, r1

    ; Move carro esportivo vermelho (larg 3, cols 2..35)
    load r0, menu_car2
    inc r0
    loadn r1, #35
    cmp r0, r1
    jgr AL_ResetCar2
    jmp AL_SaveCar2
AL_ResetCar2:
    loadn r0, #2
AL_SaveCar2:
    store menu_car2, r0

    loadn r1, #360
    add r1, r1, r0
    loadn r3, #2304
    loadn r2, #'['
    add r2, r2, r3
    outchar r2, r1
    inc r1
    loadn r2, #'}'
    add r2, r2, r3
    outchar r2, r1
    inc r1
    loadn r2, #']'
    add r2, r2, r3
    outchar r2, r1

    pop r3
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; TELA COMO JOGAR (ACESSADA PELO MENU INICIAL)
; ============================================================================
TELA_COMO_JOGAR:
    call Apagar_Tela

    loadn r0, #0
    loadn r1, #0
    loadn r2, #29
    loadn r3, #39
    loadn r4, #3584              ; moldura aqua
    call Desenhar_Caixa_Dupla

    ; Titulo com estrelas
    loadn r1, #24
    loadn r2, #2816
    add r1, r1, r2
    loadn r0, #92
    outchar r1, r0
    loadn r0, #107
    outchar r1, r0

    loadn r0, #95
    loadn r1, #msg_cj_titulo
    loadn r2, #2816
    call Imprimestr

    loadn r0, #123
    loadn r1, #34
    loadn r2, #29
    loadn r3, #1536
    add r2, r2, r3
    call Desenhar_Linha_Horiz

    ; Secao Controles + preview do bonequinho do aluno
    loadn r0, #163
    loadn r1, #msg_cj_ctrl
    loadn r2, #2560
    call Imprimestr

    loadn r0, #195
    loadn r1, #'@'
    loadn r2, #3584
    add r1, r1, r2
    outchar r1, r0
    loadn r0, #235
    loadn r1, #'w'
    outchar r1, r0

    loadn r0, #204
    loadn r1, #msg_cj_wasd
    loadn r2, #0
    call Imprimestr
    loadn r0, #244
    loadn r1, #msg_cj_cm
    loadn r2, #1792
    call Imprimestr
    loadn r0, #284
    loadn r1, #msg_cj_sn
    loadn r2, #1792
    call Imprimestr

    ; Secao Fases com mini-sprites demonstrativos
    loadn r0, #363
    loadn r1, #msg_cj_fases
    loadn r2, #2560
    call Imprimestr

    loadn r0, #404
    loadn r1, #msg_cj_f1
    loadn r2, #2816
    call Imprimestr
    loadn r0, #415
    loadn r3, #2304
    loadn r1, #'['
    add r1, r1, r3
    outchar r1, r0
    inc r0
    loadn r1, #'}'
    add r1, r1, r3
    outchar r1, r0
    inc r0
    loadn r1, #']'
    add r1, r1, r3
    outchar r1, r0
    loadn r0, #419
    loadn r1, #msg_cj_f1d
    loadn r2, #0
    call Imprimestr

    loadn r0, #444
    loadn r1, #msg_cj_f2
    loadn r2, #3584
    call Imprimestr
    loadn r0, #456
    loadn r1, #'q'
    loadn r2, #3328
    add r1, r1, r2
    outchar r1, r0
    loadn r0, #459
    loadn r1, #msg_cj_f2d
    loadn r2, #0
    call Imprimestr

    loadn r0, #484
    loadn r1, #msg_cj_f3
    loadn r2, #2560
    call Imprimestr
    loadn r0, #495
    loadn r3, #2816
    loadn r1, #'m'
    add r1, r1, r3
    outchar r1, r0
    inc r0
    loadn r1, #'n'
    add r1, r1, r3
    outchar r1, r0
    inc r0
    loadn r1, #'p'
    add r1, r1, r3
    outchar r1, r0
    loadn r0, #499
    loadn r1, #msg_cj_f3d
    loadn r2, #0
    call Imprimestr

    ; Secao Regras e Pontos
    loadn r0, #563
    loadn r1, #msg_cj_regras
    loadn r2, #2560
    call Imprimestr

    loadn r0, #604
    loadn r1, #'h'
    loadn r2, #2304
    add r1, r1, r2
    outchar r1, r0
    loadn r0, #606
    loadn r1, #msg_cj_vidas
    loadn r2, #0
    call Imprimestr

    loadn r0, #616
    loadn r1, #20                ; relogio
    loadn r2, #2816
    add r1, r1, r2
    outchar r1, r0
    loadn r0, #618
    loadn r1, #msg_cj_tempo
    loadn r2, #0
    call Imprimestr

    loadn r0, #644
    loadn r1, #msg_cj_pts1
    loadn r2, #1792
    call Imprimestr
    loadn r0, #684
    loadn r1, #msg_cj_pts2
    loadn r2, #2816
    call Imprimestr

    ; Secao Modo Reverso
    loadn r0, #763
    loadn r1, #'k'
    loadn r2, #2816
    add r1, r1, r2
    outchar r1, r0
    loadn r0, #765
    loadn r1, #msg_cj_rev
    loadn r2, #3584
    call Imprimestr
    loadn r0, #804
    loadn r1, #msg_cj_rev1
    loadn r2, #0
    call Imprimestr
    loadn r0, #844
    loadn r1, #msg_cj_rev2
    loadn r2, #0
    call Imprimestr

    ; Botao Voltar (y=25..27, x=9, larg=22)
    loadn r0, #25
    loadn r1, #9
    loadn r2, #22
    loadn r3, #2816
    call Desenhar_Botao

    loadn r0, #1047
    loadn r1, #21                ; ?
    loadn r2, #2816
    add r1, r1, r2
    outchar r1, r0
    loadn r0, #1072
    loadn r1, #22                ; ?
    add r1, r1, r2
    outchar r1, r0

    loadn r0, #1053
    loadn r1, #msg_btn_voltar
    loadn r2, #0
    call Imprimestr

TCJ_Espera:
    call Aguardar_Ou_Ler_Menu
    loadn r1, #255
    cmp r0, r1
    jeq TCJ_Espera
    loadn r1, #13
    cmp r0, r1
    jeq LOBBY
    loadn r1, #' '
    cmp r0, r1
    jeq LOBBY
    loadn r1, #'v'
    cmp r0, r1
    jeq LOBBY
    loadn r1, #'V'
    cmp r0, r1
    jeq LOBBY
    loadn r1, #'b'
    cmp r0, r1
    jeq LOBBY
    loadn r1, #'B'
    cmp r0, r1
    jeq LOBBY
    jmp TCJ_Espera

; ============================================================================
; TELA DE CREDITOS (ACESSADA PELO MENU INICIAL)
; ============================================================================
TELA_CREDITOS:
    call Apagar_Tela

    loadn r0, #0
    loadn r1, #0
    loadn r2, #29
    loadn r3, #39
    loadn r4, #2816              ; moldura dourada
    call Desenhar_Caixa_Dupla

    ; Trofeus no cabecalho
    loadn r1, #19
    loadn r2, #2816
    add r1, r1, r2
    loadn r0, #90
    outchar r1, r0
    loadn r0, #109
    outchar r1, r0

    loadn r0, #92
    loadn r1, #msg_cr_titulo
    loadn r2, #2816
    call Imprimestr

    loadn r0, #123
    loadn r1, #34
    loadn r2, #29
    loadn r3, #1536
    add r2, r2, r3
    call Desenhar_Linha_Horiz

    loadn r0, #211
    loadn r1, #msg_cr_equipe
    loadn r2, #3584
    call Imprimestr

    ; 5 Autores com estrelas decorativas
    loadn r1, #24
    loadn r2, #2816
    add r1, r1, r2
    loadn r0, #291
    outchar r1, r0
    loadn r0, #451
    outchar r1, r0
    loadn r0, #611
    outchar r1, r0

    loadn r1, #24
    loadn r2, #3584
    add r1, r1, r2
    loadn r0, #371
    outchar r1, r0
    loadn r0, #531
    outchar r1, r0

    loadn r0, #293
    loadn r1, #msg_cr_dev1
    loadn r2, #0
    call Imprimestr

    loadn r0, #373
    loadn r1, #msg_cr_dev2
    loadn r2, #0
    call Imprimestr

    loadn r0, #453
    loadn r1, #msg_cr_dev3
    loadn r2, #0
    call Imprimestr

    loadn r0, #533
    loadn r1, #msg_cr_dev4
    loadn r2, #0
    call Imprimestr

    loadn r0, #613
    loadn r1, #msg_cr_dev5
    loadn r2, #0
    call Imprimestr

    ; Divisoria Homenagem
    loadn r0, #685
    loadn r1, #30
    loadn r2, #29
    loadn r3, #1536
    add r2, r2, r3
    call Desenhar_Linha_Horiz

    loadn r0, #728
    loadn r1, #msg_cr_hom
    loadn r2, #2560
    call Imprimestr

    loadn r0, #805
    loadn r1, #msg_cr_prof
    loadn r2, #2816
    call Imprimestr

    loadn r0, #844
    loadn r1, #msg_cr_usp
    loadn r2, #1792
    call Imprimestr

    ; Desfile de icones do jogo na linha 23
    loadn r0, #936
    loadn r1, #'h'
    loadn r2, #2304
    add r1, r1, r2
    outchar r1, r0

    loadn r0, #938
    loadn r1, #'@'
    loadn r2, #3584
    add r1, r1, r2
    outchar r1, r0

    loadn r0, #940
    loadn r1, #'k'
    loadn r2, #2816
    add r1, r1, r2
    outchar r1, r0

    loadn r0, #942
    loadn r1, #23                ; Simoes feliz!
    loadn r2, #2560
    add r1, r1, r2
    outchar r1, r0

    loadn r0, #944
    loadn r1, #19                ; trofeu
    loadn r2, #2816
    add r1, r1, r2
    outchar r1, r0

    ; Botao Voltar (y=25..27, x=9, larg=22)
    loadn r0, #25
    loadn r1, #9
    loadn r2, #22
    loadn r3, #2816
    call Desenhar_Botao

    loadn r0, #1047
    loadn r1, #21
    loadn r2, #2816
    add r1, r1, r2
    outchar r1, r0
    loadn r0, #1072
    loadn r1, #22
    add r1, r1, r2
    outchar r1, r0

    loadn r0, #1053
    loadn r1, #msg_btn_voltar
    loadn r2, #0
    call Imprimestr

TCR_Espera:
    call Aguardar_Ou_Ler_Menu
    loadn r1, #255
    cmp r0, r1
    jeq TCR_Espera
    loadn r1, #13
    cmp r0, r1
    jeq LOBBY
    loadn r1, #' '
    cmp r0, r1
    jeq LOBBY
    loadn r1, #'v'
    cmp r0, r1
    jeq LOBBY
    loadn r1, #'V'
    cmp r0, r1
    jeq LOBBY
    loadn r1, #'b'
    cmp r0, r1
    jeq LOBBY
    loadn r1, #'B'
    cmp r0, r1
    jeq LOBBY
    jmp TCR_Espera

; ============================================================================
; ROTINAS UTILITARIAS DE ATRASO E IMPRESSAO DE STRINGS
; ============================================================================

Atraso_Jogo:
    push r0
    push r1

    load r1, atraso_var
AJ_Fora:
    loadn r0, #10000
AJ_Dentro:
    dec r0
    jnz AJ_Dentro

    dec r1
    jnz AJ_Fora

    pop r1
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
