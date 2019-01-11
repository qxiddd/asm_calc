delimeter = 0x20

.nolist

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
    MOV     $output_str, %RDI
    SAVE_VAR    $pos2 %RDI
    MOV     $output_str, %R8  # For debugging TODO delete me
    MOV     %RSI, %R9         # For debugging
    __sort_begin:
        PUSH    %RCX        # quantity operations in the stack
        CALL    read_token  # return RDX type, RAX success, RDI link2str
        POP     %RCX
        CMP     $1, %RAX  # if not success
        JNE     2f
        case_tkn_failure:
                CMP     $0, %RCX  # while stack not empty
                JE      3f
                POP     %RAX  # current token
                DEC     %RCX
                CMP     $tkn_open_br, %RAX
                JNE     4f
                    DIE error_msg="Wrong expression" exit_code=15
                4:
                LOAD_VAR    $pos2 %RDI
                STOSB
                MOV     $delimeter, %AL
                STOSB
                SAVE_VAR    $pos2 %RDI
                JMP     case_tkn_failure
            3:
            MOV     $output_str, %RDI
            RET
        2:
        CMP     $tkn_number, %RDX  # if number
        JNE     2f
        case_tkn_number:
            SAVE_VAR    $pos1 %RSI  # need copy number to out
            MOV     %RDI, %RSI  # move link2str (result from read_token)
            LOAD_VAR    $pos2 %RDI

            CALL    copy_str
            MOV     $delimeter, %AL
            STOSB

            SAVE_VAR    $pos2 %RDI
            LOAD_VAR    $pos1 %RSI
            JMP     __sort_begin
        2:
        CMP     $tkn_open_br, %RDX
        JNE     2f
        case_tkn_open_br:
            PUSH    %RDX
            INC     %RCX
            JMP     __sort_begin
        2:
        CMP     $tkn_clos_br, %RDX
        JNE     2f
        case_clos_br:
            CMP     $0, %RCX
            JNE     3f
                DIE error_msg="Wrong expression" exit_code=15
            3:
            POP     %RAX
            DEC     %RCX
            CMP     $tkn_open_br, %AL
            JE      __sort_begin   # jump if OpenBr got
            LOAD_VAR    $pos2 %RDI
            STOSB
            MOV     $delimeter, %AL
            STOSB
            SAVE_VAR    $pos2 %RDI
            JMP     case_clos_br
        2:
        case_oper:
            CMP     $0, %RCX  # if stack is empty
            JE      case_oper__continue
            POP     %RAX  # op1 in RDX, op2 in RAX
            DEC     %RCX
            CMP     $tkn_open_br, %RAX
            JNE     3f
                PUSH    %RAX
                INC     %RCX
                JMP     case_oper__continue
            3:
            PUSH    %RAX  # operations tokens are saved, first POP for op1
            PUSH    %RDX
            CALL    get_oper_prior
            MOV     %RAX, %RDI  # prior(op2) in RDI
            MOV     %RDX, %RAX  # prior(op1) in RAX
            CALL    get_oper_prior
            CMP     %RAX, %RDI  # if (op1 <= op2): push op2 to out
            JB      3f
                POP     %RDX
                POP     %RAX
                LOAD_VAR    $pos2 %RDI
                STOSB
                MOV     $delimeter, %AL
                STOSB
                SAVE_VAR    $pos2 %RDI
                JMP     case_oper
            3:
            POP     %RDX
            INC     %RCX
            JMP     case_oper__continue
        case_oper__continue:
            PUSH    %RDX
            INC     %RCX
            JMP     __sort_begin


get_oper_prior:
    CMP     $tkn_plus, %RAX
    JNE     2f
        MOV     $1, %RAX
        JMP     3f
    2:
    CMP     $tkn_minus, %RAX
    JNE     2f
        MOV     $1, %RAX
        JMP     3f
    2:
    CMP     $tkn_mult, %RAX
    JNE     2f
        MOV     $10, %RAX
        JMP     3f
    2:
    CMP     $tkn_div, %RAX
    JNE     2f
        MOV     $10, %RAX
        JMP     3f
    2:
    DIE error_msg="Unknown operation token got" exit_code=16
    3:
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
