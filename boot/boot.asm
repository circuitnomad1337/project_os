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

VIDEO_MEMORY equ 0xB8000
WHITE_ON_BLACK equ 0x0f

protmode:
    mov ebx, 0xB8000
    mov ah, 0x0F
    mov al, 'P'

print_32:
    mov [ebx], ax
    add ebx, 2
    ret

    ; Next goals:
    ; Set up GDT for Long Mode
    ; Print out something in 32 bits
    ; Make notes about how do you switch to 32 bits

align 4
GDT_DESC:
    dw GDT_END - GDT - 1       ; gdt_start and _end are memory addresses. This allows us to measure the size of GDT
    dd GDT                     ; dd (define doubleworld) "enables" the GDT in 32-bit mode (dq is for 64 bits, "define quadword")

align 8
GDT:
    GDT_NULL: dq 0x0000000000000000                         ; Null descriptor
    GDT_kernelCodeSegment: dq 0x00CF9A000000FFFF            ; Kernel Code Segment
    GDT_kernelDataSegment: dq 0x00CF92000000FFFF            ; Kernel Data Segment
    GDT_userCodeSegment: dq 0x00CFFA000000FFFF              ; User Code Segment
    GDT_userDataSegment: dq 0x00CF92000000FFFF              ; User Data Segment
    GDT_TSM: dq 0x0000000000000000                          ; Task State Managent
GDT_END:



message db "You're in!", 0   ; string var
messageProt db "ProtMode!", 0

times 510 - ($ - $$) db 0   ; fill 510 bits with 0's
dw 0xAA55                   ; bootloader's signature