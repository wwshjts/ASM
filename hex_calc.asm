.text
#read char
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

#close program with exit code 0
.macro exit_0
  li a0, 0
  li a7, 93
  ecall
.end_macro

.macro char_transform 
  slti a3 t0 0x2F #if hex in t0 less than 47(0x31) (askii(48) = '0') put 1 in a3 
  not  a3 a3      #make up statemet negative 
  slti a4 t0 0x3A #if hex in t0 less than 58(0x31) (askii(57) = '1') put 1 in a4
  and  t1 a3 a4
  bne  t1 zero ch_int 
  beq  t1 zero ch_num 
 
  ch_int: 
    from_num_to_num t0
    j end_transform
  ch_num:
    from_char_to_num t0
  end_transform:
.end_macro


.macro from_char_to_num %n
  addi %n %n -55
.end_macro

.macro from_num_to_num %n
  addi %n %n -48
.end_macro

#read hex_number
.macro rd_hex_number %dst
  while_hex_digit:
    read_char t0
    mv t1 t0
    addi t1 t1 -10 #try to figure out is the char is the end of the line
    beqz t1 while_hex_digit_end
    char_transform
    slli %dst %dst 4
    add %dst %dst t0
    j while_hex_digit
  while_hex_digit_end:
.end_macro   
.macro hex_transform %frm
  addi t3 zero 10 
  addi t4 zero 16
  mv t6 %frm
  while_not_last:
    blt t6 t4 end_not_last 
    srli t6 t6 4
    j while_not_last
  end_not_last:
  mv %frm t6 
  blt t6 t3 digit
  bge t6 t3 char
  digit:
    addi %frm %frm 48
    j end_hex_transform
  char:
    addi %frm %frm 55
  end_hex_transform:
.end_macro
.macro pr_hex_number %frm
  li a1 0xF #a1 is register that contains info about digit in n
  while_not_gd:
    and t0 a1 %frm #is we null all digits? 
    beqz t0 end_not_gd
    slli a1 a1 4 #mv digits left
    j while_not_gd
  end_not_gd:
  srli a1 a1 4
  while_t1: #start to write num
    beqz a1 end
    and t0 a1 %frm
    srli a1 a1 4
    hex_transform t0
    put_char t0
    j while_t1
  end:
    
.end_macro

#print hex_number
    
    
    
    
    
main: 
  rd_hex_number a1 #read first operand
  rd_hex_number a2 #read second operand
  read_char a3
  #operand code's
  # '+' 43 = 0x2B
  # '-' 45 = 0x2D
  # '&' 38 = 0x26
  # '|' 124 = 0x7C
  
  #try if operation is addition
  #i use t1 as tmp register for check
  addi t1 a3 -0x2B
  beqz t1 addition 
  li t1 0
  #try if operation in a3 is difference
  addi t1 a3 -0x2D
  beqz t1 diff
  li t1 0
  #try if operation in a3  is &
  addi t1 a3 -0x26
  beqz t1 conj 
  li t1 0
  #try if operation in a3 is |
  addi t1 a3 -0x7C
  beqz t1 disj
  li t1 0
  exit_0
  
  addition:
    add t2 a1 a2
    pr_hex_number t2
    exit_0
    
  diff:
    sub t2 a1 a2
    pr_hex_number t2
    exit_0
    
  conj: 
    and t2 a1 a2
    pr_hex_number t2
    exit_0
    
  disj:
    or t2 a1 a2
    pr_hex_number t2
    exit_0
  
  
  
  
  
