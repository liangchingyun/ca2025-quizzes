.data 
str:  .string "\n The encoded value is "

.text

main:
    # Test data 1
    la a0, str
    li a7, 4
    ecall
    li a0, 108       
    jal ra, uf8_encode
    li a7, 1         
    ecall

    # Test data 2
    la a0, str
    li a7, 4
    ecall
    li a0, 816
    jal ra, uf8_encode
    li a7, 1
    ecall

    # Test data 3
    la a0, str
    li a7, 4
    ecall
    li a0, 524272
    jal ra, uf8_encode
    li a7, 1
    ecall

    # End
    li a7, 10
    ecall
    
uf8_encode:
    addi sp, sp, -16
    sw ra, 12(sp)

    # check if value < 16
    li t0, 16
    blt a0, t0, encode_return_value

    # compute MSB via clz loop
    li t1, 31           # bit position
    mv t2, a0           # copy value

clz_loop:
    srli t3, t2, 31
    bnez t3, clz_done
    addi t1, t1, -1
    slli t2, t2, 1      
    j clz_loop
    
clz_done:
    # t1 = msb
    li t2, 5
    blt t1, t2, find_exact_exponent_loop
    addi t0, t1, -4      # t0 = exponent
    li t2, 15
    blt t2, t0, estimate_exponent
    li t0, 15        
    
estimate_exponent:
    li t2, 0            # t2 = overflow
    li t3, 0            # t3 = e
    
calculate_overflow_loop:
    bge t3, t0, adjust_loop  
    slli t2, t2, 1      # overflow <<= 1
    addi t2, t2, 16     # overflow += 16
    addi t3, t3, 1      # e++
    j calculate_overflow_loop
    
adjust_loop:
    blez t0, find_exact_exponent_loop     # if exponent <= 0, exit
    bge a0, t2, find_exact_exponent_loop  # if value >= overflow, exit
    addi t2, t2, -16                      # overflow -= 16
    srli t2, t2, 1                        # overflow >>= 1
    addi t0, t0, -1                       # exponent--
    j adjust_loop 
    
find_exact_exponent_loop:
    li t4, 15
    bge t0, t4, refine_exp_done   # if exponent >= 15, exit loop
    slli t3, t2, 1                # t3 = next_overflow = overflow << 1
    addi t3, t3, 16               # next_overflow += 16
    blt a0, t3, refine_exp_done   # if value < next_overflow, break
    mv t2, t3                     # overflow = next_overflow
    addi t0, t0, 1                # exponent++
    j find_exact_exponent_loop              
    
refine_exp_done:
    sub t4, a0, t2        # t4 = mantissa = value - overflow
    srl t4, t4, t0        # mantissa >>= exponent
    slli t0, t0, 4        # exponent << 4
    or a0, t0, t4          # a0 = (exponent << 4) | mantissa
    
encode_return_value:
    lw ra, 12(sp)
    addi sp, sp, 16
    ret