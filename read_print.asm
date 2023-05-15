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



main:
  #call read_dec
  call read_dec
  call print_dec
  exit_0

 
# |  caller  |
# | -------- |
# | dec num  |
# |----------|
# |  ra      |
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
  		   
  srli a1 a1 1	   #Рекурсивно вызваем функцию от a0/2
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
  mv s0 ra      #Перемещаем ra на caller-save регистр
  
  mv s1 a1      #Перемещаем a1 на caller-save регистр
  call div10    #Вычисляем целую часть от деления на 10
  
  li a2 0xA     #Результат умножаем на 10
  call mult     #a1 * a2     
  sub a1 s1 a1  #Вычисляем остаток
  
  #Эпилог
  mv ra s0     
  ret

read_dec:
  #Терминальная ветвь
  read_char t0
  li t1 10              #Если в t0 не символ конца строки
  bne t0 t1 read_nxt    #То продолжаем рекурсивно считывать знаки
  
  ret                   #Иначе возвращаемся вверх по рекурсии
  
  read_nxt:
  #Эпилог
  addi sp sp -4  #Выделяем 8 байт под фрейм
  sw ra 0(sp)   #Сохраняем ra по адрессу sp
    
   
  addi t0 t0 -48 #Приводим символ к цифре
  slli a1 a1 4   #Сдвигаем результат
  add a1 a1 t0   #Добавляем прочитанную цифру
  addi a2 a2 1      #Увеличиваем счетчик прочитанных чисел
  
  call read_dec  #Считываем следующий символ
  
  #Эпилог
  lw ra 0(sp)
  addi sp sp 4
  ret
  
#a1 - число, которое необходимо вывести
#a2 - количество знаков в нем
print_dec:
  #Терминальная ветвь
  bnez a2 print_digit #Если в числе остались цифры,
                      #То продолжаем печатать
                      
  ret                 #Возвращаемся вверх по рекурсии
  
  print_digit:
  #Пролог
  addi sp sp -16     #Выделяем 16 байт под фрейм
  sw ra 0(sp)        #Записываем ra
  sw s0 4(sp)        #Запоминаем волатильные регистры
  sw s1 8(sp)        #Которые попортятся в ходе программы
  sw s3 12(sp)
  
  mv s0 a1           #Сохраняем аргументы функции
  mv s1 a2           #т.к. a-регистры волатильные
                     #и не преживут вызова mod10
  
  li t0 0xF          #Вычисляем остаток от деления на 10 a1
  and a1 a1 t0
  mv s3 a1           #Запоминаем его
  
  mv a1 s0           #Подготавливаем следующий рекурсивный вызов
  srli a1 a1 4       
  addi a2 a2 -1
  
  call print_dec
  
  addi s3 s3 48
  put_char s3
  
  #Эпилог
  lw s3 12(sp)
  lw s2 8(sp)
  lw s1 4(sp)
  lw ra 0(sp)
  addi sp sp 16
  ret
  
  
  
   
  
  
  
  
  
