
section .rodata
    _linkSize: db 5
    _hexaFormat: db '%x',10,0
    _calcPrompt: db 'calc: ', 0
    _format_string: db "%s", 10, 0	; format string
    _overFlowMsg: db 'Error: Operand Stack Overflow', 10,0
    _underFlowMsg: db 'Error: Insufficient Number of Arguments on Stack', 10, 0

section .bss
    _carry: resb 1
    _operandStack: resd 0xFF
    _topOfStack: resd 1         
    _result: resd 1
    _inputBuffer: resb 80
    _x: resd 1 ;pointer to link
    _y: resd 1
    _char: resb 1
    _next: resd 1
    _curr: resd 1
    _prev: resd 1
    _newHead: resd 1
    _oldHead: resd 1
    _inputLength: resd 1

section .data
    _stackCapacity: dd 5
    _numOperations: dd 0
    _idx: dd 0


section .text
    align 16
    global main
    extern printf
    extern fprintf 
    extern fflush
    extern malloc 
    extern calloc 
    extern free 
    extern getchar 
    extern fgets   

;verified
%macro getUserInput 0
    push _calcPrompt    
    push _format_string 
    call printf 
    add esp, 8

    ;pop eax     ;eax arbitrary choice
    ;clearInputBuffer
    ;read relavent byte code to buffer
    mov edx, 80                 ;edx = numBytes
    mov ecx, _inputBuffer     ;ecx = inputBuffer
    mov ebx, 0          ;ebx = stdin dirent
    mov eax, 3       ;eax = sys_read op code
    int 0x80            ;call the kernel to read numBytes to buffer
%endmacro

;verified - convert char buffer to hexa byte rep
%macro convertAsciiToHexa 0
    mov dword[_idx],0
    %%whileLoop:
        mov ebx,_inputBuffer   ;ebx = address of buffer 
        mov ecx, [_idx]         ;ecx holds value of _idx
        mov eax,0
        mov al,[ebx+ecx]        ;al hold value of char at buffer[idx]
        cmp al, 0
        jz %%endWhileLoop
        cmp al, 10
        jz %%endWhileLoop
        mov byte[_char], al
        cmp byte[_char], 60     ;digits less than 60, letters greater than 60
        jl %%ifDigit
        jmp %%ifLetter

    %%ifDigit:
        sub byte[_char], 48
        jmp %%regardless
        
    %%ifLetter:
        sub byte[_char], 55
        jmp %%regardless
    
    %%regardless:
        mov al, [_char]
        mov ebx, _inputBuffer
        mov byte[ebx+ecx], al
        inc dword[_idx]
        jmp %%whileLoop

    %%endWhileLoop:
        mov eax, [_idx]
        mov dword[_inputLength], eax

%endmacro

;;completed
%macro listify 0
    ;;BASIC IDEA - build the list backwards. buffer[0] will be MSB, last element(link) is the head

    mov dword [_oldHead], 0
    mov dword[_idx], 0
    %%whileLoop: ;while(idx<inputLength)
        ;;check condition
        mov eax, [_idx]
        mov ebx, [_inputLength]
        sub ebx, eax
        cmp ebx, 0
        jge %%endWhileLoop
        ;read val from buffer         
        add eax, _inputBuffer            ;let eax = pointer to buffer[idx]
        mov ecx, 0
        mov cl, [eax]                   ;ecx = 0x000000buffer[idx]
        mov byte [_char],cl            ;let char = buffer[idx]
        ;new head points to old head
        push 1
        push 5
        call calloc ;eax should hold pointer to newly allocated mem
        add esp, 8
        mov dword [_newHead], eax ;eax = pointer to newHead
        mov cl, [_char]             ;cl = currValue
        mov edx, [_newHead]
        mov byte[edx], cl        ;newHead.value = cl = newValue
        mov eax, [_oldHead]          ;eax = pointer to oldHead
        mov dword[edx+1],eax   ;newHead.next = eax = pntr to oldHead
        mov eax, [_newHead]           ;eax = pntr to newHead
        mov dword [_oldHead], eax     ;oldHead = newHead

        jmp %%whileLoop
    
    %%endWhileLoop:
        pushToStack [_newHead]

%endmacro

;stores pointer M[ebx]+M[ecx] in eax
%macro myAdd 0
    ;%1 has x and %2 has y
    popFromStack
    mov _x, _result
    popFromStack
    mov _y, _result
    ;need to finish
    
%endmacro

%macro clearInputBuffer 0

%endmacro

%macro clearInputBuffer 1

%endmacro

%macro pushToStack 1
    ;; %1 is pointer to push
    mov ebx, [_topOfStack]
    add ebx, 4
    mov [_topOfStack],ebx
    mov eax, %1
    mov dword[_topOfStack], eax 
%endmacro

;;pops top element into result register and decrements top of stack
%macro popFromStack 0
    mov eax, [_topOfStack]
    mov dword[_result], eax 
    sub dword[_topOfStack], 4
%endmacro

;;completed
%macro popAndPrint 0
    popFromStack ;popped list is now in result
    mov eax, [_result] ;eax = address of the lists head
    mov dword[_curr],eax ;curr = list.head address
    push 0;
    %%pushWhileLoop:
    ;while(next not null)push value to stack (seperately push last)
    mov eax, [_curr] ;ebx = address of curr
    mov eax, [eax] ;ebx = 0x0curr.value
    cmp al,9
    jle %%ifNumberBase
    jmp %%ifLetterBase

    %%ifNumberBase:
        add al, 48
        jmp %%regardlessBase

    %%ifLetterBase:
        add al, 55
        jmp %%regardlessBase
    
    %%regardlessBase:
        push eax    ;eax should have zero(s) as MSB!
        mov eax, [_curr] ;eax = address of curr
        mov eax,[eax+1] ;eax = address of curr.next
        mov dword [_curr], eax ; curr points to address of curr.next
        ;;now check if next is null
        cmp eax,0 ;check if next's address is NULL
        jnz %%pushWhileLoop
        
    %%printWhileLoop:
        pop eax
        cmp eax, 0          ;check if you popper NULL
        jz %%popAndPrintEnd
        mov [_char], al
        mov edx, 1          ;edx = numBytes to write
        mov ecx, _char      ;ecx = char (buffer)
        mov ebx, 1          ;ebx = stdout
        mov eax, 4          ;eax = sys_write op code
        int 0x80            ;call the kernel to write numBytes to victim
        jmp %%printWhileLoop 
    %%popAndPrintEnd: 
%endmacro

%macro numHexaDigits 0
 
%endmacro


main:
    runloop:

        getUserInput
        mov eax, 0
        mov al, [_inputBuffer]   ;eax = LSByte ;might be [buffer+1] if \n or \0 present
        cmp al, 'q'
        jz endOfProgram

        cmp al, 'p'
        jz calcPrint

        jmp receiveOperand

    calcPrint:
        popAndPrint
        jmp runloop


    receiveOperand:
        convertAsciiToHexa
        listify
        jmp runloop

    endOfProgram:
        mov eax, [_numOperations] 
        

;_init:

