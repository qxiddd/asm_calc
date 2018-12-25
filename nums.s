num_shift = 0x100000000

.include "tokens.s"

.text

# put shifted number to RAX
# put to RDI for output
# RETURN length of str in RDX
int2str:
    CALL    get_abs  # берем модуль числа (RAX) и его знак (RBX)
    XOR     %RDX, %RDX  # length of out string
    CMP     $1, %RBX
    JNE     1f
        INC     %RDX  # add minus to str
        MOV     $tkn_minus, %RBX
        MOV     %RBX, (%RDI)
        INC     %RDI
    1:
    XOR     %RCX, %RCX
    MOV     $10, %RBX
    1:  # until RAX != 0
        XOR     %RDX, %RDX  # for correct DIV
        DIV     %RBX
        PUSH    %RDX  # save remainder
        INC     %RCX
        CMP     $0, %RAX
        JNE     1b
    ADD     %RCX, %RDX
    2:  # while RCX != 0
        CMP     $0, %RCX
        JNE     1f
            RET
        1:
        POP     %RAX
        ADD     $0x30, %RAX
        MOV     %RAX, (%RDI)
        INC     %RDI
        DEC     %RCX
        JMP 2b


# put to RSI string with number
# put input numbering base to RBX
# put $1 to RDI if number is negative
# RETURN shifted num in RAX
str2int:
    XOR     %RAX, %RAX  # Result
    1:
        MOVB    (%RSI), %CL  # get digit
        INC     %RSI
        CMP     $0, %RCX  # check end of line
        JE      2f
        SUB     $0x30, %RCX  # convert symbol to num
        MUL     %RBX  # result *= 10
        ADD     %RCX, %RAX  # result += digit
        JMP     1b
    2:
    CALL make_shifted
    RET


# Put absolute value of number to RAX
# put $1 to RDI if number is negative
# RETURN shifted representation of the number
make_shifted:
    MOV     $num_shift, %RDX
    CMP     $1, %RDI
    JNE     1f
        SUB     %RAX, %RDX  # if number is negative
        JMP     2f
    1:
        ADD     %RAX, %RDX  # else
    2:
    MOV     %RDX, %RAX
    RET


# put shifted number to RAX
# RETURN it's sign in RBX
get_sign:
    MOV     $num_shift, %RBX
    CMP     %RBX, %RAX  # check sign
    JNL     1f
        MOV     $1, %RBX
        JMP     2f
    1:
        MOV     $0, %RBX
    2:
    RET


# put shifted number to RAX
# RETURN absoute value of number in RAX (it's sign in RBX)
get_abs:
    PUSH    %RAX
    CALL    get_sign
    CMP     $1, %RBX  # check sign
    JNE     1f
        POP     %RCX  # if sign is minus
        MOV     $num_shift, %RAX
        JMP     2f
    1:
        POP     %RAX  # else
        MOV     $num_shift, %RCX
    2:
    SUB     %RCX, %RAX
    RET


# put shifted number to RAX
# RETURN shifted negatived num
neg_shifted:
    CALL get_abs
    CMP     $1, %RBX  # check sign
    JNE     1f
        MOV     $0, %RDI
        JMP     2f
    1:
        MOV     $1, %RDI
    2:
    CALL    make_shifted
    RET


.nolist
    .macro SPLIT_ARGS_ON_REGISTERS
        PUSH    %RBX  # save second operand in stack
        CALL    get_abs
        POP     %RCX  # get second operand
        PUSH    %RAX  # save abs(first operand)
        PUSH    %RBX  # save sign(first operand)
        MOV     %RCX, %RAX  # second operand to RAX
        CALL    get_abs
        POP     %RCX  # get sign(first operand)
        PUSH    %RAX  # save abs(second operand)
        MOV     %RCX, %RAX  # now (RAX = sign(first operand)) and (RBX = sign(second operand))
        POP     %RCX  # get abs(second operand)
        POP     %RDX  # get abs(first operand)
        PUSH    %RCX  # save abs(second operand)
        PUSH    %RDX  # save abs(first operand)
    .endm
.list


# put two nums into RAX, RBX
# RETURN summ to RAX
add_shifted:
    SPLIT_ARGS_ON_REGISTERS
    CMP     %RAX, %RBX  # Сравниваем знаки
    JNE     1f  # Если совпадают:
        MOV     %RAX, %RDI  # save sign
        POP     %RAX
        POP     %RBX
        ADD     %RBX, %RAX  # суммируем модули операндов
        CALL    make_shifted  # создаем число с известным знаком
        RET  # PROFIT
    1:  # Иначе: делаем так, чтобы число с большим модулем было в RAX, а его знак в RCX
        #      SUB     %RBX, %RAX (вычитаем из большего меньшее)
        #      создаем число с известным знаком
        POP     %RCX  # first operand
        POP     %RDX  # second operand
        CMP     %RDX, %RCX
        JNB     1f
            # if RCX < RDX (первый операнд по модулю меньше второго)
            MOV     %RBX, %RDI  # сохранили знак большего по модулю
            MOV     %RDX, %RAX  
            MOV     %RCX, %RBX
            JMP     2f
        1:  # else
            MOV     %RBX, %RDI  # сохранили знак большего по модулю
            MOV     %RDX, %RAX
            MOV     %RCX, %RBX
        2:
        SUB     %RBX, %RAX
        CALL    make_shifted
        RET  # PROFIT


# put two nums into RAX, RBX
# RETURN (RAX - RBX) to RAX
sub_shifted:
    PUSH    %RAX
    MOV     %RBX, %RAX
    CALL    neg_shifted  # меняем знак у второго аргумента
    MOV     %RAX, %RDX
    POP     %RAX
    JMP     add_shifted


# put two nums into RAX, RBX
# RETURN multiplication to RAX
mul_shifted:
    SPLIT_ARGS_ON_REGISTERS
    CMP     %RAX, %RBX  # Сравниваем знаки
    JNE     1f  # Если совпадают:
        MOV     $0, %RDI  # знак точно будет +
        JMP     2f
    1:  # Если не совпадают
        MOV     $1, %RDI  # знак точно будет -
    2:
    POP     %RAX  #  достаем модуль первого аргумента
    POP     %RBX  #  достаем модуль второго аргумента
    MUL     %RBX
    JNO     1f
        DIE error_msg="Overflow"
    1:
    CALL make_shifted
    RET  # PROFIT


# put two nums into RAX, RBX
# RETURN (RAX / RBX) to RAX
div_shifted:
    SPLIT_ARGS_ON_REGISTERS
    CMP     %RAX, %RBX  # Сравниваем знаки
    JNE     1f  # Если совпадают:
        MOV     $0, %RDI  # знак точно будет +
        JMP     2f
    1:  # Если не совпадают
        MOV     $1, %RDI  # знак точно будет -
    2:
    POP     %RAX  #  достаем модуль первого аргумента
    POP     %RBX  #  достаем модуль второго аргумента
    XOR     %RDX, %RDX
    DIV     %RBX
    CALL make_shifted
    RET  # PROFIT
