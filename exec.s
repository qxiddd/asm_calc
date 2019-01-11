.globl _start

.include "tools.s"
.include "nums.s"
.include "str.s"
.include "tokens.s"

.data
    result:     .fill 128, 1
    endl:       .byte 10, 0

.text
_start:
    POP     %RCX
    POP     %RSI
    DEC     %RCX
    PASTE_TOGETHER_ARGS
    CALL    sort_station
    CALL    calculate

    MOV     $result, %RDI
    CALL    int2str

    MOV     $result, %RSI
    CALL    print_str
    MOV     $endl, %RSI
    CALL    print_str

    CALL    exit
