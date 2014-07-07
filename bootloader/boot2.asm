;;
;; Copyright Joatin Granlund. All rights reserved.
;;
;; MODULE "boot2.asm"
;;
;; This is the second stage of the bootloader
;;

[org 0x500]
CPU x64

;--------------- Data Area ----------------;
section .data follows=.text
BOOTDEVICE: dw 0
COUNTER: dw 0x0000
MMAPCOUNT dw 0
READERROR db 'READERROR', 0
HELLOWORLD db 'HELLO WORLD', 0

DAP_GPT:
db 0x10					; Size of DAP
db 0x00					; Always 0
dw 0x0020				; Numbers of sectors to read
dw GPT				; Segment:offset pointer to target location
dw 0x0000
dq 0x0000000000000001	; Number of the start sector, the first partion starts at 0x0800, our second stage is located 16 sectors before

GDTR dw 4, 0, 0

GDT:
; null descriptor 
	dd 0 				; null descriptor--just fill 8 bytes with zero
	dd 0 
 
; Notice that each descriptor is exactally 8 bytes in size. THIS IS IMPORTANT.
; Because of this, the code descriptor has offset 0x8.
 
; code descriptor:			; code descriptor. Right after null descriptor
	dw 0FFFFh 			; limit low
	dw 0 				; base low
	db 0 				; base middle
	db 10011010b 			; access
	db 11001111b 			; granularity
	db 0 				; base high
 
; Because each descriptor is 8 bytes in size, the Data descritpor is at offset 0x10 from
; the beginning of the GDT, or 16 (decimal) bytes from start.
 
; data descriptor:			; data descriptor
	dw 0FFFFh 			; limit low (Same as code)
	dw 0 				; base low
	db 0 				; base middle
	db 10010010b 			; access
	db 11001111b 			; granularity
	db 0				; base high
GDT_end:

;----------------- Code Area -----------------;
section .text start=0x500


;;
;; The main entry point for the second stage
;;
;; @param ax, boot device
;;
[bits 16]
Main:
	mov [BOOTDEVICE], ax
	mov ax, stack
    mov ss, ax
	mov si, HELLOWORLD
	call PrintString
	call ReadGPTFromDisk

;;
;; Reads the Guid Partition Table from the bootdrive
;;
[bits 16]
ReadGPTFromDisk:
	mov ax, 0
	.ReadGPT:
		mov [COUNTER], ax
		mov ax, 0
		mov ds, ax
		mov si, DAP_GPT
		mov ah, 0x42
		mov dl, [BOOTDEVICE]
		int 13h
		jnc .ReadGPTEnd
		mov ax, [COUNTER]
		inc ax
		cmp ax, 4
		jg .ReadGPTError
		jmp .ReadGPT
	.ReadGPTError:
		mov si, READERROR
		call PrintString
		cli
		hlt
	.ReadGPTEnd:
		ret

;;
;; Reads the memory map
;;
[bits 16]
ReadMemoryMap:
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
		mov [MMAPCOUNT], bp	; store the entry count
		clc			; there is "jc" on end of list to this point, so the carry must be cleared
		ret

	.failed:
		stc			; "function unsupported" error exit
		ret


[bits 16]
EnterProtected:
cli
XOR   EAX, EAX
MOV   AX, DS
SHL   EAX, 4
ADD   EAX, GDT
MOV   [GDTR + 2], eax
MOV   EAX, GDT_end
SUB   EAX, GDT
MOV   [GDTR], AX
LGDT  [GDTR]
mov eax, cr0
or al, 1
mov cr0, eax
;jmp 08h:PModeMain

;;
;; Prints a null terminated string to the screen
;;
;; @param si, the pointer to the string
PrintString:	 		; Print a string to screen, Assume pointer to string to print is in SI 
	.next_character: 
		MOV AL, [SI]			; Grab the next character 
		OR AL, AL				; Check if character is zero 
		JZ .exit_function		; If it is, then return 
		CALL PrintCharacter		; Else, print the character 
		INC SI	 				; Increment pointer for next character 
		JMP .next_character		; Loop 
	.exit_function: 
		MOV AL, 10
		CALL PrintCharacter
		MOV AL, 13
		CALL PrintCharacter
		RET 

;;
;; Prints a character to the screen
;;
;; @param al, the character to print
;;
PrintCharacter:	 		; Print a single character to screen, Assume character to print is in AL 
	MOV AH, 0x0E	 		; Teletype Mode 
	MOV BH, 0x00	 		; Page zero 
	MOV BL, 0x07	 		; Light Gray 
	INT 0x10	 			; Print Character 
	RET 


;----------- Uninitialized Data Section ----------;
section .bss
;;
;; A small stack
;;
stack:
    resb 64

;;
;; The Guid Partition Table
;;
GPT:
    GPT_LBA1:
	    resb 512
	GPT_LBA2:
	    resb 512
	GPT_ENTRIES:
		resb 16384

MEMORYMAP: 
	resb 1536

KERNELHEAP:
	resb 512*20