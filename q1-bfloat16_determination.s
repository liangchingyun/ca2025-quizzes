.data 

bf16_list:    .half 0x7FC1, 0x7F80, 0x0000, 0x8000    # NaN, +Inf, 0, -0

str1: .string "\n NAN : "
str2: .string "\n Inf : "
str3: .string "\n Zero : "

.text

main:
    li t3, 0x7F80              # t3 = BF16_EXP_MASK
    li t4, 0x007F              # t4 = BF16_MANT_MASK
    li t6, 0x7FFF

isnan_start:
    la t0, bf16_list       
    li t1, 0           
    li t2, 4              
    
    la a0, str1
    li a7, 4
    ecall
    
isnan_loop:
    beq t1, t2, isinf_start
    
    lh a0, 0(t0)
    jal ra, bf16_isnan
    li a7, 1
    ecall
    
    addi t0, t0, 2         # Next half (16 bits)
    addi t1, t1, 1         # i++
    j isnan_loop

isinf_start: 
    la t0, bf16_list       
    li t1, 0           
    li t2, 4              
    
    la a0, str2
    li a7, 4
    ecall
    
isinf_loop:
    beq t1, t2, iszero_start
    
    lh a0, 0(t0)
    jal ra, bf16_isinf
    li a7, 1
    ecall
    
    addi t0, t0, 2         # Next half (16 bits)
    addi t1, t1, 1         # i++
    j isinf_loop
    
iszero_start: 
    la t0, bf16_list       
    li t1, 0           
    li t2, 4              
    
    la a0, str3
    li a7, 4
    ecall
    
iszero_loop:
    beq t1, t2, end
    
    lh a0, 0(t0)
    jal ra, bf16_iszero
    li a7, 1
    ecall
    
    addi t0, t0, 2         # Next half (16 bits)
    addi t1, t1, 1         # i++
    j iszero_loop
    
bf16_isnan:
    and t5, t3, a0
    bne t5, t3, return_0      
    and t5, t4, a0
    snez a0, t5                # a0 = 1 if mantissa != 0
    ret
    
bf16_isinf: 
    and t5, t3, a0
    bne t5, t3, return_0      
    and t5, t4, a0
    seqz a0, t5                # a0 = 1 if mantissa == 0
    ret

bf16_iszero:
    and t5, t6, a0
    seqz a0, t5
    ret

return_0:
    li a0, 0
    ret
    
end:
    li a7, 10
    ecall
