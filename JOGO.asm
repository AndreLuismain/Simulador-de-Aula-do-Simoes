; ============================================================================
; TRAVESSIA USP - VERSAO DEFINITIVA CORRIGIDA
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

; ---- Modo reverso ("caça ao chip do Simoes") ----
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
; acumula voltas do loop principal ate completar "1 segundo" (nao ha
; relogio de hardware nesta CPU, entao 1 segundo e aproximado por uma
; quantidade fixa de iteracoes do loop principal)
tempo_seg : var #1
static tempo_seg + #0, #60
tempo_frames : var #1
static tempo_frames + #0, #0

; 8 linhas "interessantes" onde o chip pode aparecer - pontas do mapa,
; passeios e linha de chegada, cobrindo pistas de carro, grama e
; calcada, como pedido ("passeios, linha de chegada ou pontas"). Sao 8
; variaveis separadas (em vez de um array) porque so vi variaveis de
; celula unica funcionando de fato neste codigo - nao quero arriscar um
; "var #8" indexado que nunca foi testado neste projeto
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

; LIMITES CORRIGIDOS: 
; Se a linha começa em X e termina em X+39, e o obstáculo tem tamanho T,
; O limite direito (Fim) = (X+39) - (T-1)

; ---- Obstaculo 8: Onibus Branco "oSCo" (Linha 20, larg 4) ----
ob8_addr : var #1
static ob8_addr + #0, #800     
ob8_ini : var #1
static ob8_ini + #0, #800      
ob8_fim : var #1
static ob8_fim + #0, #836      

; ---- Obstaculo 7: Carro Vermelho "o}o" (Linha 18, larg 3) ----
ob7_addr : var #1
static ob7_addr + #0, #725     
ob7_ini : var #1
static ob7_ini + #0, #720      
ob7_fim : var #1
static ob7_fim + #0, #757      

; ---- Obstaculo 6: Onibus Amarelo "o}}}o" (Linha 16, larg 5) ----
ob6_addr : var #1
static ob6_addr + #0, #640     
ob6_ini : var #1
static ob6_ini + #0, #640      
ob6_fim : var #1
static ob6_fim + #0, #675      

; ---- Obstaculo 5: Carro Cinza "o}o" (Linha 14, larg 3) ----
ob5_addr : var #1
static ob5_addr + #0, #570     
ob5_ini : var #1
static ob5_ini + #0, #560      
ob5_fim : var #1
static ob5_fim + #0, #597      

; ---- Obstaculo 4: Carro Azul "o}o" (Linha 10, larg 3) ----
ob4_addr : var #1
static ob4_addr + #0, #415     
ob4_ini : var #1
static ob4_ini + #0, #400      
ob4_fim : var #1
static ob4_fim + #0, #437      

; ---- Obstaculo 3: Onibus Branco "oSCo" (Linha 8, larg 4) ----
ob3_addr : var #1
static ob3_addr + #0, #325     
ob3_ini : var #1
static ob3_ini + #0, #320      
ob3_fim : var #1
static ob3_fim + #0, #356      

; ---- Obstaculo 2: Carro Vermelho "o}o" (Linha 6, larg 3) ----
ob2_addr : var #1
static ob2_addr + #0, #245     
ob2_ini : var #1
static ob2_ini + #0, #240      
ob2_fim : var #1
static ob2_fim + #0, #277      

; ---- Obstaculo 1: Onibus Amarelo "o}}}o" (Linha 4, larg 5) ----
ob1_addr : var #1
static ob1_addr + #0, #176     
ob1_ini : var #1
static ob1_ini + #0, #160      
ob1_fim : var #1
static ob1_fim + #0, #195      

msg_vitoria : string " CHEGOU NA USP! AGORA FORMAR! \0"
msg_derrota : string " ATROPELADO! FIM DE JOGO! \0"

; ---- Novas telas: lobby, check-in e vitoria final ----
msg_titulo : string " SIMULADOR DE AULA DO SIMOES \0"
msg_progresso : string " FASES VENCIDAS: \0"
msg_checkin : string " CONTINUAR (C) OU MORCEGAR (M)? \0"

; Tela de vitoria da fase 3, com a escolha de entrar no modo reverso
msg_puto1 : string " VOCE CHEGOU NA AULA, POREM O SIMOES \0"
msg_puto2 : string " ESTA PUTO PORQUE PERDERAM O CHIP. \0"
msg_puto3 : string " VOLTE O CAMINHO PROCURANDO! \0"
msg_opcao_s : string " APERTE S PARA VOLTAR \0"
msg_opcao_esc : string " APERTE ESC PARA IGNORAR \0"

; Chip colecionavel (modo reverso) e mensagens de conclusao
msg_chip_label : string " CHIP DO SIMOES -> \0"
msg_chip_achado1 : string " VOCE ACHOU O CHIP! \0"
msg_chip_achado2 : string " VOLTE A AULA E ENTREGUE AO SIMOES \0"
msg_reverso_fim : string " VOCE VOLTOU! O SIMOES ESTA EM PAZ. \0"

; ============================================================================
; PROGRAMA PRINCIPAL
; ============================================================================
INICIO:
    call Apagar_Tela            
    call Desenhar_Cenario_Fixo  
    call Desenhar_Dinamicos     

LOOP_PRINCIPAL:
    call Apagar_Dinamicos       
    call Ler_Teclado            
    call Mover_Obstaculos       
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
; SUBROTINAS DO JOGO
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

; Desenha os 3 coracoes de vida no canto superior esquerdo (enderecos 0,1,2),
; mostrando um coracao para cada vida restante e espaco em branco para
; cada vida perdida
Desenhar_Vidas:
    push r0
    push r1
    push r2
    push r3

    loadn r2, #'h'
    loadn r3, #2304
    add r2, r2, r3          ; r2 = coracao colorido

    load r3, vidas

    ; slot 0 (endereco 0) - aparece se vidas >= 1
    loadn r0, #0
    loadn r1, #1
    cmp r3, r1
    jgr DV_S0_Cheio
    jeq DV_S0_Cheio
    loadn r1, #' '
    outchar r1, r0
    jmp DV_S1
DV_S0_Cheio:
    outchar r2, r0
DV_S1:
    ; slot 1 (endereco 1) - aparece se vidas >= 2
    loadn r0, #1
    loadn r1, #2
    cmp r3, r1
    jgr DV_S1_Cheio
    jeq DV_S1_Cheio
    loadn r1, #' '
    outchar r1, r0
    jmp DV_S2
DV_S1_Cheio:
    outchar r2, r0
DV_S2:
    ; slot 2 (endereco 2) - aparece se vidas >= 3
    loadn r0, #2
    loadn r1, #3
    cmp r3, r1
    jgr DV_S2_Cheio
    jeq DV_S2_Cheio
    loadn r1, #' '
    outchar r1, r0
    jmp DV_Fim
DV_S2_Cheio:
    outchar r2, r0
DV_Fim:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; Desenha o HUD dinamico (cronometro, pontuacao, indicador de fase) -
; chamado toda volta do loop principal, ja que esses valores mudam com
; frequencia (diferente dos coracoes, que so mudam ao levar dano e por
; isso continuam sendo desenhados dentro de Desenhar_Cenario_Fixo)
Desenhar_HUD:
    push r0
    push r1
    push r2
    push r3

    ; --- Cronometro (canto superior direito, colunas 36-39 da linha 0).
    ; Pisca a cor a cada segundo: impar = branco, par = vermelho ---
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
    loadn r2, #512               ; impar = branco
    jmp HUD_Tempo_CorFeita
HUD_Tempo_Par:
    loadn r2, #2304               ; par = vermelho
HUD_Tempo_CorFeita:
    loadn r0, #36
    load r1, tempo_seg
    call Imprimir_Numero

    ; --- Pontuacao (canto inferior direito, colunas 36-39 da linha 29) ---
    loadn r0, #1196
    load r1, pontuacao
    loadn r2, #512
    call Imprimir_Numero

    ; --- Indicador de fase "X/3" (canto inferior esquerdo, linha 29,
    ; colunas 0-2) ---
    loadn r0, #1160
    load r1, fase
    loadn r2, #'0'
    add r1, r1, r2
    loadn r2, #512
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

    ; 1. Predios pixelados no horizonte (linhas 0 a 2)
    ; Cada faixa tem uma altura diferente para formar uma silhueta urbana.
    ; Na fase 3 (so alunos / patio do campus) pulamos os predios, deixando
    ; o horizonte aberto - visual de patio/gramado em vez de rua da cidade
    load r3, fase
    loadn r2, #3
    cmp r3, r2
    jeq DCF_Predios_Pula

    loadn r0, #0
    loadn r1, #8
    loadn r2, #0
    call Desenhar_Predios
    loadn r0, #10
    loadn r1, #16
    loadn r2, #0
    call Desenhar_Predios
    loadn r0, #22
    loadn r1, #28
    loadn r2, #0
    call Desenhar_Predios
    loadn r0, #33
    loadn r1, #40
    loadn r2, #0
    call Desenhar_Predios

    loadn r0, #0
    loadn r1, #10
    loadn r2, #40
    call Desenhar_Predios
    loadn r0, #12
    loadn r1, #18
    loadn r2, #40
    call Desenhar_Predios
    loadn r0, #21
    loadn r1, #30
    loadn r2, #40
    call Desenhar_Predios
    loadn r0, #32
    loadn r1, #40
    loadn r2, #40
    call Desenhar_Predios

    loadn r0, #0
    loadn r1, #40
    loadn r2, #80
    call Desenhar_Predios

DCF_Predios_Pula:

    ; Banner da linha de chegada: varia conforme a fase atual
    ; (fase 1 = USP, fase 2 = ICMC, fase 3 = SIMOES)
    load r3, fase
    loadn r2, #2304

    loadn r1, #1
    cmp r3, r1
    jeq DCF_Banner_USP
    loadn r1, #2
    cmp r3, r1
    jeq DCF_Banner_ICMC
    jmp DCF_Banner_SIMOES

DCF_Banner_USP:
    loadn r0, #98
    loadn r1, #'U'
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #'S'
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #'P'
    add r1, r1, r2
    outchar r1, r0
    jmp DCF_Banner_Fim

DCF_Banner_ICMC:
    loadn r0, #98
    loadn r1, #'I'
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #'C'
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #'M'
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #'C'
    add r1, r1, r2
    outchar r1, r0
    jmp DCF_Banner_Fim

DCF_Banner_SIMOES:
    loadn r0, #97
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

DCF_Banner_Fim:

    ; 2. Tracejados Divisorios das Ruas (Correcao Limites)
    loadn r0, #200               
    call Desenhar_Linha_Pontilhada
    loadn r0, #280               
    call Desenhar_Linha_Pontilhada
    loadn r0, #360               
    call Desenhar_Linha_Pontilhada
    loadn r0, #440               
    call Desenhar_Linha_Pontilhada
    
    loadn r0, #520
    call Desenhar_Linha_Pontilhada
    loadn r0, #600               
    call Desenhar_Linha_Pontilhada
    loadn r0, #680               
    call Desenhar_Linha_Pontilhada
    loadn r0, #760               
    call Desenhar_Linha_Pontilhada
    loadn r0, #840
    call Desenhar_Linha_Pontilhada

    ; 2b. Textura de asfalto nas 8 pistas de carros
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

    ; 3. Passeio central (linhas 11 e 12)
    loadn r0, #440
    loadn r1, #520
    loadn r2, #'='
    loadn r3, #2048
    add r2, r2, r3
DCF_Grama:
    cmp r0, r1
    jeq DCF_Calcada
    outchar r2, r0
    inc r0
    jmp DCF_Grama

    ; 4. Passeio de nascimento (linhas 28 e 29)
DCF_Calcada:
    loadn r0, #1120
    loadn r1, #1200
    loadn r2, #'='
    loadn r3, #2048              
    add r2, r2, r3
DCF_Calcada_Loop:
    cmp r0, r1
    jeq DCF_Fim
    outchar r2, r0
    inc r0
    jmp DCF_Calcada_Loop

DCF_Fim:
    call Desenhar_Vidas         ; HUD de coracoes desenhado por cima do cenario
    pop r3
    pop r2
    pop r1
    pop r0
    rts

Desenhar_Predios:
    push r0
    push r1
    push r2
    push r3
    add r0, r0, r2
    add r1, r1, r2
    loadn r3, #'#'
    loadn r2, #2048
    add r3, r3, r2
DP_Loop:
    cmp r0, r1
    jeq DP_Fim
    outchar r3, r0
    inc r0
    jmp DP_Loop
DP_Fim:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

Desenhar_Linha_Pontilhada:
    push r0
    push r1
    push r2
    push r3
    loadn r1, #40
    add r1, r0, r1               
    loadn r2, #'-'
    loadn r3, #2048
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

; Espalha o "fleck" de asfalto ('x') ao longo de uma pista inteira (40
; colunas), de 3 em 3 colunas, simulando o granulado do asfalto em vez
; de uma pista lisa/preta. r0 = endereco inicial da linha (ex: 160)
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
    jmp DA_Loop
DA_Fim:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; Descobre o fundo correto de uma linha da tela (recebida em r1: 0-29) e
; devolve o caractere+cor correspondente em r0. Usado ao apagar o jogador,
; para restaurar a pista/tracejado/calcada/grama em vez de deixar um
; buraco de espaco em branco por onde ele anda
Fundo_Da_Linha:
    push r1
    push r2

    loadn r2, #28
    cmp r1, r2
    jgr FDL_Calcada
    jeq FDL_Calcada

    loadn r2, #11
    cmp r1, r2
    jeq FDL_Grama
    loadn r2, #12
    cmp r1, r2
    jeq FDL_Grama

    loadn r2, #4
    cmp r1, r2
    jeq FDL_Asfalto
    loadn r2, #6
    cmp r1, r2
    jeq FDL_Asfalto
    loadn r2, #8
    cmp r1, r2
    jeq FDL_Asfalto
    loadn r2, #10
    cmp r1, r2
    jeq FDL_Asfalto
    loadn r2, #14
    cmp r1, r2
    jeq FDL_Asfalto
    loadn r2, #16
    cmp r1, r2
    jeq FDL_Asfalto
    loadn r2, #18
    cmp r1, r2
    jeq FDL_Asfalto
    loadn r2, #20
    cmp r1, r2
    jeq FDL_Asfalto

    loadn r2, #5
    cmp r1, r2
    jeq FDL_Tracejado
    loadn r2, #7
    cmp r1, r2
    jeq FDL_Tracejado
    loadn r2, #9
    cmp r1, r2
    jeq FDL_Tracejado
    loadn r2, #13
    cmp r1, r2
    jeq FDL_Tracejado
    loadn r2, #15
    cmp r1, r2
    jeq FDL_Tracejado
    loadn r2, #17
    cmp r1, r2
    jeq FDL_Tracejado
    loadn r2, #19
    cmp r1, r2
    jeq FDL_Tracejado
    loadn r2, #21
    cmp r1, r2
    jeq FDL_Tracejado

    ; Qualquer outra linha (vaos em branco, horizonte, pista extra) -
    ; realmente fica em branco
    loadn r0, #' '
    jmp FDL_Fim

FDL_Calcada:
    loadn r0, #'='
    loadn r2, #2048
    add r0, r0, r2
    jmp FDL_Fim
FDL_Grama:
    loadn r0, #'='
    loadn r2, #2048
    add r0, r0, r2
    jmp FDL_Fim
FDL_Asfalto:
    loadn r0, #'x'
    loadn r2, #2048
    add r0, r0, r2
    jmp FDL_Fim
FDL_Tracejado:
    loadn r0, #'-'
    loadn r2, #2048
    add r0, r0, r2

FDL_Fim:
    pop r2
    pop r1
    rts

; Sorteia a posicao do chip colecionavel do modo reverso: uma das 8
; linhas "interessantes" (chip_linhas: pistas, grama, calcada, linha de
; chegada) e uma coluna entre 19 e 38 (deixando sempre espaco pro rotulo
; "CHIP DO SIMOES ->" caber a esquerda sem sair da tela). Nao ha
; instrucao de numero aleatorio nem de multiplicacao/divisao nesta CPU,
; entao tudo aqui usa o contador rng_seed com resto por subtracao
; repetida, e a conta linha*40 e feita somando 40 "linha" vezes
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
    ; r0 = indice (0-7); escolhe a linha correspondente por comparacao
    ; direta - sem array/indexacao, so o que ja e comprovado neste codigo
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
    ; r2 = linha sorteada (0-29)

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

    ; endereco = linha*40 + coluna (soma 40, "linha" vezes, no acumulador r3)
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

; Imprime um numero de 0 a 9999 como 4 digitos decimais (com zeros a
; esquerda), usando so subtracao repetida - nao ha instrucao de divisao
; nesta CPU. r0 = endereco inicial na tela, r1 = numero, r2 = cor
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

    ; unidades: o que sobrou em r1 (0-9)
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

; Soma r0 pontos a pontuacao, sem passar de 9999 (o maior valor que
; Imprimir_Numero consegue mostrar em 4 digitos)
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
    pop r2
    pop r1
    pop r0
    rts

; Concede 10 pontos por um passo "para frente" - o sentido depende do
; modo atual. r3 = 1 se o movimento foi pra CIMA (LT_Cima), 0 se foi
; pra BAIXO (LT_Baixo). No modo normal (ou no reverso ja com o chip
; encontrado), "frente" e pra cima; no reverso ainda procurando o chip,
; "frente" e pra baixo
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

    ; reverso=1 e chip ainda nao encontrado: "frente" e pra baixo
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

; Multiplica r0 * r1 (via somas repetidas) e soma o resultado a
; pontuacao (chamando Somar_Pontos). Usado pelos bonus de tempo restante
; e de vidas extras. Se r0 for 0, nao soma nada
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

Apagar_Dinamicos:
    push r0
    push r1
    push r2

    loadn r2, #40                

    ; Jogador: apaga corpo e cabeca restaurando o fundo correto de cada
    ; linha (em vez de espaco em branco), pra pista/calcada/grama nao
    ; sumirem quando o jogador anda por cima
    load r1, py
    call Fundo_Da_Linha
    load r1, player_addr
    outchar r0, r1

    load r1, py
    dec r1
    call Fundo_Da_Linha
    load r1, player_addr
    sub r1, r1, r2
    outchar r0, r1

    ; Apagar obstaculo volta a usar espaco em branco (o "fleck" de asfalto
    ; usado aqui antes deixava um rastro de 'x' marcando por onde cada
    ; carro passou - a textura de fundo so aparece uma vez, no desenho
    ; inicial da pista, e nao eh mais redesenhada no apagar)
    loadn r0, #' '

    ; OB 1 (5 celulas)
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

    ; OB 2 (3 celulas)
    load r1, ob2_addr
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1

    ; OB 3 (4 celulas)
    load r1, ob3_addr
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1

    ; OB 4 (3 celulas)
    load r1, ob4_addr
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1

    ; OB 5 (3 celulas)
    load r1, ob5_addr
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1

    ; OB 6 (5 celulas)
    load r1, ob6_addr
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1

    ; OB 7 (3 celulas)
    load r1, ob7_addr
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1

    ; OB 8 (4 celulas)
    load r1, ob8_addr
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1

    ; OB9 (pista extra) - so apaga se ja estiver liberada
    load r1, ob9_ativo
    loadn r2, #0
    cmp r1, r2
    jeq AD_Obs9_Fim
    load r1, ob9_addr
    outchar r0, r1
    inc r1
    outchar r0, r1
    inc r1
    outchar r0, r1
AD_Obs9_Fim:

    ; Chip colecionavel (modo reverso) - apaga sempre que estiver ativo
    ; (icone + area do rotulo), pra permitir o rotulo "piscar" direito
    load r3, chip_ativo
    loadn r2, #0
    cmp r3, r2
    jeq AD_Chip_Fim

    load r1, chip_addr
    loadn r0, #' '
    outchar r0, r1

    loadn r2, #19
    sub r1, r1, r2
    loadn r3, #0
AD_Chip_Label_Loop:
    loadn r2, #19
    cmp r3, r2
    jeq AD_Chip_Fim
    outchar r0, r1
    inc r1
    inc r3
    jmp AD_Chip_Label_Loop

AD_Chip_Fim:

    pop r2
    pop r1
    pop r0
    rts

Desenhar_Dinamicos:
    push r0
    push r1
    push r2
    push r3

    ; Escolhe o "tema" visual dos obstaculos conforme a fase atual:
    ; fase 1 = rua (carros/onibus), fase 2 = campus (mistura de carros,
    ; motos e alunos), fase 3 = so alunos (parados, correndo, com cadeira)
    load r3, fase
    loadn r2, #1
    cmp r3, r2
    jeq DD_Obs_Fase1
    loadn r2, #2
    cmp r3, r2
    jeq DD_Obs_Fase2
    jmp DD_Obs_Fase3

DD_Obs_Fase1:
    load r1, ob1_addr
    loadn r3, #2304               ; era 2816 (saia escuro/piscando) - agora claro e visivel
    loadn r2, #'['
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
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1

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

    ; Onibus Branco (4 celulas): traseira '[' + 2 janelas 'K'/'W' + frente ']'
    load r1, ob3_addr
    loadn r3, #2048              
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'K'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'W'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1

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

    load r1, ob5_addr
    loadn r3, #2048               
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

    load r1, ob6_addr
    loadn r3, #3072               ; era 2816 (mesma cor escura/piscando do ob1)
    loadn r2, #'['
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
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1

    load r1, ob7_addr
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

    ; Onibus Branco (4 celulas): traseira '[' + 2 janelas 'K'/'W' + frente ']'
    load r1, ob8_addr
    loadn r3, #2304              
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'K'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'W'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1
    jmp DD_Obs_Fim

DD_Obs_Fase2:
    ; OB1: continua onibus/van do campus
    load r1, ob1_addr
    loadn r3, #2304
    loadn r2, #'['
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
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1

    ; OB2: moto
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

    ; OB3: continua onibus/van do campus
    load r1, ob3_addr
    loadn r3, #2048
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'K'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'W'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1

    ; OB4: moto
    load r1, ob4_addr
    loadn r3, #3072
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

    ; OB5: continua carro
    load r1, ob5_addr
    loadn r3, #2048
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

    ; OB6: grupo de alunos atravessando
    load r1, ob6_addr
    loadn r3, #3072
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

    ; OB7: continua carro
    load r1, ob7_addr
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

    ; OB8: continua onibus/van do campus
    load r1, ob8_addr
    loadn r3, #2304
    loadn r2, #'['
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'K'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #'W'
    add r0, r2, r3
    outchar r0, r1
    inc r1
    loadn r2, #']'
    add r0, r2, r3
    outchar r0, r1

    jmp DD_Obs_Fim

DD_Obs_Fase3:
    ; OB1: alunos (normal/correndo/cadeira)
    load r1, ob1_addr
    loadn r3, #2304
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

    ; OB2: alunos (com cadeira no meio)
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

    ; OB3: grupo correndo
    load r1, ob3_addr
    loadn r3, #2048
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

    ; OB4: alunos com cadeira
    load r1, ob4_addr
    loadn r3, #3072
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

    ; OB5: alunos
    load r1, ob5_addr
    loadn r3, #2048
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

    ; OB6: grupo grande, mistura correndo/normal
    load r1, ob6_addr
    loadn r3, #3072
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

    ; OB7: alunos
    load r1, ob7_addr
    loadn r3, #2304
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

    ; OB8: alunos com cadeira/correndo
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

    ; OB9 (pista extra em direcao aleatoria) - so desenha se ja liberada.
    ; Sempre um carro (cor de alerta), independente do tema da fase, pra
    ; se destacar como uma pista "fora do padrao"
    load r3, ob9_ativo
    loadn r2, #0
    cmp r3, r2
    jeq DD_Obs9_Fim
    load r1, ob9_addr
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
DD_Obs9_Fim:

    ; Chip colecionavel (modo reverso) - so desenha se ainda ativo
    load r3, chip_ativo
    loadn r2, #0
    cmp r3, r2
    jeq DD_Chip_Fim

    load r1, chip_addr
    loadn r3, #2304
    loadn r2, #'k'
    add r0, r2, r3
    outchar r0, r1

    ; O rotulo "CHIP DO SIMOES ->" pisca (some na metade dos passos),
    ; usando o mesmo player_frame que ja anima as pernas do jogador
    load r2, player_frame
    loadn r3, #1
    cmp r2, r3
    jne DD_Chip_Fim

    load r1, chip_addr
    loadn r2, #19
    sub r0, r1, r2
    loadn r1, #msg_chip_label
    loadn r2, #2304
    call Imprimestr

DD_Chip_Fim:

    ; ---- JOGADOR ----
    ; Corpo (torso+pernas) alterna entre dois sprites dedicados ('w'/'y')
    ; conforme player_frame. NAO usa mais '}' aqui - esse caractere e do
    ; corpo dos carros/onibus; reaproveita-lo faria o jogador ficar com
    ; cara de carrinho tambem
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
    loadn r3, #512
    add r0, r2, r3
    outchar r0, r1

    ; Cabeca+torax+bracos, tambem animado (era um '@' fixo - a "mochila"
    ; cinza que nao mudava nunca). Agora alterna 'j'/'@' em sincronia com
    ; as pernas: o braço oposto a perna esticada tambem se estica
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
    loadn r3, #2048                
    add r0, r2, r3
    outchar r0, r1

    pop r3
    pop r2
    pop r1
    pop r0
    rts

; Alterna player_frame entre 0 e 1. Chamada apenas quando o jogador de
; fato se move (nao quando esbarra na borda da tela), para a animacao
; de "passos" andar junto com o movimento
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

    ; Contador pseudo-aleatorio: cresce a cada quadro, usado so para
    ; sortear a direcao da pista extra (ob9) quando ela e liberada
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
MO_1:
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
MO_2:
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
MO_3:
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
MO_4:
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
MO_5:
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
MO_6:
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
MO_7:
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
MO_8:
MO_8_Store:
    store ob8_addr, r0

    ; OB9 (pista extra, so se ja estiver liberada) - direcao aleatoria
    load r0, ob9_ativo
    loadn r1, #0
    cmp r0, r1
    jeq MO_9_Fim

    load r1, ob9_dir
    loadn r0, #0
    cmp r1, r0
    jeq MO_9_Direita

    ; Contramao: decrementa; se passar do inicio, volta pro fim
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


; Verifica se o jogador pisou em cima do chip colecionavel (so importa
; no modo reverso, mas a checagem em si e inofensiva mesmo fora dele -
; chip_ativo so fica 1 quando o chip existe de verdade). Se coletou,
; mostra uma mensagem rapida e volta a tela do jogo pro mesmo ponto
Testar_Chip:
    push r0
    push r1
    push r2

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

    ; Achou o chip: o objetivo muda para voltar a sala (fim da fase 3 -
    ; py=2), entao trava a fase em 3 (skin da sala do Simoes) dali em
    ; diante, nao importa em qual das 3 pernas do modo reverso ele
    ; estava quando achou
    loadn r0, #1
    store chip_encontrado, r0
    loadn r0, #3
    store fase, r0

    call Apagar_Tela
    loadn r0, #527
    loadn r1, #msg_chip_achado1
    loadn r2, #2304
    call Imprimestr
    loadn r0, #567
    loadn r1, #msg_chip_achado2
    loadn r2, #2304
    call Imprimestr
    call Atraso_Jogo
    call Atraso_Jogo

    call Apagar_Tela
    call Desenhar_Cenario_Fixo
    call Desenhar_Dinamicos

TCP_Fim:
    pop r2
    pop r1
    pop r0
    rts

; Chamado todo quadro do loop principal. Conta as voltas do loop ate
; completar "1 segundo" (nao ha relogio de hardware nesta CPU, entao 1
; segundo e aproximado por uma quantidade fixa de voltas - ajustavel
; aqui trocando o "20"; a velocidade real do jogo muda com atraso_var,
; entao a precisao desse "segundo" varia um pouco com a dificuldade)
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

; Verifica se o tempo acabou. Se sim, funciona como se o jogador tivesse
; sido atingido: perde uma vida (ou vai pra tela de derrota se ja for a
; ultima) e o cronometro reinicia em 60s para nao ficar travado em 0
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
    jeq TC_GameOver          ; reaproveita a tela de derrota (tempo esgotado)

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

    ; Hitbox: usa APENAS a linha logica real do jogador (r0).
    ; (Antes tambem checava r7 = player_addr-40, a linha da 'cabeca'
    ;  visual do sprite, o que causava colisao uma linha ANTES do
    ;  jogador realmente entrar na pista - bug corrigido aqui)
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

    ; OB9 (pista extra) - so verifica colisao se ja estiver liberada
    load r2, ob9_ativo
    loadn r3, #0
    cmp r2, r3
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
    ; Chegamos aqui de dentro de Testar_Colisao (via jeq), sem passar pelo
    ; pop/rts normal dela. r0/r1 aqui embaixo sao livres para usar - no
    ; fim, desempilhamos o r0/r1 que Testar_Colisao empilhou na entrada,
    ; para devolver a rotina corretamente ao loop principal.

    load r0, vidas
    dec r0
    store vidas, r0

    loadn r1, #0
    cmp r0, r1
    jeq TC_GameOver

    ; Ainda restam vidas: pisca o jogador, tira 1 coracao e volta pro
    ; inicio da travessia (sem reiniciar fase/velocidade)
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
    call Apagar_Tela
    loadn r0, #567          
    loadn r1, #msg_derrota  
    loadn r2, #2304         
    call Imprimestr
    call Atraso_Jogo
    call Atraso_Jogo

    ; Descarta o contexto de Testar_Colisao (nao vamos retornar por rts -
    ; a partida acabou, o fluxo agora vai direto pro lobby)
    pop r0
    pop r1
    pop r2

    ; Fim de jogo de verdade: zera o progresso e reinicia tudo antes de
    ; voltar pro lobby
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

; Faz o sprite do jogador piscar (aparece/some) algumas vezes no lugar
; onde foi atingido - feedback visual de dano antes de voltar ao inicio
Piscar_Jogador:
    push r0
    push r1
    push r2
    push r3
    loadn r3, #6                ; numero de trocas apagado/desenhado
PJ_Loop:
    ; apaga corpo + cabeca, restaurando o fundo correto de cada linha
    load r1, py
    call Fundo_Da_Linha
    load r1, player_addr
    outchar r0, r1

    load r1, py
    dec r1
    call Fundo_Da_Linha
    load r1, player_addr
    loadn r2, #40
    sub r1, r1, r2
    outchar r0, r1
    call Atraso_Jogo

    ; redesenha corpo (quadro atual) + cabeca/torax (mesmo quadro)
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
    loadn r2, #512
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
    loadn r0, #2048
    add r2, r2, r0
    load r1, player_addr
    loadn r0, #40
    sub r1, r1, r0
    outchar r2, r1
    call Atraso_Jogo

    dec r3
    jnz PJ_Loop

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

    ; Ainda procurando o chip: alvo e py==29 (fim da perna atual)
    load r0, py
    loadn r1, #29
    cmp r0, r1
    jne TV_Fim

    call Apagar_Tela
    loadn r0, #567
    loadn r1, #msg_vitoria
    loadn r2, #512
    call Imprimestr
    call Atraso_Jogo
    call Atraso_Jogo

    ; +50 pontos por avancar de perna
    loadn r0, #50
    call Somar_Pontos

    ; Se a fase atual (antes de decrementar) ja e a 1, essa era a ultima
    ; perna sem ter achado o chip - encerra o modo reverso mesmo assim
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

    ; Ja achou o chip: alvo agora e py==2 (voltar pra sala do Simoes)
TV_Reverso_ComChip:
    load r0, py
    loadn r1, #2
    cmp r0, r1
    jne TV_Fim

    ; Bonus de tempo (+10 por segundo restante) e de vida extra (+50 por
    ; vida alem da primeira), igual ao final normal
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
    ; MODO NORMAL (jogo pra frente, como sempre foi)
    ; ========================================================================
TV_Modo_Normal:
    load r0, py
    loadn r1, #2
    cmp r0, r1
    jne TV_Fim
    
    ; Mostra a mensagem de vitoria por um instante
    call Apagar_Tela
    loadn r0, #567
    loadn r1, #msg_vitoria
    loadn r2, #512          
    call Imprimestr
    call Atraso_Jogo
    call Atraso_Jogo

    ; +50 pontos por avancar de fase
    loadn r0, #50
    call Somar_Pontos

    ; Se a fase que acabou de vencer era a 3 (SIMOES), vai direto pra tela
    ; de vitoria final; senao (fase 1 ou 2), registra o progresso e mostra
    ; o check-in perguntando se continua ou "morcegar" (volta pro lobby)
    load r0, fase
    loadn r1, #3
    cmp r0, r1
    jeq TV_Ir_Final

    load r0, fases_vencidas
    inc r0
    store fases_vencidas, r0

    ; Descarta o contexto desta chamada (nao vamos retornar por rts -
    ; dali em diante o fluxo continua em TELA_CHECKIN, que so retorna
    ; pro loop principal via jmp direto, nao por rts)
    pop r2
    pop r1
    pop r0
    pop r3
    jmp TELA_CHECKIN

TV_Ir_Final:
    ; Chegou "a toca" (fim da fase 3): bonus de tempo (+10 por segundo
    ; restante) e bonus de vida extra (+50 por vida alem da primeira)
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
    loadn r0, #560
    loadn r1, #msg_checkin
    loadn r2, #512
    call Imprimestr

TCK_Espera:
    inchar r0
    loadn r1, #255
    cmp r0, r1
    jeq TCK_Espera
    loadn r1, #'c'
    cmp r0, r1
    jeq TCK_Continuar
    loadn r1, #'m'
    cmp r0, r1
    jeq TCK_Morcegar
    jmp TCK_Espera

TCK_Continuar:
    ; Dificuldade progressiva (mesma logica de sempre)
    load r0, atraso_var
    loadn r1, #3
    cmp r0, r1
    jeq TCK_SemReduzir
    dec r0
    store atraso_var, r0
TCK_SemReduzir:

    ; Avanca (ou recua, no modo reverso) de fase. So chegamos aqui vindo
    ; de uma fase intermediaria (a ultima perna de cada sentido vai
    ; direto pra tela final correspondente), entao so precisamos somar
    ; ou subtrair 1
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

    ; Pista extra (ob9): ativa a partir da fase 2, direcao sorteada pela
    ; paridade do contador rng_seed
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

    ; Reinicia o jogador no ponto de partida da proxima perna. No modo
    ; normal, isso e a calcada inicial (py=29); no modo reverso, e a
    ; linha de chegada (py=2), ja que o jogador esta vindo "de volta"
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

    jmp LOOP_PRINCIPAL

TCK_Morcegar:
    ; "Morcegar": desiste desta tentativa e volta pro lobby, mas mantem
    ; fases_vencidas pra mostrar o progresso por la. Tambem sai do modo
    ; reverso, caso estivesse nele
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
; TELA DE VITORIA FINAL - aparece ao vencer a fase 3 (SIMOES). O Simoes
; ficou puto porque perderam o chip dele; o jogador escolhe entre voltar
; procurando (S) ou ignorar e encerrar o ciclo aqui mesmo (ESC)
; ============================================================================
TELA_VITORIA_FINAL:
    call Apagar_Tela
    loadn r0, #365
    loadn r1, #msg_puto1
    loadn r2, #2304
    call Imprimestr
    loadn r0, #405
    loadn r1, #msg_puto2
    loadn r2, #2304
    call Imprimestr
    loadn r0, #445
    loadn r1, #msg_puto3
    loadn r2, #2304
    call Imprimestr

    ; Carinha de bravo, entre o texto e os comandos
    loadn r0, #499
    loadn r1, #'v'
    loadn r2, #2304
    add r1, r1, r2
    outchar r1, r0

    loadn r0, #565
    loadn r1, #msg_opcao_s
    loadn r2, #512
    call Imprimestr
    loadn r0, #605
    loadn r1, #msg_opcao_esc
    loadn r2, #512
    call Imprimestr

TVF_Espera:
    inchar r0
    loadn r1, #255
    cmp r0, r1
    jeq TVF_Espera
    loadn r1, #'s'
    cmp r0, r1
    jeq TVF_Volta
    ; ATENCAO: 27 e o codigo ASCII padrao da tecla ESC. Se o teclado
    ; deste simulador usar outro codigo pra ESC, so trocar o #27 abaixo
    loadn r1, #27
    cmp r0, r1
    jeq TVF_Ignora
    jmp TVF_Espera

TVF_Volta:
    ; Ativa o modo reverso: comeca na linha de chegada (fase 3, SIMOES)
    ; e vai voltando ate a fase 1, com o chip sorteado em algum lugar
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

    ; Pista extra (ob9) ativa (a fase 3 sempre tem), direcao sorteada
    ; pela paridade do contador rng_seed - mesma logica do check-in
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

    ; Cronometro: reinicia com 3 minutos extras pra achar o chip e voltar
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
    ; Ignora o chip: fecha o ciclo normalmente e volta pro lobby
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
; TELA DE FIM DO MODO REVERSO - o jogador conseguiu voltar ate o inicio
; ============================================================================
TELA_REVERSO_FIM:
    call Apagar_Tela
    loadn r0, #567
    loadn r1, #msg_reverso_fim
    loadn r2, #512
    call Imprimestr
    call Atraso_Jogo
    call Atraso_Jogo
    call Atraso_Jogo

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
; LOBBY - tela inicial com o nome do jogo
; ============================================================================
LOBBY:
    call Apagar_Tela

    loadn r0, #365
    loadn r1, #msg_titulo
    loadn r2, #2304
    call Imprimestr

    ; Mostra o progresso (fases vencidas) se houver algum ainda pendente
    load r3, fases_vencidas
    loadn r2, #0
    cmp r3, r2
    jeq LOBBY_SemProgresso

    loadn r0, #480
    loadn r1, #msg_progresso
    loadn r2, #2304
    call Imprimestr

    ; Digito de fases_vencidas (0-3) logo apos o texto (que tem 17
    ; caracteres, entao o proximo endereco livre e 480+17=497)
    load r0, fases_vencidas
    loadn r1, #'0'
    add r0, r0, r1
    loadn r1, #2304
    add r0, r0, r1
    loadn r1, #497
    outchar r0, r1

LOBBY_SemProgresso:

LOBBY_Espera:
    inchar r0
    loadn r1, #255
    cmp r0, r1
    jeq LOBBY_Espera

    ; Comeca uma partida nova (fase 1, sentido normal) - ob9 e
    ; fases_vencidas NAO sao zerados aqui: se o jogador voltou de um
    ; "morcegar", fases_vencidas continua mostrando o progresso ate a
    ; proxima vitoria final
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
