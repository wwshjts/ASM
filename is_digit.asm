.text

.macro exit_0
  li a0, 0
  li a7, 93
  ecall
.end_macro

.macro read_char
  li a0, 0
  li a7, 12
  ecall
  mv t0 a0
.end_macro

.macro put_char
  mv a0 t0
  li a7 11
  ecall
.end_macro
main:
  read_char
  slti a3 t0 0x31
  slti a4 t0 0x3A
  addi a3 a3 
  exit_0