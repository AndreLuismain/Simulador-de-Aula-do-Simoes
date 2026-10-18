# Código-Fonte do Simulador Gráfico C++ (`simulador_fonte`)

Este diretório contém o código-fonte em **C++** com interface gráfica **GTK+ 2.0** do simulador oficial do **Processador ICMC**, estruturado segundo o padrão arquitetural **MVC (Model-View-Controller)**.

---

## 🗂️ Mapeamento dos Arquivos-Fonte

| Arquivo | Camada MVC | Responsabilidade Técnica |
|---|---|---|
| **[`Model.cpp`](./Model.cpp)** / **[`Model.h`](./Model.h)** | **Model** | Emula o caminho de dados (*datapath*) da CPU de 16 bits: banco de 8 registradores (`r0`–`r7`), `PC` (*Program Counter*), `SP` (*Stack Pointer*), `IR` (*Instruction Register*), `FR` (*Flag Register* de 16 bits), memória RAM de $32\text{K} \times 16\text{ bits}$ (`32768` palavras) e ciclo *Fetch-Decode-Execute*. |
| **[`View.cpp`](./View.cpp)** / **[`View.h`](./View.h)** | **View** | Renderiza a janela gráfica em GTK+, o monitor de vídeo ($40 \times 30$ células com glifos $8 \times 8$ do `charmap.mif`), os painéis de inspeção de registradores/flags e o desmontador (*disassembler*) de instruções em tempo real. |
| **[`Controller.cpp`](./Controller.cpp)** / **[`Controller.h`](./Controller.h)** | **Controller** | Gerencia eventos de teclado (`inchar`), botões de controle de clock (execução passo a passo vs. contínua), *reset* de hardware e carregamento de arquivos `.mif`. |
| **[`Instrucoes.h`](./Instrucoes.h)** / **[`Mneumonicos.h`](./Mneumonicos.h)** | **ISA Specs** | Definição das constantes binárias de *opcodes* (manipulação de dados, ULA aritmética/lógica, desvio condicional/incondicional, pilha e E/S). |
| **[`Registradores.h`](./Registradores.h)** / **[`Video.h`](./Video.h)** | **Hardware Specs** | Mapeamento de bits do registrador de flags (`OVERFLOW`, `CARRY`, `ZERO`, `EQUAL`, `LESSER`, `GREATER`) e estrutura da memória de vídeo. |
| **[`main.cpp`](./main.cpp)** | **Bootstrap** | Inicializa o loop de eventos GTK+ e conecta as instâncias de `Model`, `View` e `Controller`. |

---

## 🛠️ Como Compilar

Em ambiente Linux (com `libgtk2.0-dev` instalado):
```bash
sh compila.sh
```
Em ambiente Windows (via MinGW / Makefile.win):
```powershell
mingw32-make -f Makefile.win
```
