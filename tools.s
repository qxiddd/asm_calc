.nolist

.macro DIE error_msg="Exception" exit_code=-1
    .data
        1:  .ascii  "\error_msg"
            .ascii "\n"
        _len = . - 1b
    .text
    MOV     $1b, %RSI
    MOV     $_len, %RDX
    CALL    print

    MOV     $\exit_code, %RDI
    CALL    exit
.endm

.list

.text
# put str buffer to RSI
# put it's len to RDX
print:
    MOV     $1, %RAX
    MOV     $1, %RDI
    SYSCALL
    RET

# put link to str to RSI
print_str:
    PUSH    %RSI
    XOR     %RCX, %RCX
    1:
        MOVB    (%RSI), %AL
        INC     %RSI
        CMP     $0, %AL
        JNE     2f
            MOV     %RCX, %RDX
            POP     %RSI
            CALL    print
            RET
        2:
        INC     %RCX
        JMP     1b
    


# put exit_code to RDI
exit:
    MOV     $60, %RAX
    SYSCALL
