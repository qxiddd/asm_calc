.include "tools.s"
.include "nums.s"

.globl _start

.data
    buffer: .ascii "                               "
            .byte 0

.text

_start:
    POP     %RCX
    POP     %RDI
    POP     %RSI
    MOV     $10, %RBX
    CALL    str2int

    CALL    neg_shifted
    MOV     $buffer, %RDI
    CALL    int2str

    MOV     $buffer, %RSI
    CALL    print

    CALL    exit
