[BITS 16]     
[ORG 0x7C00]   ; classic place of the bootloader

_start:
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    
    jmp protModeSetup    
    
protModeSetup:
    cli                     ; disable interrupts

    in al, 0x92             ; download the state of I/O port 0x92
    or al, 2                ; manipulate it
    out 0x92, al            ; send it back, enabling A20 line
    
    xor ax, ax              ; prepare to initialize ds
    mov ds, ax              ; initialize ds, lgdt uses ds as it's segment

    lgdt [GDT_DESC]         ; load the GDT

    mov eax, 0x11           ; manipulate eax (eax is zero'ed)

    ; mov eax to Control Register 0
    ; paging disabled, protection bit 0 enabled, bit 4, the extension type is alwawys 1

    mov cr0, eax            
    
    jmp GDT_kernelCodeSegment-GDT:protmode      ; jump to Protected Mode part 

    
[BITS 32]

protmode:   
    mov ax, GDT_kernelDataSegment - GDT  
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov esp, 0x90000                            ; tmp stack.

    jmp longModeSetup

longModeSetup:
    xor eax, eax

    mov eax, 0xA0          
    mov cr4, eax            ; Set up the PAE and PGE bits
    
    ; Setting up the PDPT tables
    ; --- Page Directory (PD) Setup, 2 MiB pages

    mov edi, 0x100000

    mov eax, 0x83               ; 0x83 = Present, Read/Write, PS = 0 (Point to PT)
    xor edx, edx
    mov [edi], eax
    mov [edi + 4], edx
    add edi, 8

    mov ecx, 511 * 2
    xor eax, eax
    rep stosd

    ; --- Page Directory Pointer (PDP) Setup, 1 GiB pages

    mov eax, 0x100003           ; Present, Read/Write, PS = 0 (Point to PD)
    mov [edi], eax
    mov [edi + 4], edx
    add edi, 8

    mov ecx, 511 * 2
    xor eax, eax
    rep stosd
    
    ; --- Page Map Level 4 (PML4) Setup, 512 GiB pages

    mov eax, 0x101003           ; Present, Read/Write, PS = 0 (Point to PDP)
    mov [edi], eax
    mov [edi + 4], edx
    add edi, 8

    mov ecx, 511 * 2
    xor eax, eax
    rep stosd

    ; --- Set PML4 Pointer in Control Register 3
    
    mov eax, 0x102000
    mov cr3, eax

    ; --- Set LME bit (Long Mode Eneable) in the IA32_EFER machine specific register

    mov ecx, 0xC0000080         ; Register number of EFER
    mov eax, 0x00000100         ; LME bit set
    xor edx, edx                ; Rest of the bits set to zero
    wrmsr

    ; --- Enable paging 
    
    mov eax, cr0                ; Download and store Control Register 0 state in EAX register
    bts eax, 31                 ; Swap the bit's state
    mov cr0, eax                ; Change the Control Register 0 state

    jmp GDT_CS64-GDT:longMode          ; Jump into Long Mode (64 bits)

[BITS 64]

longMode:
    mov rdi, 0xB8000
    mov rax, 'L o n g '
    stosq

hang:
    pause
    jmp hang

align 4
GDT_DESC:
    dw GDT_END - GDT - 1       ; gdt_start and _end are memory addresses. This allows us to measure the size of GDT
    dd GDT                     ; dd (define doubleworld) "enables" the GDT in 32-bit mode (dq is for 64 bits, "define quadword")

align 16
GDT:
    GDT_NULL: dq 0x0000000000000000                         ; Null descriptor
    GDT_kernelCodeSegment: dq 0x00CF9A000000FFFF            ; Kernel Code Segment
    GDT_kernelDataSegment: dq 0x00CF92000000FFFF            ; Kernel Data Segment
    GDT_userCodeSegment: dq 0x00CFFA000000FFFF              ; User Code Segment
    GDT_userDataSegment: dq 0x00CF92000000FFFF              ; User Data Segment
    GDT_TSM: dq 0x0000000000000000                          ; Task State Management

    GDT_CS64:dq 0x00209A0000000000

GDT_END:




messageProt db "ProtMode!", 0

times 510 - ($ - $$) db 0   ; fill 510 bits with 0's
dw 0xAA55                   ; bootloader's signature