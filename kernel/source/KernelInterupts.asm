;;
;; Copyright Joatin Granlund 2014. All rights reserved.
;;
;; MODULE KernelInterupts.asm
;;
;; The module contains the functions for setting up interupts and to handle 
;; them
;;
[BITS 64]

section .data

;;
;; The values for the IDT Register
;;
IDTR:
	dw 0x1000
	dq IDT_START

;;
;; The start for our IDT Table
;;
IDT_START:

IDT_END:

section .text 

;;
;; Sets up the IDT table
;;
global SetupIDT
SetupIDT:
	lidt [IDTR]
	ret 