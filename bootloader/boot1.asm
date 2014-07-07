;Copyright Joatin Granlund. All rights reserved.

;--------------- PRELIMINARY SETUP ---------------; 

[BITS 16]	 			; Tell NASM we're in 16-bit mode 
[ORG 0x7C00]	 		; Tell NASM that this code will be loaded at 0x7C00 
						; to ensure any absolute jumps are calculated correctly 
					
;---------------- BOOTLOADER CODE ----------------; 
Start:
mov ax, 0x0500
mov ss, ax
;jmp reset

reset:
mov ax, 0
.reset:
mov [COUNTER], ax
mov ax, 0
mov dl, 0x80
int 13h
jnc read
mov ax, [COUNTER]
inc ax
cmp ax, 4
jg reseterror
jmp .reset

reseterror:
mov si, RESETERRORSTRING
call PrintString
cli
hlt

read:
mov ax, 0
.read:
mov [COUNTER], ax
mov ax, 0
mov ds, ax
mov si, DAP
mov ah, 0x42
mov dl, 0x80
int 13h
jnc jumpstg2
mov ax, [COUNTER]
inc ax
cmp ax, 4
jg readerror
jmp .read

readerror:
mov si, READERRORSTRING
call PrintString
cli
hlt

jumpstg2:
mov ax, 0x80
jmp 0x500
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

COUNTER dw 0
RESETERRORSTRING db 'Could not reset the hard drive', 0
READERRORSTRING db 'Could not read from the hard drive', 0
DAP:
db 0x10					; Size of DAP
db 0x00					; Always 0
dw 0x000F				; Numbers of sectors to read
dw 0x0500				; Segment:offset pointer to target location
dw 0x0000
dq 0x00000000000007F0	; Number of the start sector, the first partion starts at 0x0800, our second stage is located 16 sectors before


;-------------- PADDING / SIGNATURE -------------; 
; $ is current line, $$ is first line, db 0 is a 00000000 byte 
; So, pad the code with 0s until you reach 484 bytes 
TIMES 490 - ($ - $$) db 0 

dw 0x54494e42 ; TINB

;---------------------- MBR ---------------------;
dw 0x0000
dw 0x0002
dw 0xEEFF
dw 0xFFFF
dd 0x00000001
dd 0xFFFFFFFF

; Fill last two bytes (a word) with the MBR signature 0xAA55 
dw 0xAA55

