# .include "tokens.s"
.include "tools.s"

.nolist

delimeter = 0x20

# make single string from stack. RESULT link to str in RSI
# put quantity of args to RCX
.macro PASTE_TOGETHER_ARGS
    MOV     $input_str, %RDI
    1:
        TEST    %RCX, %RCX  # if RCX == 0
        JZ      1f
        DEC     %RCX
        POP     %RSI
        CALL    copy_str
        MOV     $delimeter, %AL
        STOSB
        JMP     1b
    1:
    MOV     $0, %AL
    DEC     %RDI
    STOSB
    MOV     $input_str, %RSI
.endm

.macro  SAVE_VAR dest, reg
    PUSH    %RAX
    MOV     \dest, %RAX
    MOV     \reg, (%RAX)
    POP     %RAX
.endm

.macro  LOAD_VAR dest, reg
    PUSH    %RAX
    MOV     \dest, %RAX
    MOV     (%RAX), \reg
    POP     %RAX
.endm

.list

# put input string to RSI
# RETURN link to result str in %RDI
sort_station:
    XOR     %RCX, %RCX
    __sort_begin:
        PUSH    %RCX  # operations in the stack
        CALL    read_token  # RDX type, RAX success, RDI link2str
        POP     %RCX
        CMP     $1, %RAX  # if not success
        JNE     2f
            CMP     $0, %RCX # if(RCX != 0) stack not empty
            JE     3f
                DIE error_msg="Bad expression" exit_code=10
            3:
            RET
        2:
        CMP     $tkn_number, %RDX  # if number
        JNE     2f
            SAVE_VAR    $pos1 %RSI  # need copy number to out
            MOV     %RDI, %RSI
            LOAD_VAR    $pos2 %RDI

            CALL    copy_str
            MOV     $delimeter, %AL
            STOSB

            SAVE_VAR    $pos2 %RDI
            LOAD_VAR    $pos1 %RSI
            JMP     __sort_begin
        2:  # if not number
        CMP     $tkn_open_br, %RDX
        JNE     2f
            PUSH    %RDX
            INC     %RCX
            JMP     __sort_begin
        2:
        CMP     $tkn_clos_br, %RDX
        JNE     2f
            # TODO Open bracket
            JMP     __sort_begin
        2:
        # TODO Binary operation
        JMP     __sort_begin


get_oper_prior:
    CMP     $tkn_plus, %RAX
    JNE     2f
        MOV     $1, %RAX
        JMP     1f
    2:
    CMP     $tkn_minus, %RAX
    JNE     2f
        MOV     $1, %RAX
        JMP     1f
    2:
    CMP     $tkn_mult, %RAX
    JNE     2f
        MOV     $10, %RAX
        JMP     1f
    2:
    CMP     $tkn_div, %RAX
    JNE     2f
        MOV     $10, %RAX
        JMP     1f
    2:
    DIE error_msg="Unknown operation token got" exit_code=16
    1:
    RET


copy_str:
    LODSB
    TEST    %AL, %AL
    JZ      1f
    STOSB
    JMP     copy_str
    1:
    RET


.data
    input_str:  .fill  1024, 1
    output_str: .fill  2048, 1
    pos1:  .quad 0
    pos2:  .quad 0
