;Copyright Joatin Granlund 2014. All rights reserved.

;------------- Compiler Setup ------------;
[BITS 32]
[ORG 0x00100000]


KernelMain:			;This symbol must be first in the file
hlt
sti					;Interupts are disabled when we come from the bootloader

;------------- Includes --------------;
%include KernelInterupts.asm

;---------------- GDT ----------------;

;---------------- IDT ----------------;

;---------------- PML4 ---------------;