.globl _start

.include "str.s"
.include "tokens.s"


.text
_start:
    POP     %RCX
    POP     %RSI
    DEC     %RCX
    PASTE_TOGETHER_ARGS
    ja:
        CALL    read_token
        CMP     $1, %RAX
        JNE     ja
    MOV     $5, %RAX
