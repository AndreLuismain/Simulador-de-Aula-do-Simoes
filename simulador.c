#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <math.h>
#include <unistd.h>
#include <string.h> // Adicionado para resolver os avisos de strstr e strchr

#ifdef _WIN32
    #include <conio.h>
#else
    #include <termios.h>
#endif

#define TAMANHO_PALAVRA 16
#define TAMANHO_MEMORIA 32768
#define MAX_VAL 65535

// Estados do Processador
#define STATE_RESET 0
#define STATE_FETCH 1
#define STATE_DECODE 2
#define STATE_EXECUTE 3
#define STATE_EXECUTE2 4
#define STATE_HALTED 5

// Seleção do Mux1 (Endereço de Memória) - RENOMEADO PARA EVITAR CONFLITO
#define sPC 0
#define sMAR 1
#define sM4_M1 2
#define sSP_M1 3

// Seleção do Mux2 (Entrada dos Registradores) - RENOMEADO PARA EVITAR CONFLITO
#define sULA 0
#define sDATA_OUT 1
#define sM4_M2 2
#define sTECLADO 4
#define sSP_M2 5

// Seleção do Mux5 (Dados para Memória)
#define sPC_MUX5 0
#define sM3 1

// Seleção do Mux6 (Flags)
#define sULA_FR 0
#define sDATA_OUT_FR 1

// Opcodes
#define LOAD 48
#define STORE 49
#define LOADN 56
#define LOADI 60
#define STOREI 61
#define MOV 51
#define OUTCHAR 50
#define INCHAR 53
#define ADD 32
#define SUB 33
#define MULT 34
#define DIV 35
#define INC 36
#define LMOD 37
#define SQR 57
#define LAND 18
#define LOR 19
#define LXOR 20
#define LNOT 21
#define SHIFT 16
#define CMP 22
#define JMP 2
#define CALL 3
#define RTS 4
#define PUSH 5
#define POP 6
#define NOP 0
#define HALT 15
#define SETC 8
#define BREAKP 14

// Flags
#define NEGATIVE 9
#define STACK_UNDERFLOW 8
#define STACK_OVERFLOW 7
#define DIV_BY_ZERO 6
#define ARITHMETIC_OVERFLOW 5
#define CARRY 4
#define ZERO 3
#define EQUAL 2
#define LESSER 1
#define GREATER 0

unsigned int MEMORY[TAMANHO_MEMORIA];
int reg[8];
int FR[16] = {0};

typedef struct {
    unsigned int result;
    unsigned int auxFR;
} ResultadoUla;

void le_arquivo(void);
int processa_linha(char* linha);
int pega_pedaco(int ir, int a, int b);
ResultadoUla ULA(unsigned int x, unsigned int y, unsigned int OP, int carry);

int my_kbhit(void) {
#ifdef _WIN32
    return _kbhit();
#else
    struct termios oldt, newt;
    int ch, oldf;
    tcgetattr(STDIN_FILENO, &oldt);
    newt = oldt;
    newt.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &newt);
    oldf = fcntl(STDIN_FILENO, F_GETFL, 0);
    fcntl(STDIN_FILENO, F_SETFL, oldf | O_NONBLOCK);
    ch = getchar();
    tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
    fcntl(STDIN_FILENO, F_SETFL, oldf);
    if(ch != EOF) { ungetc(ch, stdin); return 1; }
    return 0;
#endif
}

int main() {
    int i, PC=0, IR=0, SP=0, MAR=0, rx, ry, rz, opcode, temp;
    int LoadPC=0, IncPC=0, LoadIR=0, LoadSP=0, IncSP=0, DecSP=0, LoadMAR=0, LoadFR=0, RW=0;
    int selM1=0, selM2=0, selM3=0, selM4=0, selM5=0, selM6=0;
    int LoadReg[8] = {0};
    int DATA_OUT, M1, M2, M3, M4, M5, M6, OP, carry, TECLADO;
    unsigned char state = STATE_RESET;
    ResultadoUla resUla;

    le_arquivo();
    printf("Simulador ICMC iniciado (Lendo JOGO.mif). 'r' para reset, 'q' para sair.\n");

    while(1) {
        if(LoadIR) IR = DATA_OUT;
        if(LoadPC) PC = DATA_OUT;
        if(IncPC) PC++;
        if(LoadMAR) MAR = DATA_OUT;
        if(LoadSP) SP = M4;
        if(IncSP) SP++;
        if(DecSP) SP--;
        if(LoadFR) for(i=0; i<16; i++) FR[i] = (M6 >> i) & 1;

        rx = pega_pedaco(IR, 9, 7);
        ry = pega_pedaco(IR, 6, 4);
        rz = pega_pedaco(IR, 3, 1);

        if(LoadReg[rx]) reg[rx] = M2;
        if(RW) MEMORY[M1 % TAMANHO_MEMORIA] = M5;

        for(i=0; i<8; i++) LoadReg[i] = 0;
        RW=LoadIR=LoadMAR=LoadPC=IncPC=LoadSP=IncSP=DecSP=LoadFR=0;

        switch(state) {
            case STATE_RESET:
                for(i=0; i<8; i++) reg[i] = 0;
                for(i=0; i<16; i++) FR[i] = 0;
                PC = 0; IR = 0; MAR = 0; SP = TAMANHO_MEMORIA - 1;
                state = STATE_FETCH;
                break;

            case STATE_FETCH:
                selM1 = sPC; LoadIR = 1; IncPC = 1;
                state = STATE_DECODE;
                break;

            case STATE_DECODE:
                opcode = pega_pedaco(IR, 15, 10);
                switch(opcode) {
                    case LOADN: selM1 = sPC; selM2 = sDATA_OUT; LoadReg[rx] = 1; IncPC = 1; state = STATE_FETCH; break;
                    case LOAD:  selM1 = sPC; LoadMAR = 1; IncPC = 1; state = STATE_EXECUTE; break;
                    case STORE: selM1 = sPC; LoadMAR = 1; IncPC = 1; state = STATE_EXECUTE; break;
                    case LOADI: selM4 = ry; selM1 = sM4_M1; selM2 = sDATA_OUT; LoadReg[rx] = 1; state = STATE_FETCH; break;
                    case STOREI: selM4 = rx; selM1 = sM4_M1; selM3 = ry; selM5 = sM3; RW = 1; state = STATE_FETCH; break;
                    case MOV:   selM4 = ry; selM2 = sM4_M2; LoadReg[rx] = 1; state = STATE_FETCH; break;
                    case OUTCHAR: printf("%c", reg[rx]); fflush(stdout); state = STATE_FETCH; break;
                    case INCHAR: 
                        if(my_kbhit()) TECLADO = getchar(); else TECLADO = 255;
                        M2 = TECLADO & 0xFF; LoadReg[rx] = 1; state = STATE_FETCH; break;
                    case ADD: case SUB: case MULT: case DIV: case LMOD: case LAND: case LOR: case LXOR: case LNOT:
                        selM3 = ry; selM4 = rz; OP = opcode; carry = pega_pedaco(IR, 0, 0);
                        selM2 = sULA; LoadReg[rx] = 1; selM6 = sULA_FR; LoadFR = 1; state = STATE_FETCH; break;
                    case INC:
                        selM3 = rx; selM4 = 8; OP = (pega_pedaco(IR, 6, 6) == 0) ? ADD : SUB;
                        selM2 = sULA; LoadReg[rx] = 1; selM6 = sULA_FR; LoadFR = 1; state = STATE_FETCH; break;
                    case SQR:
                        selM3 = rx; selM4 = rx; OP = MULT; selM2 = sULA; LoadReg[rx] = 1; state = STATE_FETCH; break;
                    case CMP:
                        selM3 = rx; selM4 = ry; OP = CMP; selM6 = sULA_FR; LoadFR = 1; state = STATE_FETCH; break;
                    case JMP:
                        temp = pega_pedaco(IR, 9, 6);
                        int cond = 0;
                        if(temp==0 || (temp==7 && FR[GREATER]) || (temp==8 && FR[LESSER]) || (temp==1 && FR[EQUAL]) || (temp==2 && !FR[EQUAL]) || (temp==3 && FR[ZERO])) cond = 1;
                        if(cond) { selM1 = sPC; LoadPC = 1; } else IncPC = 1;
                        state = STATE_FETCH; break;
                    case PUSH: selM1 = sSP_M1; selM3 = rx; selM5 = sM3; RW = 1; DecSP = 1; state = STATE_FETCH; break;
                    case POP:  IncSP = 1; state = STATE_EXECUTE; break;
                    case CALL: 
                        temp = pega_pedaco(IR, 9, 6);
                        if(temp==0 || (temp==1 && FR[EQUAL])) {
                            selM1 = sSP_M1; selM5 = sPC_MUX5; RW = 1; DecSP = 1; state = STATE_EXECUTE;
                        } else { IncPC = 1; state = STATE_FETCH; }
                        break;
                    case RTS: IncSP = 1; state = STATE_EXECUTE; break;
                    case HALT: state = STATE_HALTED; break;
                    case NOP: state = STATE_FETCH; break;
                    default: state = STATE_FETCH; break;
                }
                break;

            case STATE_EXECUTE:
                opcode = pega_pedaco(IR, 15, 10);
                if(opcode == LOAD) { selM1 = sMAR; selM2 = sDATA_OUT; LoadReg[rx] = 1; state = STATE_FETCH; }
                else if(opcode == STORE) { selM1 = sMAR; selM3 = rx; selM5 = sM3; RW = 1; state = STATE_FETCH; }
                else if(opcode == POP) { selM1 = sSP_M1; selM2 = sDATA_OUT; LoadReg[rx] = 1; state = STATE_FETCH; }
                else if(opcode == CALL) { selM1 = sPC; LoadPC = 1; state = STATE_FETCH; }
                else if(opcode == RTS) { selM1 = sSP_M1; LoadPC = 1; state = STATE_EXECUTE2; }
                break;

            case STATE_EXECUTE2:
                IncPC = 1; state = STATE_FETCH;
                break;

            case STATE_HALTED:
                temp = getchar();
                if(temp == 'r') state = STATE_RESET;
                if(temp == 'q') exit(0);
                break;
        }

        if(selM4 == 8) M4 = 1; 
        else if(state == STATE_DECODE || state == STATE_EXECUTE) {
            if(selM1 == sM4_M1 || selM2 == sM4_M2) M4 = reg[pega_pedaco(IR, 6, 4)];
            else M4 = reg[pega_pedaco(IR, 3, 1)];
        } else M4 = 0;

        if(selM1 == sPC) M1 = PC; 
        else if(selM1 == sMAR) M1 = MAR; 
        else if(selM1 == sSP_M1) M1 = SP; 
        else M1 = M4;
        
        DATA_OUT = MEMORY[M1 % TAMANHO_MEMORIA];
        
        temp = 0; for(i=0; i<16; i++) temp |= (FR[i] << i);
        if(selM3 == 8) M3 = temp; else M3 = reg[rx];

        resUla = ULA(M3, M4, OP, carry);

        if(selM2 == sULA) M2 = resUla.result; 
        else if(selM2 == sDATA_OUT) M2 = DATA_OUT; 
        else if(selM2 == sSP_M2) M2 = SP;
        else M2 = M4;

        if(selM5 == sPC_MUX5) M5 = PC; else M5 = M3;
        if(selM6 == sULA_FR) M6 = resUla.auxFR; else M6 = DATA_OUT;
    }
    return 0;
}

ResultadoUla ULA(unsigned int x, unsigned int y, unsigned int OP, int carry) {
    ResultadoUla res = {0, 0};
    unsigned long long temp = 0;
    int flags[16] = {0};

    switch(OP) {
        case ADD: temp = (unsigned long long)x + y + (carry ? FR[CARRY] : 0); res.result = temp & 0xFFFF; if(temp > 0xFFFF) flags[CARRY] = 1; break;
        case SUB: temp = (unsigned long long)x - y; res.result = temp & 0xFFFF; if(x < y) flags[NEGATIVE] = 1; break;
        case MULT: temp = (unsigned long long)x * y; res.result = temp & 0xFFFF; if(temp > 0xFFFF) flags[ARITHMETIC_OVERFLOW] = 1; break;
        case DIV: if(y != 0) res.result = x / y; else flags[DIV_BY_ZERO] = 1; break;
        case LAND: res.result = x & y; break;
        case LOR:  res.result = x | y; break;
        case LXOR: res.result = x ^ y; break;
        case LNOT: res.result = ~x & 0xFFFF; break;
        case CMP: 
            if(x > y) flags[GREATER] = 1;
            else if(x < y) flags[LESSER] = 1;
            else flags[EQUAL] = 1;
            res.result = x;
            break;
    }

    if(res.result == 0) flags[ZERO] = 1;
    for(int i=0; i<16; i++) res.auxFR |= (flags[i] << i);
    return res;
}

void le_arquivo(void) {
    // ALTERADO PARA LER JOGO.mif DIRETAMENTE
    FILE *f = fopen("JOGO.mif", "r");
    if(!f) { printf("Erro: JOGO.mif nao encontrado na pasta!\n"); exit(1); }
    char linha[128];
    int addr = 0, processando = 0;
    while(fgets(linha, sizeof(linha), f)) {
        if(strstr(linha, "CONTENT BEGIN")) { processando = 1; continue; }
        if(strstr(linha, "END;")) break;
        if(processando && strchr(linha, ':')) {
            MEMORY[addr++] = processa_linha(linha);
        }
    }
    fclose(f);
}

int processa_linha(char* linha) {
    char *p = strchr(linha, ':');
    if(!p) return 0;
    p++;
    while(*p == ' ' || *p == '\t') p++;
    int val = 0;
    for(int i=0; i<16; i++) {
        if(p[i] == '1') val |= (1 << (15-i));
    }
    return val;
}

int pega_pedaco(int ir, int a, int b) {
    int mask = (1 << (a - b + 1)) - 1;
    return (ir >> b) & mask;
}