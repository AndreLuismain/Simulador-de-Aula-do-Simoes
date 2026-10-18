# Ambiente de Montagem e Simulação — Processador ICMC (`Simulador/`)

Este diretório contém o pacote de ferramentas de montagem (`montador.exe`) e simulação gráfica (`simulador.exe` em GTK+/C++) do **Processador Didático de 16 bits do ICMC-USP**, além de manuais de arquitetura e códigos de referência em Assembly.

---

## 🧭 Índice de Subpastas e Artefatos

| Caminho | Descrição Técnica |
|---|---|
| **[`JOGO.asm`](./JOGO.asm)** / **[`JOGO.mif`](./JOGO.mif)** | Cópia pronta do jogo principal (*Simulador de Aula do Simões*) configurada para montagem e execução direta via atalho `F7`. |
| **[`Hello4.asm`](./Hello4.asm)** / **[`Hello4.mif`](./Hello4.mif)** | Programa de validação rápida de saída de vídeo (`outchar`), laços de repetição e subrotinas com pilha (`push`/`pop`). |
| **[`charmap.mif`](./charmap.mif)** | Memória de caracteres bitmap $8 \times 8$ customizada com os glifos e sprites do jogo. |
| **[`Versao_05_2013/Exemplos/`](./Versao_05_2013/Exemplos/)** | Catálogo de algoritmos fundamentais em Assembly ICMC (`Hello.asm`, `fatorial.asm`, `pacman.asm`, `printaASCII.asm`, `printCharmap.asm`, `printnr.asm`). |
| **[`Versao_05_2013/simulador_fonte/`](./Versao_05_2013/simulador_fonte/)** | Código-fonte em **C++ (arquitetura MVC)** do simulador gráfico (`Model.cpp`, `View.cpp`, `Controller.cpp`, `Registradores.h`, `Instrucoes.h`). |
| **[`Versao_05_2013/Manual/`](./Versao_05_2013/Manual/)** | Especificação da ISA do Processador ICMC (`reference_guide_icmc_processor_v_1_0_r_2.pdf`), manual do simulador e guia de sintaxe do montador. |

---

## 🚀 Como Montar e Executar um Programa `.asm` via Linha de Comando

No terminal, a partir deste diretório (`Simulador/`):

```powershell
# 1. Montar o código Assembly (.asm) gerando a imagem de memória (.mif)
.\montador.exe JOGO.asm JOGO.mif

# 2. Executar o simulador gráfico carregando a ROM gerada e o mapa de caracteres
.\Versao_05_2013\32_bits\simulador.exe JOGO.mif charmap.mif
```
