.text

#close program with exit code 0
.macro exit_0
  li a0, 0
  li a7, 93
  ecall
.end_macro

#read char to t0
.macro read_char
  li a0, 0
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

.macro put_int
  mv a0 t0
  li a7 1
  ecall
.end_macro


main:
  read_char
  slti a3 t0 0x2F #if hex in t0 less than 47(0x31) (askii(48) = '0') put 1 in a3 
  not  a3 a3      #make up statemet negative 
  slti a4 t0 0x3A #if hex in t0 less than 58(0x31) (askii(57) = '1') put 1 in a4
  and  t0 a3 a4
  bne  t0 zero if_statement #if expression is true put int
  exit_0
 
  if_statement: 
    put_int
  exit_0
