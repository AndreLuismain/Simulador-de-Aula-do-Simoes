# Simulador de Aula do Simões

Um jogo estilo *Frogger*, escrito em Assembly para o processador didático do ICMC-USP (disciplina de Arquitetura de Computadores, sob orientação do Prof. Eduardo do Valle Simões). O jogador atravessa uma avenida cheia de obstáculos para conseguir chegar à aula — e, se demorar demais, pode até ter que voltar atrás para resolver um probleminha com o professor.

Developed by [André Luís](https://github.com/AndreLuismain); [João Vitor](https://github.com/webjotah); [Viniccius Faria](https://github.com/vinicciusfaria); [Yuri Oba](https://github.com/yurioba)


## Arquivos do projeto

| Arquivo | Conteúdo |
|---|---|
| `JOGO.asm` | Todo o código-fonte em Assembly do processador ICMC |
| `charmap.mif` | Fonte de caracteres 8x8 (bitmap) usada para desenhar todos os sprites do jogo |

## A história

Você é um aluno tentando chegar na aula do Simões. O caminho passa por três fases temáticas, cada uma mais perigosa que a anterior. Se você chegar até o fim sem se atrasar... só que perdeu o chip do professor pelo caminho, e agora o Simões está bravo. Você decide se vai voltar atrás pra procurar o chip ou se vai deixar pra lá.

## Como jogar

**Controles (WASD):**
- `W` — anda para cima (em direção ao objetivo, na maior parte do jogo)
- `S` — anda para baixo
- `A` — anda para a esquerda
- `D` — anda para a direita
- Qualquer tecla — avança em telas de espera (lobby, mensagens)
- `C` / `M` — nas telas de check-in, continuar ou "morcegar" (desistir da tentativa)
- `S` / `ESC` — na tela final, voltar procurando o chip ou ignorar

**Objetivo:** atravessar a avenida (de baixo pra cima) sem ser atropelado, evitando os obstáculos de cada pista, até chegar à linha de chegada no topo da tela.

## As 3 fases

O jogo tem três fases temáticas, cada uma com uma placa diferente na linha de chegada:

1. **Fase 1 — USP:** cenário de rua comum, carros e ônibus tradicionais atravessando as pistas.
2. **Fase 2 — ICMC:** mistura de carros, motos e um grupo de alunos atravessando junto — o cenário começa a "entrar" no campus.
3. **Fase 3 — SIMOES:** só alunos como obstáculo (parados, correndo, ou carregando cadeiras), e o horizonte de prédios dá lugar a um visual de pátio aberto de campus.

A cada fase vencida, o jogo fica mais rápido (o atraso entre quadros diminui até um piso mínimo, pra nunca ficar impossível de jogar) e uma pista extra é liberada a partir da fase 2 — um carro isolado que pode vir tanto da esquerda quanto da direita, sorteado aleatoriamente a cada rodada.

## Vidas e game over

Você começa com **3 vidas** (mostradas como corações no canto superior esquerdo). Ao ser atingido por um obstáculo, o personagem pisca no lugar do impacto, perde uma vida e volta para o início da travessia atual — sem perder o progresso de fase. Se as vidas acabarem, ou se o tempo se esgotar, é fim de jogo: uma mensagem de derrota aparece e o jogo volta para o lobby.

## Cronômetro

Um cronômetro no canto superior direito conta o tempo restante, piscando de cor a cada segundo (segundos ímpares em branco, pares em vermelho). Ele começa em 1 minuto e só é reiniciado — com um bônus de 3 minutos — quando você chega ao fim da fase 3. Se o tempo zerar, é tratado como se você tivesse sido atropelado.

> **Nota técnica:** como o processador não tem um relógio de hardware de verdade, "1 segundo" é aproximado contando quadros do jogo. A precisão varia levemente conforme a velocidade do jogo aumenta a cada fase.

## Pontuação

Um contador de pontos aparece no canto inferior direito. Você ganha pontos por:

- **+10** a cada passo bem-sucedido na direção do objetivo (andar de lado ou para trás não pontua)
- **+20** ao alcançar o passeio/grama do meio da avenida
- **+50** ao avançar para a próxima fase
- **+10** por cada segundo restante no cronômetro, ao chegar à linha de chegada
- **+50** por cada vida extra (além da primeira) que você ainda tiver ao concluir a fase

## Check-in entre fases

Ao vencer a fase 1 ou a fase 2, o jogo pergunta se você quer **continuar** (`C`, avança para a próxima fase) ou **"morcegar"** (`M`, desiste da tentativa e volta para o lobby, mas mantém visível quantas fases você já venceu, no formato X/3, indicado também por um quadradinho no canto inferior esquerdo durante o jogo).

## O chip perdido (modo reverso)

Ao vencer a fase 3, o jogo revela que você perdeu o chip do Professor Simões pelo caminho. Você escolhe:

- **`S` — voltar procurando:** o jogo entra em modo reverso. Você recomeça na linha de chegada e precisa voltar pelas 3 fases na ordem contrária (SIMOES → ICMC → USP). Em algum ponto do caminho, um pequeno chip colecionável aparece em uma posição aleatória do mapa (pode estar em qualquer pista, no passeio, na grama ou na linha de chegada), sinalizado por uma placa piscante "CHIP DO SIMOES ->". Ao encontrá-lo, o objetivo muda: agora você precisa voltar até a linha de chegada para entregá-lo ao professor. Conseguir isso mostra a tela de conclusão "o Simões está em paz".
- **`ESC` — ignorar:** encerra o ciclo por ali mesmo e volta para o lobby.

## Lobby

Tela inicial com o nome do jogo. Mostra também o progresso (X/3 fases vencidas) se você tiver voltado de um "morcegar" antes. Qualquer tecla começa uma nova partida do zero.

## Notas técnicas e suposições assumidas

Este projeto foi desenvolvido de forma incremental, sessão após sessão, sobre um processador didático customizado sem instruções de multiplicação, divisão ou geração de números aleatórios — vários mecanismos precisaram ser construídos "na mão":

- **Números decimais na tela** (pontuação e cronômetro) são calculados por subtração repetida, já que não existe instrução de divisão.
- **Aleatoriedade** (direção da pista extra, posição do chip, tema sorteado) usa um contador que cresce sozinho a cada quadro do jogo como "semente", já que não existe gerador de números aleatórios.
- **A tecla ESC** é assumida como o código ASCII padrão (27). Se o simulador usado enviar um código diferente para essa tecla, basta ajustar essa constante no código (está comentada no ponto exato onde é usada).
- Todas as pistas de carro, o corpo do jogador, as janelas de ônibus e outros elementos visuais foram desenhados a partir de glifos 8x8 redefinidos no `charmap.mif` — nenhuma letra usada nos textos do jogo foi sobrescrita por um sprite (isso já rendeu alguns bugs corrigidos ao longo do desenvolvimento).


## Como baixar o compilador para programação em Assembly

Precisará usar um simulador para desenvolver e rodar programas em linguagem Assembly que poderá ser encontrado para Windows, Linux e MacOS em: 
[Processador-ICMC](https://github.com/simoesusp/Processador-ICMC/blob/master/Install_Packages/)
Para Windows, fiz um link super fácil de instalar: 
[Link Facilitado para Windows](https://github.com/simoesusp/Processador-ICMC/blob/master/Install_Packages/Simulador_Windows_Tudo_Pronto_F%C3%A1cil%20(1).zip)

Esse zip já vem inclusive com o sublime configurado para escrever o software (incluindo a sintaxe highlight) e o montador e o simulador já configurado para ser chamado com a tecla **F7**
- Para instalar basta fazer o download na area de trabalho ou na pasta Documentos
- Entrar na pasta ..\Simulador\Sublime Text 3
- Executar o sublime: "sublime_text.exe"
- Se ele pedir, **NÃ0 FAÇA O UPDATE !!!!!!!!!!!!!!!**
- Vá em File - Open File e volte uma pasta para ..\Simulador\
- Abra o sw em Assembly chamado Hello4.ASM
- Teste se está tudo funcionando chamando o MONTADOR e o SIMULADOR com a tecla F7
- Apartir daí pode-se salvar o sw com outro nome e fazer novos programas
- Apenas preste atenção para estar na pasta ..\Simulador\
- Se der o erro: [Decode error - output not utf-8] é porque você não está na pasta ..\Simulador\
... Ou basta mudar o formato para utf-8 e salvar...
