
dq 0x5452415020494645		; The signature
dd 0x00010000 					; Revision
dd 0x0000005C					; Header size
dd 0x00000000					; CRC32 checksum
dd 0x00000000					; Reserved
dq 0x00000001					; Current LBA
dq 0x00000000					; Backup LBA
dq 0x00000800					; First Usable LBA
dq 0x00000000
dq 0x00000000
dq 0x00000000
dq 0x00000002
dd 0x0080
dd 0x0080
dd 0x0000						; CRC32 checksum of partition array

TIMES 512 - ($ - $$) db 0 

dq 0x0000000000000000
dq 0x0000000000000000

dq 0x0000000000000000
dq 0x0000000000000000

dq 0x0000000000000800

dq 0x0000000000000900

dq 0x0000000000000000

TIMES 36 dw 0
