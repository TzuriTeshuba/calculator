section	.rodata			; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0	; format string
	format_num: db "%d", 10, 0		; format string
	format_blah: db "blah", 10, 0

section .bss			; we define (global) uninitialized variables in .bss section
	an: resb 12			; enough to store integer in [-2,147,483,648 (-2^31) : 2,147,483,647 (2^31-1)]
	char: resb 1
	temp: resb 1

section .data
	sum: dd 0
	length: db 0
	remainder: db 0
	divisor: db 16

section .text
	global convertor
	extern printf

convertor:
	push ebp
	mov ebp, esp	
	pushad			

	mov ecx, dword [ebp+8]			; get function argument (pointer to string)

	; your code comes here...
	mov ebx, 0						;set ebx (i) to 0
	mov byte[length], 0
	clear:
		mov byte[an+ebx], 0
		inc ebx
		cmp ebx, 12
		jl clear

	mov ebx, 0

	whileLoop1:
		mov edx, 0					;reset edx
		mov eax, 0
		mov al,[ecx+ebx]		;store the next byte from the input in al
		mov byte[char], al			;place the next char of the sring in char
		cmp byte[char], 0			;if the char is null or next line dont do anything
		je endWhileLoop1
		cmp byte[char], 10
		je endWhileLoop1
		mov eax, dword[sum]			;put sum in eax
		mov edx, 10					;put 10 in edx - the multyplier
		mul edx						;multiply sum by 10 eax=lower part of product  edx=upper part of product
		mov dword [sum], eax		;keep the product in sum, should never be more than 2^32-1 so should never be in edx
		mov edx, 0					;get rid of garbage
		mov dl, byte[char]			;get ascii val of char into char 
		sub dl, 48					;sub 48 to get decimal value
		mov byte[char], dl			;put it back into char
		add dword[sum], edx			;sum = sum+char, edx still holds the right value of char
		inc ebx
		jmp whileLoop1

	endWhileLoop1:	

	cmp dword[sum], 0
	jg notZero
	mov byte[an], 48
	jmp funcEnd

	notZero:
	mov ebx, 0

	whileLoop2:
		mov edx, 0
		cmp dword [sum],0
		je endWhileLoop2
		mov eax, [sum]
		div dword[divisor]						;eax = sum/16 and edx holds remainder
		mov dword [sum], eax
		cmp edx, 10
		jl ifNumber
		add edx, 55
		mov byte [an+ebx], dl
		inc ebx
		inc byte[length]
		jmp whileLoop2

	ifNumber:
		add edx, 48
		mov byte [an+ebx], dl
		inc ebx
		inc byte[length]
		jmp whileLoop2


	endWhileLoop2:

	mov ebx, 0						;set i to 0
	dec byte[length]
	whileLoop3:
		mov eax, 0						;clean garbage	
		mov edx, 0
		mov dl, byte[length]			;plae length in dl
		mov al, byte[an+edx]			;placing the last char from an in al
		mov byte[temp], al				;temp = an[length-i]
		mov al, byte[an+ebx]			;al = an[i]
		mov byte[an+edx], al			;an[length-i] = an[i]
		mov al, byte[temp]
		mov byte[an+ebx], al			;an[i] = temp
		dec byte[length]
		inc ebx
		cmp byte[length], bl
		jg whileLoop3


	funcEnd:


	push an				; call printf with 2 arguments -  
	push format_string	; pointer to str and pointer to format string
	call printf
	add esp, 8			; clean up stack after call

	popad			
	mov esp, ebp	
	pop ebp
	ret
