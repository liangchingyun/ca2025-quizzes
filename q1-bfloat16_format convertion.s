.data 
str1: .string "\n The bf16 of 0x3FC00000 is "
str2: .string "\n The bf16 of 0xC02C0000 is "
str3: .string "\n The bf16 of 0x477FE000 is "

str4: .string "\n The f32 of 0x3FC0 is "
str5: .string "\n The f32 of 0xC02C is "
str6: .string "\n The f32 of 0x4780 is "

f32_input1: .word 0x3FC00000  
f32_input2: .word 0xC02C0000   
f32_input3: .word 0x477FE000  

bf16_input1: .word 0x3FC0  
bf16_input2: .word 0xC02C   
bf16_input3: .word 0x4780  

.text

main:
    # Test f32_to_bf16
    
    # data 1
    la a0, str1
    li a7, 4
    ecall
    lw a0, f32_input1
    jal ra, f32_to_bf16
    li a7, 34
    ecall
    
    # data 2
    la a0, str2
    li a7, 4
    ecall
    lw a0, f32_input2
    jal ra, f32_to_bf16
    li a7, 34
    ecall
    
    # data 3
    la a0, str3
    li a7, 4
    ecall
    lw a0, f32_input3
    jal ra, f32_to_bf16
    li a7, 34
    ecall

    # Test bf16_to_f32
    
    # data 1
    la a0, str4
    li a7, 4
    ecall
    lw a0, bf16_input1
    jal ra, bf16_to_f32
    li a7, 34
    ecall
    
    # data 2
    la a0, str5
    li a7, 4
    ecall
    lw a0, bf16_input2
    jal ra, bf16_to_f32
    li a7, 34
    ecall
    
    # data 3
    la a0, str6
    li a7, 4
    ecall
    lw a0, bf16_input3
    jal ra, bf16_to_f32
    li a7, 34
    ecall
    
    # End
    li a7, 10
    ecall
    
f32_to_bf16:     
    # check exp == 0xFF
    srli t0, a0, 23
    andi t0, t0, 0xFF
    li t1, 0xFF
    beq t0, t1, f32_to_bf16_done

    # round-to-nearest-even
    srli t2, a0, 16          

    andi t2, t2, 1
    li t3, 0x7FFF
    add a0, a0, t2
    add a0, a0, t3

f32_to_bf16_done:
    srli a0, a0, 16
    ret
    
bf16_to_f32:
    slli a0, a0, 16          
    ret


