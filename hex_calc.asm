.text
#read char to t0
.macro read_char
  li a7, 12
  ecall
  mv t0 a0
.end_macro

#put char from t0
.macro put_char
  mv a0 t0 
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
.macro rd_hex_number
  while_hex_digit:
    read_char
    mv t1 t0
    addi t1 t1 -10 #try to figure out is the char is the end of the line
    beqz t1 while_hex_digit_end
    char_transform
    slli a1 a1 4
    add a1 a1 t0
    j while_hex_digit
   while_hex_digit_end:
.end_macro   
    
    
    
    
    
main: 
  rd_hex_number
  #mv t1 t0 #read first operand to t1
  #read_int 
  #mv t2 t0 #read second operand to t2
  #read_char
  #mv a1 t0 #read operation to a1
  
  #operand code's
  # '+' 43 = 0x2B
  # '-' 45 = 0x2D
  # '&' 38 = 0x23
  # '|' 124 = 0x7C
  
  #addi t0 a1 -0x2B
  #beq t0 zero addition
  exit_0
  addition:
    exit_0
  
  
  
  