#идея:
#использовать s0 как указатель для адресации не динамической памяти
#потом выделить память под n чиселок и обращаться к ним через sp
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
  call read_dec
  call sieve
  mv a1 a0

exit_0


#---------------------------------------------------------------------
div10:
  #Терминальная ветвь
  li t0 0xA	      #Если параметр функции больше 10, то
  bge a0 t0 recursion #рекурсивно вычисляем результат
                   
  li a0 0           #Иначе результат известен
                    #загружаем ответ на a1
                    
  ret               #возвращаемся к вызывавшей функции
  
  recursion:
  #Пролог
  addi sp sp -8    #Выделяем фрейм размером 8 байт
  sw ra 4(sp)      #Сохраняем адресс возврата по ардрессу sp + 4
  
  sw a0 0(sp) 	   #Сохраняем параметр вызова по адресу sp
  		   #Он пригодится нам для вычислений после вызова
  		   
  srli a0 a0 1	   #Рекурсивно вызваем функцию от a0/2
  jal ra div10  
  
  lw t0 0(sp)      #Загружам в t0 параметр с которым была вызвана функция

  # 1/2 * (1/4 * x - (1/2 * x) * 1/10)

  srli t0 t0 2     # 1/4 * x
  sub  a0 t0 a0 
  srli a0 a0 1
  
  #Эпилог 
  lw ra 4(sp)
  addi sp sp 8
  ret
  
mult:
  li t0, 0  #res
 m_loop:
  andi t1, a1, 1 #bit 1?
  beqz t1, m_nonset
  add  t0, t0, a0 
  
 m_nonset:
    slli a0, a0, 1 #double first arg
    srli a1, a1, 1
    bnez a1, m_loop  
    mv a0, t0
    ret
 
mod10:
  #Пролог
  addi sp sp -8
  sw ra 4(sp)
  sw s1 0(sp)
  
  mv s1 a0      #Перемещаем a1 на caller-save регистр
  call div10    #Вычисляем целую часть от деления на 10
  
  li a1 0xA     #Результат умножаем на 10
  call mult     #a0 * a1     
  sub a0 s1 a0  #Вычисляем остаток
  
  #Эпилог
  lw s1 0(sp)
  lw ra 4(sp)  
  addi sp sp 8
  ret

read_dec:
  #Терминальная ветвь
  mv t6 a0
  read_char t0
  mv a0 t6
  li t1 10              #Если в t0 не символ конца строки P.S. 10 - код символа конца строки
  bne t0 t1 read_nxt    #То продолжаем рекурсивно считывать знаки
  
  ret                   #Иначе возвращаемся вверх по рекурсии
  
  read_nxt:
  #Эпилог
  addi sp sp -12  #Выделяем 8 байт под фрейм
  sw ra 0(sp)     #Сохраняем ra по адрессу sp
  sw s0 4(sp)
  sw s1 8(sp)
  
  mv s0 a1
  mv s1 t0
  addi s1 s1 -48 #Приводим символ к цифре
  li a1 10
  call mult      #Сдвигаем результат
  add a0 a0 s1   #Добавляем прочитанную цифру
  mv a1 s0
  addi a1 a1 1   #Увеличиваем счетчик прочитанных чисел
  
  call read_dec  #Считываем следующий символ
  
  #Эпилог
  lw ra 0(sp)
  lw s0 4(sp)
  lw s1 8(sp)
  addi sp sp 12
  ret
  
#a1 - число, которое необходимо вывести
#a2 - количество знаков в нем

print_dec:
  #Терминальная ветвь
  bnez a0 print_digit #Если в числе остались цифры,
                      #То продолжаем печатать
                      
  ret                 #Возвращаемся вверх по рекурсии
  
  print_digit:
  #Пролог
  addi sp sp -16     #Выделяем 16 байт под фрейм
  sw ra 0(sp)        #Записываем ra
  sw s0 4(sp)        #Запоминаем волатильные регистры
  sw s1 8(sp)        #Которые попортятся в ходе программы
  sw s3 12(sp)
  
  mv s0 a0           #Сохраняем аргументы функции
  mv s1 a1           #т.к. a-регистры волатильные
                     #и не преживут вызова mod10
  
  call mod10         #Вычисляем остаток от деления на 10 a1
  mv s3 a0           #Запоминаем его
  
  mv a0 s0           #Подготавливаем следующий рекурсивный вызов      
  call div10
  call print_dec
  
  addi s3 s3 48
  mv t6 a0
  put_char s3
  mv a0 t6
  
  #Эпилог
  lw s3 12(sp)
  lw s1 8(sp)
  lw s0 4(sp)
  lw ra 0(sp)
  addi sp sp 16
  ret
#-----------------------------------------------------


#Аргументы a0
#sieve выводит все простые числа до a0
sieve:

 
   #Пролог
   addi sp sp -20
   sw ra 0(sp)  #Сохраняем ra
   sw s0 4(sp)  #Сохраняем испорченный неволатильный регистр 
   sw s1 8(sp)
   sw s2 12(sp)
   sw s3 16(sp)
   
   mv s1 a0
   mv s0 sp     #Сохраняем текущее положение sp в неволатильный регистр
   
   slli a0 a0 2

   sub sp sp a0 #Выделяем a0 бит стековой памяти
   
   #Инициализируем массив единичками
   li t0 0 #в t0 лежит счетчик цикла

   li t1 1 #загружаем единичку, которой будем инициализировать массив
   while_array:

     add t2 sp t0              #Вычисляем текущее смещение от-но sp
     
     bge t2 s0 end_while_array #Если t0 указывает на память за
     			       #границей массива, то выйти из цикла
     			          
     sw t1, 0(t2)              #Записываем в массив бит по смещению
     addi t0 t0 4              #Инкрементируем счетчик цикла
     
     j while_array
     
     
   end_while_array:
   
   #*****
   #Начинается само решето
   
   li s2 1  #i:= s2 = 0 инициализируем счетчик цикла
   while_i_lt_n:
     addi s2 s2 1  #инкрементируем счетчик
     #теперь в t0 := a0 / 2 + 1
     srli t0 s1 1
     addi t0 t0 1
     bgt s2 t0 end_while_i_lt_n #Если прошли половину чисел, то выходим
     
     slli t0 s2 2 #Вычисляем индекс числа s2 в памяти
     add t0 t0 sp
     
     lw t1 0(t0)      #Загружаем из памяти пометку
     beqz t1 while_i_lt_n #continue, если число не простое
     #иначе   
     li s3 2          #Инициализируем 'счетчик' цикла            
     while_ij_le_n:      
       mv a0 s2       #Выбраннное простое число последовательно умножеаем на 2, 3...
       mv a1 s3
       call mult   
       
       bge a0 s1 end_while_ij_le_n #если получили число большее n, то останавливаем перебор
       
       slli t0 a0 2             #иначе вычисляем индекс числа в памяти
       add t0 t0 sp
       li t1 0
       sw t1 0(t0)              #обновляем пометку в памяти
       
       addi s3 s3 1             #инкрементируем счетчик
       j while_ij_le_n       
   end_while_ij_le_n:
   j while_i_lt_n
       
   end_while_i_lt_n:
   #выводим числа
   li s2 1 		       #Число, которое хотим вывести
   while_print_nums:
     addi s2 s2 1                    
     bge s2 s1 end_while_print_nums  #Если напечатали все числа, то break
     
     slli t0 s2 2                    #Вычисляем индекс числа в памяти
     add  t0 t0 sp
     
     lw t1 0(t0)                     #Загружаем пометку
     beqz t1 while_print_nums        #Если число не простое, то continue
      
     mv a0 s2                        #Печатаем простое число
     call print_dec              
     li a1 0xA                       #Символ конца строки
     put_char a1

     j while_print_nums
     
   end_while_print_nums:
     
   
   
   #Эпилог
   mv sp s0
   lw ra 0(sp)
   lw s0 4(sp)
   lw s1 8(sp)
   lw s2 12(sp)
   lw s3 16(sp)
   addi sp sp 20
   ret
   
   

