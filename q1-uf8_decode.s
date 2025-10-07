.data 
str:  .string "\n The decoded value is "

.text
# t0 = exponent
# t1 = mantissa
# t2 = offset

main:
    # Test data 1
    la  a0, str     
    li  a7, 4         
    ecall
    li a0, 0x2F       
    jal ra, uf8_decode
    li a7, 1      
    ecall
    
    # Test data 2
    la  a0, str     
    li  a7, 4         
    ecall
    li a0, 0x5A       
    jal ra, uf8_decode
    li a7, 1
    ecall

    # Test data 3
    la  a0, str     
    li  a7, 4         
    ecall
    li a0, 0xF0      
    jal ra, uf8_decode
    li a7, 1
    ecall

    # End
    li a7, 10       
    ecall
    
uf8_decode:
    addi sp, sp, -16      # allocate stack space for t0, t1, t2, ra
    sw ra, 12(sp)         # save return address

    srai t0, a0, 4        # extract exponent t0 = a0 >> 4
    andi t1, a0, 0x0F     # extract mantissa t1 = a0 & 0x0F

    # calculate offset = (2^e -1) << 4
    li t2, 1
    sll t2, t2, t0        # t2 = 2^e
    addi t2, t2, -1       # t2 = 2^e -1
    slli t2, t2, 4        # offset = (2^e-1)*16

    # calculate mantissa shifted: t1 << e
    sll t1, t1, t0

    # final value = mantissa<<e + offset
    add a0, t1, t2

    lw ra, 12(sp)
    addi sp, sp, 16
    ret
