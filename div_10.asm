.text
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
#this macro transforms char in t0 to hex digit
.macro char_transform %frm
  slti s0 %frm 0x2F #if hex in %frm less than 47(0x31) (askii(48) = '0') put 1 in s0
  not  s0 s0        #make up statemet negative 
  slti s1 %frm 0x3A #if hex in %frm less than 58(0x31) (askii(57) = '1') put 1 in s1
  and  t1 s0 s1	    #
  bne  t1 zero ch_int 
  beq  t1 zero ch_num 
 
  ch_num: 
    addi %frm %frm -55 #diff between t0 and 55(A in askii) gives us hex digit greater than 9
    j end_transform
  ch_int:
    addi %frm %frm -48 #diff between t0 and 48(0 in askii) gives us hex digit less than 9
  end_transform:
  #set to 0 tmp registers
  li s0 0
  li s1 0
.end_macro
#this macro read's hex number to dst reg
.macro rd_hex_number %dst
  while_hex_digit:
    read_char t0 #read one digit of number
    mv t1 t0     #move digit to t1
    addi t1 t1 -10 #try to figure out is the digit is the end of the line
    beqz t1 while_hex_digit_end #if t1 is eoln break
    char_transform t0 #char transform
    slli %dst %dst 4 #multiply our hex number on 16
    add %dst %dst t0 #add one digit
    j while_hex_digit
  while_hex_digit_end:
  li t0 0
.end_macro  

.macro count_digits %frm %dst
  li %dst 0		#counter
  mv s2 %frm		#copy original number to s2 (it will corrupted)
  beqz s2 end_while_is_number #BUG!!!!!!!!!!!!1
  while_is_number:
    srli s2 s2 4 	#shift s2 to left while it is not zero 
    addi %dst %dst 1	#counting digits of %frm 
    beqz s2 end_while_is_number
    j while_is_number
  end_while_is_number:
.end_macro

.macro pr_hex_number %frm
  li s0 0xF	#s0 is mask register
  li s10 10     #reg used to compare digits
  count_digits %frm s3
  beqz s3 zero_number
  mv s11 s3
  addi s11 s11 -1
  slli s11 s11 2    #tmp register to store s3 * 4
  sll s0 s0 s11     #move mask to right position
  while_cnt_gz: #while counter in s3 greater than zero
    beqz s3 end_while_cnt_gz
    and s4 %frm s0 #used mask to chose digit of number
    srl s4 s4 s11 #shift digit to lower 'bit'
    blt s4 s10 print_digit
    bge s4 s10 print_hex_digit
    print_digit:
      addi s4 s4 48
      put_char s4
      j upd_mask_cnt
    print_hex_digit:
      addi s4 s4 55
      put_char s4
      # fallthrough
    upd_mask_cnt:
      addi s3 s3 -1 #update counter
      srli s0 s0 4   #update mask
      mv s11 s3
      addi s11 s11 -1
      slli s11 s11 2    #tmp register to store s3 * 4
      j while_cnt_gz
  zero_number:
    addi s4 s4 48
    put_char s4
  #some code here to fix bug
  end_while_cnt_gz:
.end_macro


main:
  rd_hex_number a1 #read first operand
  read_char a3
  li a4 0xA
  put_char a4 #print new line
  #operand code's
  # '/' 43 = 0x2B
  # '%' 45 = 0x25
  
  #try if operation is addition
  #i use t1 as tmp register for check
  addi t1 a3 -0x2B
  beqz t1 div_
  #if char in a3 is minus
  addi t1 a3 -0x25
  beqz t1 mod_
  
  div_:
    call div10
    pr_hex_number a1
    exit_0
  mod_:
    call mod10
    pr_hex_number a1
    exit_0

 
# |  caller  |
# |----------|
# |  ra      |
# | -------- |
# | dec num  |
# |----------|
#
div10:
  #Терминальная ветвь
  li t0 0xA	      #Если параметр функции больше 10, то
  bge a1 t0 recursion #рекурсивно вычисляем результат
                   
  li a1 0           #Иначе результат известен
                    #загружаем ответ на a1
                    
  ret               #возвращаемся к вызывавшей функции
  
  recursion:
  #Пролог
  addi sp sp -8    #Выделяем фрейм размером 8 байт
  sw ra 4(sp)      #Сохраняем адресс возврата по ардрессу sp + 4
  
  sw a1 0(sp) 	   #Сохраняем параметр вызова по адресу sp
  		   #Он пригодится нам для вычислений после вызова
  		   
  srli a1 a1 1	   #Рекурсивно вызваем функцию от a1/2
  jal ra div10  
  
  lw t0 0(sp)      #Загружам в t0 параметр с которым была вызвана функция

  # 1/2 * (1/4 * x - (1/2 * x) * 1/10)

  srli t0 t0 2     # 1/4 * x
  sub  a1 t0 a1 
  srli a1 a1 1
  
  #Эпилог 
  lw ra 4(sp)
  addi sp sp 8
  ret
  
mult:
  li t0, 0  #res
 m_loop:
  andi t1, a2, 1 #bit 1?
  beqz t1, m_nonset
  add  t0, t0, a1 
  
 m_nonset:
    slli a1, a1, 1 #double first arg
    srli a2, a2, 1
    bnez a2, m_loop  
    mv a1, t0
    ret
 
mod10:
  #Пролог
  #todo
  mv s0 ra      #Перемещаем ra на caller-save регистр
  
  mv s1 a1      #Перемещаем a1 на caller-save регистр
  call div10    #Вычисляем целую часть от деления на 10
  
  li a2 0xA     #Результат умножаем на 10
  call mult     #a1 * a2     
  sub a1 s1 a1  #Вычисляем остаток
  
  #Эпилог
  mv ra s0     
  ret









