# Exemplos de Algoritmos em Assembly ICMC (`Versao_05_2013/Exemplos`)

Coleção de programas didáticos escritos na linguagem **Assembly do Processador ICMC (16 bits)**, demonstrando manipulação direta de registradores (`r0`–`r7`), pilha de hardware (`sp`), memória de vídeo mapeada ($40 \times 30$ células, endereços `0` a `1199`) e chamadas de subrotina (`call`/`rts`).

---

## Catálogo de Códigos-Fonte

| Arquivo | Objetivo do Algoritmo | Conceitos de Arquitetura Aplicados |
|---|---|---|
| **[`Hello.asm`](./Hello.asm)** | Imprime uma string estática alocada manualmente byte a byte (`var #21` + `static`) na memória de vídeo. | Diretivas de alocação (`var`, `static`), endereçamento indireto por registrador (`loadi r2, r1`), E/S de vídeo (`outchar`) e preservação de contexto na pilha (`push`/`pop`). |
| **[`Hello2.asm`](./Hello2.asm)** | Imprime mensagens utilizando a diretiva `.string` do montador e aplica máscara de cores nos caracteres. | Diretiva `string`, codificação de cores nos bits superiores da palavra de 16 bits (soma de offset de cor ao código ASCII). |
| **[`Hello3.asm`](./Hello3.asm)** | Demonstra impressão sequencial de múltiplas strings em coordenadas distintas da tela. | Cálculo de endereço linear de vídeo ($\text{endereço} = \text{linha} \times 40 + \text{coluna}$) e reutilização de subrotina `Imprime`. |
| **[`Hello4.asm`](./Hello4.asm)** | Versão estendida de impressão de strings com controle de posicionamento e cores. | Modularização de subrotinas em Assembly e manipulação de ponteiros em registradores. |
| **[`fatorial.asm`](./fatorial.asm)** | Calcula iterativamente o fatorial de um inteiro ($n!$) em `r0` e converte o resultado binário para dígitos decimais ASCII na tela. | Instruções aritméticas (`mul`, `div`, `sub`, `dec`), desvios condicionais baseados no *Flag Register* (`cmp`, `jgr`) e algoritmo de decomposição posicional (centena, dezena, unidade). |
| **[`printnr.asm`](./printnr.asm)** | Subrotina isolada para impressão de números inteiros de até 3 dígitos (`0`–`999`) em formato decimal ASCII. | Conversão inteiro-para-ASCII (soma de `#48` / `'0'`) e divisão inteira sucessiva por potências de 10. |
| **[`printaASCII.asm`](./printaASCII.asm)** | Renderiza na tela todos os caracteres da tabela ASCII para inspeção visual. | Laço de repetição controlado por contador e mapeamento sequencial na memória de vídeo. |
| **[`printCharmap.asm`](./printCharmap.asm)** | Exibe na tela os glifos customizados carregados a partir do arquivo `charmap.mif`. | Inspeção de memória de caracteres ($8 \times 8$ pixels por glifo) e verificação de sprites. |
| **[`pacman.asm`](./pacman.asm)** | Protótipo de movimentação e animação de sprites na tela utilizando glifos redefinidos. | Loop de animação com atraso por software (*busy-wait delay*), leitura de teclado (`inchar`) e atualização de quadros. |

---

## Como Compilar (Montar) e Executar Qualquer Exemplo

A partir da pasta `Simulador/`:

```powershell
.\montador.exe Versao_05_2013\Exemplos\fatorial.asm Versao_05_2013\Exemplos\fatorial.mif
.\Versao_05_2013\32_bits\simulador.exe Versao_05_2013\Exemplos\fatorial.mif charmap.mif
```
