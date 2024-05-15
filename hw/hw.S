#    SPDX-FileCopyrightText: 2024 ms-erik <erikmelges@usp.br>
#   
#    SPDX-License-Identifier: GPL-3.0-or-later

# AT&T assembly, translated from NASM


    .code16     # set 16-bit code

    .global start # to the linker be able to find it
 

start: 
    
    mov $0xe, %ah

    mov $0x48, %al

    int $0x10

    mov $0x65, %al
    int $0x10

    mov $0x6C, %al
    int $0x10

    mov $0x6C, %al
    int $0x10

    mov $0x6F, %al
    int $0x10

    mov $0x20, %al
    int $0x10

    mov $0x57, %al
    int $0x10

    mov $0x6F, %al
    int $0x10

    mov $0x72, %al
    int $0x10

    mov $0x6C, %al
    int $0x10

    mov $0x64, %al
    int $0x10
halt: 
    
    hlt        
    jmp halt     

	.fill 510 - (. - begin), 1, 0       
	.word 0xaa55			    
