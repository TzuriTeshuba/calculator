
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
    _valx: db 0
    _valy: db 0
    _valz: db 0


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
    mov dword [_oldHead], 0
    mov dword[_idx], 0
    %%whileLoop: ;while(idx<inputLength)
        ;;check condition
        mov eax, [_idx]
        mov ebx, [_inputLength]
        sub ebx, eax    ;ebx = length - idx
        cmp ebx, 0       
        jle %%endWhileLoop
        ;read val from buffer         
        add eax, _inputBuffer            ;let eax = pointer to buffer[idx]
        mov ecx, 0
        mov cl, [eax]                   ;ecx = 0x000000buffer[idx]
        mov byte [_char],cl             ;let char = buffer[idx]
        ;new head points to old head
        push 1
        push 5
        call calloc                     ;eax should hold pointer to newly allocated mem
        add esp, 8
        mov dword [_newHead], eax       ;eax = pointer to newHead
        mov cl, [_char]                 ;cl = currValue
        mov edx, [_newHead]
        mov byte[edx], cl               ;newHead.value = cl = newValue
        mov eax, [_oldHead]             ;eax = pointer to oldHead
        mov dword[edx+1],eax            ;newHead.next = eax = pntr to oldHead
        mov eax, [_newHead]             ;eax = pntr to newHead
        mov dword [_oldHead], eax       ;oldHead = newHead
        inc dword[_idx]                 ;increment buffer index 

        jmp %%whileLoop
    
    %%endWhileLoop:
        pushToStack [_newHead]

%endmacro

;stores pointer M[ebx]+M[ecx] in eax
%macro myAdd 0
    popFromStack
    mov eax, [_result]
    mov dword[_x],eax       ;x hold address of 1st head
    popFromStack
    mov eax, [_result]
    mov dword[_y],eax       ;y hold address of 2nd head

    mov byte[_carry],0      ;reset the carry
    mov dword[_prev],0      ;prev init to null
    mov dword[_result], 0   ;result will point to the address to push, it's now null

    ;loop starts here
    %%whileLoop:
        mov byte [_valx],0                  ;init valx to 0
        mov byte [_valy],0                  ; init valy to 0
        cmp dword [_x],0                    ;check if x points to null (end of list1)
        jz %%calcedX

        ;valx = x.val 
        mov eax, [_x]                       ;eax holds pointer to x-list link
        mov ebx,0
        mov bl, [eax]                       ;bl = x.val
        mov byte[_valx], bl                 ;valx=x.val

        %%calcedX:
            cmp dword [_y],0
            jz %%calcedY

            ;valy = y.val 
            mov eax, [_y]                   ;eax holds pointer to y-list link
            mov ebx,0
            mov bl, [eax]                   ;bl = y.val
            mov byte[_valy], bl             ;valy=y.val

        %%calcedY:
            ;;check if both x and y are null
            mov eax, [_x]
            add eax, [_y]
            cmp eax, 0                      ;check if x and y are BOTH null
            jz %%finishIterating            ;still have to add the carry!

            mov ecx,0
            mov cl, [_valx]
            add cl, [_valy]
            add cl, [_carry]
            mov byte[_valz],cl
            cmp cl, 0x10
            jge %%carry
            jmp %%dontCarry
        
        %%carry:
            mov byte[_carry],1
            sub byte[_valz], 0x10
            jmp %%carryOrNot

        %%dontCarry:
            mov byte[_carry],0
            jmp %%carryOrNot

        %%carryOrNot:
            ;new head points to old head
            push 1
            push 5
            call calloc                     ;eax should hold pointer to newly allocated mem
            add esp, 8
            mov ebx, [_result]
            cmp ebx, 0 
            jnz %%skip
            mov dword[_result], eax
            pushToStack eax

        %%skip:
            mov dword [_next], eax          ;next holds address of new link
            mov cl, [_valz]                 ;cl = currValue
            mov edx, [_next]                ;edx hold address of new link 
            mov byte[edx], cl               ;newLink.value = cl = newValue
            mov eax, [_prev]                ;eax = pointer to prev
            mov dword[edx+1],0              ;newLink.next = null
            mov dword[eax+1], edx           ;prev.next = address of new link
            mov dword [_prev], edx          ;prev = new link
            jmp %%whileLoop

        %%finishIterating:
            cmp byte[_carry], 0
            jz %%endOfAdd
            ;;create extra link for the carry
            push 1
            push 5
            call calloc                     ;eax should hold pointer to newly allocated mem
            add esp, 8
            mov dword [_next], eax          ;next holds address of new link
            mov cl, 1                       ;cl = currValue
            mov edx, [_next]                ;edx hold address of new link 
            mov byte[edx], cl               ;newLink.value = cl = newValue
            mov eax, [_prev]                ;eax = pointer to prev
            mov dword[edx+1],0              ;newLink.next = null
            mov dword[eax+1], edx           ;prev.next = address of new link
            mov dword [_prev], edx          ;prev = new link

    %%endOfAdd:

%endmacro

%macro clearInputBuffer 0

%endmacro

%macro clearInputBuffer 1

%endmacro

%macro pushToStack 1
    ;; %1 is pointer to push
    mov ebx, [_topOfStack]      ;ebx = address of current top element
    add ebx, 4                  ;ebx = address of first available place in op stack
    mov [_topOfStack],ebx       ;top of stack holds address of first available space
    mov eax, %1                 ;eax = arg1 = pointer to push
    mov dword[ebx], eax         ;first available spot filled filled arg1
%endmacro

;;pops top element into result register and decrements top of stack
%macro popFromStack 0
    mov eax, [_topOfStack]      ;eax = address of top-most element
    mov eax, [eax]              ;eax = value of top-most element = address of some list's head
    mov dword[_result], eax 
    sub dword[_topOfStack], 4
%endmacro

;;completed
%macro popAndPrint 0
    popFromStack                ;popped list is now in result
    mov eax, [_result]          ;eax = address of the lists head
    mov dword[_curr],eax        ;curr = list.head address
    push 0;
    %%pushWhileLoop:
    ;while(next not null)push value to stack (seperately push last)
    mov eax, [_curr]            ;ebx = address of curr
    mov eax, [eax]              ;ebx = 0x0curr.value //SegFault
    cmp al,9                    ;check if value reps letter decimal number
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
        mov al, 10
        mov byte[_char], al
        mov edx, 1          ;edx = numBytes to write
        mov ecx, _char      ;ecx = char (buffer)
        mov ebx, 1          ;ebx = stdout
        mov eax, 4          ;eax = sys_write op code
        int 0x80            ;call the kernel to write numBytes to victim
%endmacro

%macro numHexaDigits 0
 
%endmacro


main:
    ;set topOfStack to hold address of stack-1
    mov eax, _operandStack
    sub eax,4
    mov dword [_topOfStack],eax

    runloop:

        getUserInput
        mov eax, 0
        mov al, [_inputBuffer]   ;eax = LSByte
        cmp al, 'q'
        jz endOfProgram

        cmp al, 'p'
        jz calcPrint

        cmp al, '+'
        jz calcAdd

        jmp receiveOperand

    calcPrint:
        popAndPrint
        jmp runloop

    calcAdd:
        myAdd
        jmp runloop

    receiveOperand:
        convertAsciiToHexa
        listify
        jmp runloop

    endOfProgram:
        mov eax, [_numOperations] 
        

;_init:

