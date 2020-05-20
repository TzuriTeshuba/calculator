section .data                    	; we define (global) initialized variables in .data section
        format: db '%d',10,0

section .text                    	; we write code in .text section
        global assFunc         		; 'global' directive causes the function assFunc(...) to appear in global scope
        extern c_checkValidity
        extern printf

assFunc:                        	; assFunc function definition - functions are defined as labels
        push ebp              		; save Base Pointer (bp) original value
        mov ebp, esp         		; use Base Pointer to access stack contents (assFunc(...) activation frame)
        pushad                   	; push all signficant registers onto stack (backup registers values)
        mov ebx, dword [ebp+8]		; ebx = x
		mov ecx, dword [ebp+12]	    ; ecx = y

    

		; func body...
                push ecx
                push ebx
                call c_checkValidity ;result should be in eax
                add esp, 8
                cmp eax, 0    ; if c_checkValidity returned 0
                jnz subtract
            add:
                add ebx, ecx

                jmp finish
            subtract:
                sub ebx, ecx
            
            finish:
                push ebx
                push format
                call printf
                add esp, 8

        popad                    	; restore all previously used registers
        ;mov eax, ebx 
                                    ; return an (returned values are in eax)
        mov esp, ebp			    ; free function activation frame
        pop ebp				        ; restore Base Pointer previous value (to returnt to the activation frame of main(...))
        ret				            ; returns from assFunc function
