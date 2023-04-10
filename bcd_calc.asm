.macro read_char %rd_to
  li a7, 12
  ecall
  mv %rd_to a0
.end_macro

#put char from %dst
.macro put_char %dst
  mv a0 %dst
  li a7 11
  ecall
.end_macro
#exit macro
.macro exit_0
  li a0, 0
  li a7, 93
  ecall
.end_macro
.macro normal_and %dst %a1 %a2 
  li t0 0
  li t1 0
  bnez %a1 a1_zero #if a1 is zero mv 1 to %a1 
  end_a1_zero:
  bnez %a2 a2_zero#if a2 is zero mv 1 to %a2
  end_a2_zero:
  j end_normal_and
  a1_zero:
    li t0 1
    j end_a1_zero
  a2_zero:
    li t1 1
    j end_a2_zero
  end_normal_and:
    and %dst t0 t1
    mv t0 zero
    mv t1 zero
.end_macro
.macro rd_bcd_number %dst %cnt
  while_hex_digit:
    read_char t0 #read one digit of number
    mv t1 t0     #move digit to t1
    addi t1 t1 -10   #try to figure out is the digit is the end of the line
    beqz t1 while_hex_digit_end #if t1 is eoln break
    addi %cnt %cnt 1
    addi t0 t0 -48   #get value of char
    slli %dst %dst 4 #multiply our hex number on 16
    add %dst %dst t0 #add one digit
    j while_hex_digit
  while_hex_digit_end:
  li t0 0
.end_macro  

.macro sum_bcd %x %y %cnt_x %cnt_y
  #register's list
  #x - first operand; y - second operand
  #s1 - amount of digit's in first operand; s2 in second
  #s0 - overflow reg
  li s0 0  #s0 - overflow reg
  mv s1 %cnt_x
  mv s2 %cnt_y
  normal_and s3 s1 s2 #flag if one of number is null
  li s4 0x6
  li s5 0xF
  li s6 0 #tmp register for digit of first operator
  li s7 0 #tmp register for digit of second operator
  li s8 0 #tmp register for sum of current digits
  while_digits_left:
    beqz s3 end_while_digits_left
    and s6 %x s5 #take current digit of first operator
    and s7 %y s5 #take current digit of second operator
    add s8 s6 s7 #add two digits
    add s8 s8 s4  #try to overflow
    srli s8 s8 4
    normal_and s0 s8 s7 #check the overflow 
    bnez s0 overflow
    end_overflow:
    add %x %x s7
    addi s1 s1 -1
    addi s2 s2 -1 
    slli s4 s4 4
    slli s5 s5 4
    normal_and s3 s1 s2
    
    j while_digits_left
    overflow:
      add %x %x s4 #correct bit's
      j end_overflow
            
  end_while_digits_left:
  
.end_macro

main:
  #register's
  #s10 contains amount of digit's in first operand
  #s11 contains amount of digit's in second operand
  rd_bcd_number a1 s10
  rd_bcd_number a2 s11
  sum_bcd a1 a2 s10 s11
  exit_0