# TOKEN TYPES ------------
    tkn_plus  = 0x2B
    tkn_minus = 0x2D
    tkn_mult  = 0x2A
    tkn_div   = 0x2F

    tkn_zero   = 0x30
    tkn_nine   = 0x39
    tkn_number = 0x31

    tkn_open_br = 0x28
    tkn_clos_br = 0x29

    tkn_space = 0x20
# ------------------------

.data
token_buffer: .fill 128, 1
buff_len = . - token_buffer


.nolist
# true_br and false_br are labels.
# if AL is digit go to true_br
# else go to false_br
.macro  IS_AL_DIGIT true_br false_br
    CMP     $tkn_zero, %AL  # if (AL >= 0x30)
    JL      \false_br
    CMP     $tkn_nine, %AL  # if (AL <= 0x39)
    JG      \false_br
    JMP     \true_br
.endm
.list


.text
_clear_buffer:
    MOV     $buff_len, %RCX
    XOR     %AL, %AL
    MOV     $token_buffer, %RDI
    REP STOSB
    RET


# Read token from string (RSI). Increases RSI till current token
#   ends.
# RETURN link to string with token in RDI
#        token type in RDX
#        success flag in RAX (0 if success)
read_token:
    CALL    _clear_buffer
    MOV     $token_buffer, %RDI
    __read:
        LODSB
        CMP     $tkn_space, %AL             # SPACE
        JNE     1f
            JMP __read
        1:
        CMP     $tkn_open_br, %AL           # OPEN BRACKET
        JNE     1f
            MOV     $tkn_open_br, %RDX
            JMP     __ret_simple_tkn
        1:
        CMP     $tkn_clos_br, %AL           # CLOSE BRACKET
        JNE     1f
            MOV     $tkn_clos_br, %RDX
            JMP     __ret_simple_tkn
        1:
        CMP     $tkn_mult, %AL              # MUTLIPLICATION
        JNE     1f
            MOV     $tkn_mult, %RDX
            JMP     __ret_simple_tkn
        1:
        CMP     $tkn_div, %AL               # DIVIDE
        JNE     1f
            MOV     $tkn_div, %RDX
            JMP     __ret_simple_tkn
        1:
        CMP     $tkn_plus, %AL              # PLUS
        JNE     1f
            MOV     $tkn_plus, %RDX
            JMP     __ret_simple_tkn
        1:
        CMP     $tkn_minus, %AL             # MINUS
        JNE     1f
            MOV     $tkn_minus, %RDX
            JMP     __ret_simple_tkn
        1:
        IS_AL_DIGIT __ret_number 1f         # NUMBER
        1:
        JMP     __not_success

    __not_success:
    MOV     $1, %RAX
    RET

    __ret_simple_tkn:
    STOSB
    MOV     $token_buffer, %RDI
    MOV     $0, %RAX
    RET
    
    __ret_number:
    1:
        STOSB
        LODSB
        IS_AL_DIGIT 1b 1f
    1:
    DEC     %RSI
    MOV     $0, %RAX
    MOV     $tkn_number, %RDX
    MOV     $token_buffer, %RDI
    RET
