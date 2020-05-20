
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
    _inputLength: resd 1

section .data
    _stackCapacity: dd 5
    _numOperations: dd 0
    _idx: dd 0

    struc link
        .value resb 1 ;single hexa digit 0x00-0xFF
        .next resd 1 ;pointer to next
    endstruc

section .text
    align 16
    global _start
    global main
    extern printf
    extern fprintf 
    extern fflush
    extern malloc 
    extern calloc 
    extern free 
    extern getchar 
    extern fgets   

_start:
    runloop:
        push _calcPrompt    ;remove
        push _format_string ; remove
        call printf ;remove
        getUserInput


        mov eax, 0
        mov al, [_inputBuffer]   ;eax = LSByte ;might be [buffer+1] if \n or \0 present
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
        
        

;_init:




;completed
%macro getUserInput 0
    push _calcPrompt
    push _format_string
    call printf
    pop eax     ;eax arbitrary choice
    clearInputBuffer
    ;read relavent byte code to buffer
    mov edx, 80                 ;edx = numBytes
    mov ecx, _inputBuffer     ;ecx = inputBuffer
    mov ebx, 0          ;ebx = stdin dirent
    mov eax, 3       ;eax = sys_read op code
    int 0x80            ;call the kernel to read numBytes to buffer
%endmacro

;completed - convert char buffer to hexa byte rep
%macro convertAsciiToHexa 0
    mov dword[_idx],0
    %%whileLoop:
        mov ebx, inputBuffer   ;ebx = address of buffer 
        mov ecx, [_idx]         ;ecx holds value of _idx
        mov al,[ebx+ecx]        ;al hold value of char at buffer[idx]
        cmp al, 0
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
        mov byte[_inputBuffer+ecx], al
        inc dword[_idx]
        jmp %%whileLoop

    %%endWhileLoop:
        mov eax, [_idx]
        mov dword[_inputLength], eax

%endmacro

;;completed
%macro listify 0
    ;;BASIC IDEA - build the list backwards. buffer[0] will be MSB, last element(link) is the head

    push 1
    push 5
    call calloc ;eax should hold pointer to newly allocated mem
    add esp 8
    ;;might have to move byte by byte
    mov _prev, eax
    pushToStack _prev ;prev is the head and pushed to our stack

    mov dword[_idx], 0
    %%whileLoop: ;while(idx<inputLength)
        ;;check condition
        mov eax, [_idx]
        mov ebx, [_inputLength]
        sub ebx, eax
        cmp ebx, 0
        jge %%endWhileLoop
        ;read val from buffer
        mov eax, [_inputBuffer+[_idx]] ;let eax = buffer[idx]
        mov byte [_char],eax            ;let char = buffer[idx]
        ;new link = curr
        push 1
        push 5
        call calloc ;eax should hold pointer to newly allocated mem
        mov _curr, eax
        add esp 8
        ;put prev.next= address of curr
        mov _prev+1, _curr ; prev.next=curr
        ;put buff val into curr value
        mov _curr, [-char] ;curr.value = char
        inc dword[_idx]
        jmp %%whileLoop
    
    %%endWhileLoop:

%endmacro

;stores pointer M[ebx]+M[ecx] in eax
%macro add 0
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
    mov _result, eax 
    sub _topOfStack, 4
%endmacro

;;completed
%macro popAndPrint 0
    popFromStack
    push [_result] ;popFromStack should pop into result
%endmacro

;;completed
%macro print 0
                    ;;;arg is address of link to print recursively
    pop _x ;;x is address of link to print recursively
    ;;if(x.next == null) print
    ;;else push x; push x.next; print next
    mov eax,[_x+1] ;eax = x.next address
    cmp eax, 0
    jz %%base
    jmp %%notBase

    %%base:
        mov eax,0 
        mov al,[_x] ;al=first byte of x = x.value
        mov byte[_char], al ;char=x.value
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
            mov byte [_char],al
            mov edx, 1  ;edx = numBytes to write
            mov ecx, _char     ;ecx = curr.value
            mov ebx, 1    ;ebx = stdout
            mov eax, 3          ;eax = sys_write op code
            int 0x80            ;call the kernel to write numBytes to victim
            jmp %%endPrint

    %%notBase:
        push _x
        push [_x+1]
        print
        pop _x
        mov eax,0 
        mov al,[_x] ;al=first byte of x = x.value
        mov byte[_char], al ;char=x.value
        cmp al,9
        jle %%ifNumberNotBase
        jmp %%ifLetterNotBase

        %%ifNumberNotBase:
            add al, 48
            jmp %%regardlessNotBase

        %%ifLetterNotBase:
            add al, 55
            jmp %%regardlessNotBase

        %%regardlessNotBase:
            mov byte [_char],al
            mov edx, 1  ;edx = numBytes to write
            mov ecx, _char     ;ecx = curr.value
            mov ebx, 1    ;ebx = stdout
            mov eax, 3          ;eax = sys_write op code
            int 0x80            ;call the kernel to write numBytes to victim
            jmp %%endPrint
        


    %%endPrint:   
%endmacro

%macro printSingleDigit 0
    ;;double code in print
%endmacro

%macro numHexaDigits 0
 
%endmacro


