# Documentação: Simulador Aula do Simões (JOGO.asm)

## Visão Geral do Jogo
O **Simulador Aula do Simões** é um jogo em Assembly com mecânicas semelhantes ao clássico *Frogger*. O objetivo do jogador é atravessar a rua (ou o campus) desviando de obstáculos móveis (carros, ônibus, motos e grupos de alunos) para chegar à linha de chegada no topo da tela. 

O jogo é composto por:
*   **Fases Progressivas:** O jogo possui 3 fases (USP, ICMC e SIMÕES). A cada fase concluída, os obstáculos ficam mais rápidos e o visual/tema dos obstáculos muda.
*   **Modo Reverso (Caça ao Chip):** Ao vencer a fase 3, um evento especial ocorre. O jogador deve fazer o caminho inverso (de cima para baixo) passando pelas três fases de costas para encontrar um "Chip do Simões" gerado em uma posição aleatória e devolvê-lo à sala.
*   **Sistema de Vidas e Tempo:** O jogador possui 3 vidas (representadas por corações). Há um limite de tempo de 60 segundos por tela (ou 180 segundos no modo reverso).
*   **Pontuação:** Pontos são adquiridos ao se mover para frente, atravessar faixas específicas e ao completar fases (incluindo bônus por vidas e tempo restantes).

---

## Estrutura do Código e Loop Principal

O programa começa na label `INICIO`, onde inicializa e desenha o cenário estático e os elementos dinâmicos (jogador e obstáculos). 
Logo após, entra no `LOOP_PRINCIPAL`, que é executado repetidamente e segue o seguinte fluxo a cada quadro (frame):
1. Apaga os elementos dinâmicos da posição anterior.
2. Lê a entrada do teclado.
3. Move os obstáculos (e atualiza o gerador de números pseudo-aleatórios).
4. Redesenha os elementos dinâmicos em suas novas posições.
5. Testa colisões, captura de itens (chip), condições de vitória e esgotamento de tempo.
6. Atualiza o HUD (interface de pontos e tempo).
7. Aguarda um tempo de atraso (delay) para controlar a velocidade do jogo.

---

## Dicionário de Funções (Subrotinas)

Abaixo está o detalhamento de cada função estruturada no código-fonte, agrupadas por sua responsabilidade.

### 1. Gráficos e Renderização de Cenário
*   **`Apagar_Tela`**: Preenche toda a tela (endereços de 0 a 1199) com caracteres de espaço em branco, limpando completamente a exibição.
*   **`Desenhar_Cenario_Fixo`**: Desenha a estrutura estática do mapa de acordo com a fase atual. Inclui o horizonte (prédios), as faixas da pista, canteiros de grama, calçadas e a faixa de chegada (banners USP/ICMC/SIMOES).
*   **`Desenhar_Predios` / `Desenhar_Linha_Pontilhada` / `Desenhar_Asfalto`**: Funções auxiliares chamadas pelo cenário fixo para desenhar padrões repetitivos como os prédios ao fundo, as faixas tracejadas da rua e a textura pontilhada do asfalto.
*   **`Fundo_Da_Linha`**: Retorna o caractere de fundo original (grama, asfalto, faixa, etc.) de uma linha específica da tela. Essencial para que o rastro do jogador seja apagado restaurando o chão correto em vez de deixar um "buraco negro" de espaços em branco.
*   **`Desenhar_Vidas` / `Desenhar_HUD`**: Atualizam a interface de usuário (Heads-Up Display). `Desenhar_Vidas` desenha os corações no canto superior esquerdo. `Desenhar_HUD` desenha o cronômetro, a pontuação e o indicador de fases vencidas no rodapé.

### 2. Elementos Dinâmicos (Jogador e Obstáculos)
*   **`Desenhar_Dinamicos`**: Renderiza os obstáculos (veículos ou alunos) e o jogador. A aparência dos obstáculos muda com base na `fase` atual (fase 1: cidade; fase 2: misto; fase 3: apenas alunos no campus). Também é responsável por animar as pernas e braços do jogador dependendo do estado atual.
*   **`Apagar_Dinamicos`**: Restaura os pixels ocupados pelos obstáculos usando espaços e os pixels do jogador utilizando a rotina `Fundo_Da_Linha`. Apaga também o rótulo do chip colecionável, se estiver ativo.
*   **`Alternar_Frame_Jogador`**: Alterna o quadro de animação do sprite do jogador (entre 0 e 1) toda vez que ocorre um movimento, criando o efeito de caminhada.
*   **`Piscar_Jogador`**: Cria um efeito visual (feedback de dano) fazendo o sprite do jogador piscar sucessivas vezes ao colidir com um obstáculo ou perder por tempo, antes de o reposicionar no ponto de início.

### 3. Movimento e Controles
*   **`Ler_Teclado`**: Lê a entrada (WASD) para movimentar o personagem. Trata limites da tela (para não sair do mapa) e chama as rotinas de pontuação e atualização de sprite correspondentes a cada passo.
*   **`Mover_Obstaculos`**: Move todos os obstáculos horizontais pela tela. Caso o veículo passe do limite, ele ressurge do outro lado. Também movimenta a "pista extra" (ob9), que pode fluir de forma contrária aos demais (contramão) com base em um sorteio aleatório de direção.

### 4. Lógica e Regras de Jogo
*   **`Testar_Colisao`**: Varre as coordenadas atuais de cada obstáculo e compara com a coordenada (hitbox) real do jogador. Se houver sobreposição, o jogador sofre dano e o ciclo é interrompido para deduzir uma vida.
*   **`Testar_Vitoria`**: Avalia se o jogador alcançou o fim da travessia lógica da rodada. No modo normal, ocorre ao chegar na linha de chegada. No modo reverso, os limites se invertem. Calcula pontuações de bônus e redireciona o jogador para a tela de continuação correta.
*   **`Testar_Chip` / `Sortear_Chip`**: Lidam com o modo reverso. `Sortear_Chip` usa aritmética rudimentar modular sobre a `rng_seed` (variável iterada a cada loop) para colocar o chip em um local aleatório da tela. `Testar_Chip` verifica se o jogador sobrepôs a coordenada desse item.
*   **`Atualizar_Cronometro` / `Testar_Tempo`**: Mantêm a cadência de passagem do tempo, deduzindo segundos baseando-se em contadores de frames. Se o tempo zerar, atua exatamente como uma colisão, subtraindo uma vida do jogador.
*   **`Atraso_Jogo`**: Executa um laço de repetição ocioso (delay) antes de encerrar um frame. A contagem desse laço decresce gradualmente conforme a dificuldade (fases vencidas) avança, acelerando a execução do jogo.

### 5. Matemática e Interface Numérica
*   **`Somar_Pontos`**: Adiciona pontuação ao jogador, com trava de segurança em 9999 (máximo de 4 dígitos comportados pela UI).
*   **`Pontuar_Movimento` / `Multiplicar_E_Somar_Pontos`**: Distribuem pontuações ativas. Movimentações dão pontos base, e as multiplicações fornecem bônus de conversão (ex: tempo restante vezes um peso fixo, vidas extras vezes peso) ao completar telas.
*   **`Imprimir_Numero`**: Função robusta que isola as casas decimais (milhar, centena, dezena, unidade) usando loopings de subtração contínua (já que a CPU não possui instruções diretas de divisão/módulo) para plotar números inteiros no formato texto na tela.
*   **`Imprimestr`**: Recebe um ponteiro e imprime uma string finalizada com null-terminator (`\0`) no endereço de tela desejado.

### 6. Gerenciamento de Estado (Telas e Menus)
*   **`LOBBY`**: Tela principal / menu de inicialização do jogo. Aguarda o input para resetar variáveis gerais de partida (vidas, fases, modos, atrasos) e iniciar uma jogada.
*   **`TELA_CHECKIN`**: Uma área de transição após concluir a fase 1 ou 2. Permite ao jogador "Continuar" para a próxima etapa (aumentando a velocidade e ativando a pista 9 surpresa) ou "Morcegar", o que salva o progresso lógico de conquistas e volta ao menu principal.
*   **`TELA_VITORIA_FINAL`**: Acionada ao finalizar a fase 3. Traz a narrativa extra da fúria do "Simões" pela perda do chip e convida o jogador a iniciar a campanha extra do modo reverso.
*   **`TELA_REVERSO_FIM`**: A verdadeira conclusão do jogo. Tela acionada apenas após coletar o chip na jornada de volta e devolvê-lo, acalmando o Simões e parabenizando definitivamente o jogador.
