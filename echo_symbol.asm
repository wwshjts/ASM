.text

.macro exit_0
  li a0, 0
  li a7, 93
  ecall
.end_macro

.macro read_char %rg
  mv a0, zero
  li a7, 12
  ecall
  mv %rg a0
.end_macro

.macro put_char %rg
  mv a0 %rg
  li a7 11
  ecall
.end_macro

main:
  addi t1 zero 0x20
  addi t2 zero 0xA
  while_char:
    read_char t0
    addi a1 t0 -0xA
    beqz a1 end_while
    put_char  t1 #print space
    put_char  t0 #echo symbol
    put_char  t1 #print space
    addi t0 t0 1 #inc asii code
    put_char  t0 #print incremendet symbol
    put_char  t2
    j while_char
  end_while:
  exit_0

