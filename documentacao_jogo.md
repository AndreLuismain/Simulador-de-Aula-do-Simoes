# Documentação: Simulador Aula do Simões (JOGO.asm)

## Visão Geral do Jogo
O **Simulador Aula do Simões** é um jogo em Assembly com mecânicas semelhantes ao clássico *Frogger*. O objetivo do jogador é atravessar a rua (ou o campus) desviando de obstáculos móveis (carros, ônibus, motos e grupos de alunos) para chegar à linha de chegada no topo da tela. 

O jogo é composto por:
*   **Tela Inicial Arcade (Menu):** Gabinete animado com opções interativas para **Jogar**, **Como Jogar** e **Créditos**, além de placar de **Recorde** da sessão.
*   **Fases Progressivas:** O jogo possui 3 fases (USP, ICMC e SIMÕES). A cada fase concluída, os obstáculos ficam mais rápidos e o visual/tema do cenário e dos obstáculos muda.
*   **Modo Reverso (Caça ao Chip):** Ao vencer a fase 3, um evento especial ocorre. O jogador deve fazer o caminho inverso (de cima para baixo) passando pelas três fases de costas para encontrar um "Chip do Simões" gerado em uma posição aleatória e devolvê-lo à sala.
*   **Sistema de Vidas e Tempo:** O jogador possui 3 vidas (representadas por corações cheios e vazados). Há um limite de tempo de 60 segundos por tela (ou 180 segundos no modo reverso).
*   **Pontuação e Recorde:** Pontos são adquiridos ao se mover para frente, atravessar faixas específicas e ao completar fases (incluindo bônus por vidas e tempo restantes), atualizando automaticamente o recorde da sessão.

---

## Estrutura do Código e Loop Principal

O programa inicia na tela de abertura `LOBBY` (menu *arcade*). Ao selecionar **JOGAR**, salta para a label `INICIO`, onde inicializa e desenha o cenário estático e os elementos dinâmicos (jogador, obstáculos e HUD). 
Logo após, entra no `LOOP_PRINCIPAL`, que é executado repetidamente e segue o seguinte fluxo a cada quadro (frame):
1. Apaga os elementos dinâmicos da posição anterior restaurando o fundo exato de cada célula.
2. Lê a entrada do teclado.
3. Move os obstáculos (e atualiza o gerador de números pseudo-aleatórios).
4. Redesenha o portal da linha de chegada e os elementos dinâmicos em suas novas posições.
5. Testa colisões, captura de itens (chip), condições de vitória e esgotamento de tempo.
6. Atualiza o HUD (interface de pontos, troféu, relógio e fase).
7. Aguarda um tempo de atraso (delay) para controlar a velocidade do jogo.

---

## Dicionário de Funções (Subrotinas)

Abaixo está o detalhamento de cada função estruturada no código-fonte, agrupadas por sua responsabilidade.

### 1. Gráficos, Molduras Arcade e Renderização de Cenário
*   **`Apagar_Tela`**: Preenche toda a tela (endereços de 0 a 1199) com caracteres de espaço em branco, limpando completamente a exibição.
*   **`Desenhar_Caixa_Dupla` / `Desenhar_Botao` / `Desenhar_Linha_Horiz`**: Utilitários gráficos de interface *arcade* que desenham janelas com moldura dupla (`#3..#9`), botões interativos de 3 linhas (`#25..#30`) e divisórias horizontais.
*   **`Desenhar_Cenario_Fixo` / `Desenhar_Banner_Chegada`**: Desenham a estrutura estática do mapa de acordo com a fase atual. Incluem o horizonte temático (arranha-céus coloridos com telhados e janelas acesas na Fase 1, prédios e árvores do ICMC na Fase 2 e pátio arborizado na Fase 3), canteiro central de grama viva, calçadas quadriculadas e os portais de chegada (`USP`, `ICMC`, `SIMOES`).
*   **`Desenhar_Bloco_Predio` / `Desenhar_Linha_Pontilhada` / `Desenhar_Asfalto`**: Funções auxiliares chamadas pelo cenário fixo para desenhar blocos de edifícios coloridos, as faixas tracejadas da rua (prata, amarelo no eixo central e vermelho na 9ª pista) e a textura pontilhada do asfalto.
*   **`Fundo_Da_Celula` / `Apagar_Celula_Pista`**: Retornam e restauram com precisão de coluna e linha o caractere e a cor originais do cenário (grama, calçada, faixa tracejada ou textura do asfalto a cada 4 colunas), evitando apagar detalhes da pista quando carros ou o jogador se movem.
*   **`Desenhar_Vidas` / `Desenhar_HUD`**: Atualizam a interface de usuário (Heads-Up Display). `Desenhar_Vidas` desenha corações vermelhos cheios (`h`) e corações vazados (`#18`) para vidas perdidas. `Desenhar_HUD` desenha o ícone de relógio com cronômetro, o troféu dourado com a pontuação e o indicador `X/3` da fase.

### 2. Elementos Dinâmicos (Jogador e Obstáculos)
*   **`Desenhar_Dinamicos`**: Renderiza os obstáculos coloridos (veículos ou alunos), o chip colecionável e o jogador. A aparência dos obstáculos muda com base na `fase` atual (fase 1: cidade; fase 2: misto; fase 3: apenas alunos no campus). Também anima as pernas e braços do jogador dependendo do quadro atual.
*   **`Apagar_Dinamicos`**: Restaura os pixels ocupados pelos obstáculos usando `Apagar_Celula_Pista` e os pixels do jogador e do rótulo do chip utilizando `Fundo_Da_Celula`.
*   **`Alternar_Frame_Jogador`**: Alterna o quadro de animação do sprite do jogador (entre 0 e 1) toda vez que ocorre um movimento, criando o efeito de caminhada.
*   **`Piscar_Jogador`**: Cria um efeito visual (feedback de dano) fazendo o sprite do jogador piscar em vermelho no ponto de impacto ao colidir com um obstáculo ou perder por tempo, limpando o local antes de reposicionar o jogador no início.

### 3. Movimento e Controles
*   **`Ler_Teclado`**: Lê a entrada (`WASD`, maiúsculas ou minúsculas) para movimentar o personagem. Trata limites da tela (para não sair do mapa) e chama as rotinas de pontuação e atualização de sprite correspondentes a cada passo.
*   **`Mover_Obstaculos`**: Move todos os obstáculos horizontais pela tela. Caso o veículo passe do limite, ele ressurge do outro lado. Também movimenta a "pista extra" (`ob9`), que pode fluir de forma contrária aos demais (contramão) com base em um sorteio aleatório de direção.

### 4. Lógica e Regras de Jogo
*   **`Testar_Colisao`**: Varre as coordenadas atuais de cada obstáculo e compara com a coordenada (hitbox) real do jogador. Se houver sobreposição, o jogador sofre dano e o ciclo é interrompido para deduzir uma vida.
*   **`Testar_Vitoria` / `Mostrar_Card_Fase_Concluida`**: Avaliam se o jogador alcançou o fim da travessia lógica da rodada. No modo normal, ocorre ao chegar na linha de chegada (`py = 2`). No modo reverso, os limites se invertem até o chip ser encontrado. Calcula pontuações de bônus e redireciona o jogador para a tela de continuação correta.
*   **`Testar_Chip` / `Sortear_Chip`**: Lidam com o modo reverso. `Sortear_Chip` usa aritmética modular sobre a `rng_seed` para colocar o chip em um local aleatório da tela. `Testar_Chip` verifica se o jogador sobrepôs a coordenada desse item e exibe o card de captura.
*   **`Atualizar_Cronometro` / `Testar_Tempo`**: Mantêm a cadência de passagem do tempo, deduzindo segundos baseando-se em contadores de frames. Se o tempo zerar, atua exatamente como uma colisão, subtraindo uma vida do jogador.
*   **`Atraso_Jogo` / `Atraso_Popup`**: Executam laços de repetição ociosos (delay) para controlar a velocidade de quadros e o tempo de exibição de cartões de aviso.

### 5. Matemática e Interface Numérica
*   **`Somar_Pontos` / `Atualizar_Recorde`**: Adicionam pontuação ao jogador com trava de segurança em 9999 e atualizam automaticamente o `recorde` máximo da sessão.
*   **`Pontuar_Movimento` / `Multiplicar_E_Somar_Pontos`**: Distribuem pontuações ativas. Movimentações dão pontos base, e as multiplicações fornecem bônus de conversão (tempo restante e vidas extras) ao completar telas.
*   **`Imprimir_Numero`**: Isola as casas decimais (milhar, centena, dezena, unidade) usando laços de subtração contínua para plotar números inteiros de 4 dígitos na tela.
*   **`Imprimestr`**: Recebe um ponteiro e imprime uma string finalizada com null-terminator (`\0`) no endereço de tela desejado com a cor escolhida.

### 6. Gerenciamento de Estado (Telas e Menus Arcade)
*   **`LOBBY` / `Desenhar_Botoes_Lobby` / `Animar_Lobby` / `Aguardar_Ou_Ler_Menu`**: Tela de abertura estilo *arcade*, com letreiro dourado, recorde da sessão, mini-avenida animada com ônibus e carro em movimento, luzes piscantes e seleção interativa entre **JOGAR**, **COMO JOGAR** e **CREDITOS** (`W`/`S` + `ENTER`/`ESPAÇO` ou `1`/`2`/`3`).
*   **`TELA_COMO_JOGAR`**: Guia ilustrado acessível pelo menu inicial, exibindo controles, mini-sprites das 3 fases, sistema de pontuação e explicação do modo reverso.
*   **`TELA_CREDITOS`**: Tela de créditos com moldura dourada listando os cinco autores do projeto e a homenagem ao Prof. Eduardo do Valle Simões.
*   **`TELA_CHECKIN`**: Janela de transição após concluir a fase 1 ou 2. Permite ao jogador "Continuar" (`C`) para a próxima etapa (aumentando a velocidade e ativando a pista 9 surpresa) ou "Morcegar" (`M`), salvando o progresso `X/3` e voltando ao menu principal.
*   **`TELA_VITORIA_FINAL`**: Acionada ao finalizar a fase 3. Traz a narrativa da fúria do "Simões" pela perda do chip e convida o jogador a iniciar o modo reverso (`S`) ou ignorar e voltar ao menu (`N` / `ESC`).
*   **`TELA_REVERSO_FIM`**: A verdadeira conclusão do jogo, acionada após coletar o chip na jornada de volta e entregá-lo na sala do Simões, exibindo pontuação final e melhor marca da sessão.
