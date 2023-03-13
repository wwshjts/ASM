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
  put_char
  addi t0 t0 1
  put_char
  exit_0

