;Copyright Joatin Granlund. All rights reserved.

;--------------- PRELIMINARY SETUP ---------------; 

[BITS 16]	 			; Tell NASM we're in 16-bit mode 
[ORG 0x7C00]	 		; Tell NASM that this code will be loaded at 0x7C00 
						; to ensure any absolute jumps are calculated correctly 
					
;---------------- BOOTLOADER CODE ----------------; 
Start:
;jmp reset

reset:					; Reset the floppy drive
mov ax, 0
mov dl, 0x80				; Drive=0 (=A)
int 13h
jc reset				; ERROR => reset again


read:
mov ax, 0       ; ES:BX = 1000:0000
mov es, ax          ;
mov bx, Start2           ;

mov ah, 2           ; Load disk data to ES:BX
mov al, 2           ; Load 5 sectors
mov ch, 0           ; Cylinder=0
mov cl, 2           ; Sector=2
mov dh, 0           ; Head=0
mov dl, 0x80           ; Drive=0
int 13h             ; Read!

jc read             ; ERROR => Try again

jmp Start2      ; Jump to the program

;---------------- SCREEN FUNCTIONS ---------------; 

PrintString:	 		; Print a string to screen 
						; Assume pointer to string to print is in SI 
next_character: 
MOV AL, [SI]			; Grab the next character 
OR AL, AL				; Check if character is zero 
JZ exit_function		; If it is, then return 
CALL PrintCharacter		; Else, print the character 
INC SI	 				; Increment pointer for next character 
JMP next_character		; Loop 
exit_function: 
MOV AL, 10
CALL PrintCharacter
MOV AL, 13
CALL PrintCharacter
RET 

PrintCharacter:	 		; Print a single character to screen 
						; Assume character to print is in AL 
MOV AH, 0x0E	 		; Teletype Mode 
MOV BH, 0x00	 		; Page zero 
MOV BL, 0x07	 		; Light Gray 
INT 0x10	 			; Print Character 
RET 

;------------------ DATA BLOCK ------------------; 


;-------------- PADDING / SIGNATURE -------------; 
; $ is current line, $$ is first line, db 0 is a 00000000 byte 
; So, pad the code with 0s until you reach 510 bytes 
TIMES 510 - ($ - $$) DB 0 

; Fill last two bytes (a word) with the MBR signature 0xAA55 
DW 0xAA55

;------------------- Stage 2 --------------------;

Start2:
call do_e820
mov si, HelloString		; Store pointer to hello world string in SI 
call PrintString		; Print the string 
jmp EnterProtected

do_e820:
	xor ebx, ebx		; ebx must be 0 to start
	xor bp, bp		; keep an entry count in bp
	mov edx, 0x0534D4150	; Place "SMAP" into edx
	mov eax, 0xe820
	mov di, 0x500
	mov [es:di + 20], dword 1	; force a valid ACPI 3.X entry
	mov ecx, 24		; ask for 24 bytes
	int 0x15
	jc short .failed	; carry set on first call means "unsupported function"
	mov edx, 0x0534D4150	; Some BIOSes apparently trash this register?
	cmp eax, edx		; on success, eax must have been reset to "SMAP"
	jne short .failed
	test ebx, ebx		; ebx = 0 implies list is only 1 entry long (worthless)
	je short .failed
	jmp short .jmpin
.e820lp:
	mov eax, 0xe820		; eax, ecx get trashed on every int 0x15 call
	mov [es:di + 20], dword 1	; force a valid ACPI 3.X entry
	mov ecx, 24		; ask for 24 bytes again
	int 0x15
	jc short .e820f		; carry set means "end of list already reached"
	mov edx, 0x0534D4150	; repair potentially trashed register
.jmpin:
	jcxz .skipent		; skip any 0 length entries
	cmp cl, 20		; got a 24 byte ACPI 3.X response?
	jbe short .notext
	test byte [es:di + 20], 1	; if so: is the "ignore this data" bit clear?
	je short .skipent
.notext:
	mov ecx, [es:di + 8]	; get lower dword of memory region length
	or ecx, [es:di + 12]	; "or" it with upper dword to test for zero
	jz .skipent		; if length qword is 0, skip entry
	inc bp			; got a good entry: ++count, move to next storage spot
	add di, 24
.skipent:
	test ebx, ebx		; if ebx resets to 0, list is complete
	jne short .e820lp
.e820f:
	mov [mmap_ent], bp	; store the entry count
	clc			; there is "jc" on end of list to this point, so the carry must be cleared
	ret
.failed:
	stc			; "function unsupported" error exit
	ret
;---------------- Protected Mode ----------------;

EnterProtected:
cli
lgdt [GDTR]
mov eax, cr0
or al, 1
mov cr0, eax
jmp PModeMain

;------------------ DATA BLOCK ------------------; 

HelloString db 'Hello World', 0 
mmap_ent db 0

GDTR db 0

[BITS 32]
PModeMain:

hlt

;The size of the second stage is 1024 bytes
TIMES 1536 - ($ - $$) DB 0

;heads =5, cylinders = 980, sectors = 17, bytes per sector = 512, 40 mb
TIMES 42649600 - ($ - $$) DB 0