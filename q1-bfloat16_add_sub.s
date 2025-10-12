.data 

bf16_vals:
    .half 0x3FC0     
    .half 0xC030     
    .half 0x4780
    .half 0x3FC0     

str1: .string "\nbf16_add result: "
str2: .string "\n\nbf16_sub result: "
str:  .string " \n"

.text

main:
add_start: 
    la t0, bf16_vals    # t0 = pointer to list
    li t1, 0            # loop counter
    li t2, 2  
    
    la a0, str1
    li a7, 4
    ecall     
    
add_loop:
    bgt t1, t2, sub_start
    
    la a0, str
    li a7, 4
    ecall 
    
    lhu a0, 0(t0)        # a = bf16_vals[i]
    lhu a1, 2(t0)        # b = bf16_vals[i+1]
    
    jal ra, bf16_add
    li a7, 34
    ecall

    addi t0, t0, 2     
    addi t1, t1, 1
    j add_loop
    
sub_start: 
    la t0, bf16_vals    # t0 = pointer to list
    li t1, 0            # loop counter
    li t2, 2  
    
    la a0, str2
    li a7, 4
    ecall     
    
sub_loop:
    bgt t1, t2, end
    
    la a0, str
    li a7, 4
    ecall 
    
    lhu a0, 0(t0)        # a = bf16_vals[i]
    lhu a1, 2(t0)        # b = bf16_vals[i+1]
    
    jal bf16_sub
    li a7, 34
    ecall

    addi t0, t0, 2     
    addi t1, t1, 1
    j sub_loop


bf16_add:
    addi sp, sp, -16
    sw ra, 12(sp)

    # --- extract sign, exp, mantissa ---
    srli a2, a0, 15        # a2 = sign_a
    srli a3, a1, 15        # a3 = sign_b

    srli a4, a0, 7
    andi a4, a4, 0xFF      # a4 = exp_a
    srli a5, a1, 7
    andi a5, a5, 0xFF      # a5 = exp_b

    andi a6, a0, 0x7F      # a6 = mant_a
    andi a7, a1, 0x7F      # a7 = mant_b

    # --- handle special cases: NaN, Inf, zero ---
    li t3, 0xFF
    bne a4, t3, finish_first_case
    bnez a6, return_a
    bne a5, t3, return_a
    # (mant_b || sign_a == sign_b) ? b : NaN
    bnez a7, return_b
    beq a2, a3, return_b
    li a0, 0x7FC0
    ret
    
finish_first_case:
    beq a5, t3, return_b
    beqz a4, return_b
    beqz a5, return_a

    # --- restore implicit 1 for normalized numbers ---
    
bf16_add_restore_a:
    beqz a4, bf16_add_restore_b
    ori a6, a6, 0x80       # mant_a |= 0x80
bf16_add_restore_b:
    beqz a5, exp_diff_start
    ori a7, a7, 0x80       # mant_b |= 0x80
    
exp_diff_start:
    sub t3, a4, a5         # t3 = exp_diff
    li t4, 8               # t4 = 8
    blez t3, exp_diff_le0      
    
    mv t5, a4              # t5 = result_exp    
    bgt t3, t4, return_a    
      
    srl a7, a7, t3          
    j sign_start
exp_diff_le0:
    bgez t3, exp_diff_eq0  
    mv t5, a5                  # t5 = result_exp
    neg t3, t3                 # t3 = -exp_diff
    bgt t3, t4, return_b      

    srl a6, a6, t3
    j sign_start
exp_diff_eq0:
    mv t5, a4                  # t5 = result_exp

sign_start:
    bne a2, a3, diff_sign_case  
same_sign_case:
    mv  t3, a2                     # t3 = result_sign
    add t4, a6, a7                 # t4 = result_mant

    andi t6, t4, 0x100             # t6 = result_mant & 0x100
    beqz t6, bf16_add_end         
    srli t4, t4, 1                 
    addi t5, t5, 1                 
    addi t6, t5, -0xFF             # t6 = ++result_exp - 0xFF
    bgez  t6, overflow_to_inf   

    j bf16_add_end                 
overflow_to_inf:
    slli a0, t3, 15
    li t6, 0x7F80
    or  a0, a0, t6
    j bf16_add_end
diff_sign_case:
    blt a6, a7, mant_a_smaller     
    mv  t3, a2                     # t3 = result_sign
    sub t4, a6, a7                 # t4 = result_mant
    j check_zero
mant_a_smaller:
    mv  t3, a3                     # t3 = result_sign
    sub t4, a7, a6                 # t4 = result_mant
check_zero:
    beqz t4, return_zero          

normalize_loop:
    andi t6, t4, 0x80              # t6 = result_mant & 0x80
    bnez t6, bf16_add_end             

    slli t4, t4, 1              
    addi t5, t5, -1                
    blez t5 return_zero           
    j normalize_loop

bf16_add_end:
    slli a0, t3, 15        # a0 = result_sign << 15
    andi t6, t5, 0xFF      # t1 = result_exp & 0xFF
    slli t6, t6, 7         # t6 << 7
    or a0, a0, t6          # a0 |= (result_exp & 0xFF) << 7

    andi t6, t4, 0x7F      # t6 = result_mant & 0x7F
    or a0, a0, t6          # a0 |= result_mant & 0x7F

    ret
    
bf16_sub:
    addi sp, sp, -16
    sw ra, 12(sp)         
    li   t3, 0x8000
    xor  a1, a1, t3       
    jal bf16_add
    lw ra, 12(sp)      
    addi sp, sp, 16
    ret 
#--------------------------------------------------------------
# return paths
#--------------------------------------------------------------

return_a:
    mv a0, a0
    ret
return_b:
    mv a0, a1
    ret
return_zero:
    li a0, 0                    
    ret

end:
    li a7, 10
    ecall