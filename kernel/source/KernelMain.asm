;;
;; Copyright Joatin Granlund 2014. All rights reserved.
;;
;; MODULE KernelMain.asm
;;
[BITS 64]
[ORG 0x00100000]
CPU x64

section .data follows=.text



section .text

;;
;; The entry point for the kernel (Must be placed first in .text section)
;;
KernelMain:
call SetupIDT
hlt
sti					;Interupts are disabled when we come from the bootloader

;------------- Includes --------------;
%include "KernelInterupts.asm"



section .bss