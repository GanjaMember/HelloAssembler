; Задача №2.2. Сумма двух 16-битных чисел

; (*) Ошибки обработчиков ошибок не обрабатываются
; (*) r13 зарезервирован под код выполнения программы:
;   r13 = 0 - Успешное выполнение программы
;   r13 > 0 - Количество записанных байт не соотвествует ожидаемому значению
;   r13 < 0 - Системный вызов провалился

%define MAX_INPUT_STR_SIZE 6                            ; максимальная длина строки ввода
%define MAX_OUTPUT_STR_SIZE 100                         ; максимальная длина буфера вывода

%define READ 0                                          ; номер системного вызова read
%define WRITE 1                                         ; номер системного вызова write
%define EXIT 60                                         ; номер системного вызова exit

%define STDIN 0                                         ; дескриптор стандартного ввода
%define STDOUT 1                                        ; дескриптор стандартного вывода
%define STDERR 2                                        ; дескриптор стандартного потока ошибок

%define NULL_CHAR 0                                     ; нуль-терминатор
%define NEWLINE 0x0A                                    ; символ перевода строки '\n'

global _start                                           ; точка входа программы

section .bss                                            ; секция для глобальных неинициализированных переменных
    x1_str resb MAX_INPUT_STR_SIZE                      ; буфер для первой введённой строки
    x2_str resb MAX_INPUT_STR_SIZE                      ; буфер для второй введённой строки
    x1 resw 1                                           ; переменная для хранения первого числа (16 бит)
    x2 resw 1                                           ; переменная для хранения второго числа (16 бит)
    sum_str resb MAX_OUTPUT_STR_SIZE                    ; буфер для строки с суммой

section .data                                           ; секция для константных данных
    ; Подсказки в консоли
    prompt1 db "Enter 1 number: ", NULL_CHAR            ; подсказка для ввода первого числа
    len_prompt1 equ $-prompt1                           ; длина подсказки 1

    prompt2 db "Enter 2 number: ", NULL_CHAR            ; подсказка для ввода второго числа
    len_prompt2 equ $-prompt2                           ; длина подсказки 2

    msg_result db "Answer: ", NULL_CHAR                 ; сообщение перед выводом результата
    len_msg_result equ $-msg_result                     ; длина сообщения

    newline db 0x0A                                     ; символ новой строки

    ; Сообщения об ошибках
    write_failed_msg db "Error: write() failed", NEWLINE, NULL_CHAR
    write_failed_msg_len equ $-write_failed_msg

    write_byte_number_mismatch_msg db "Error: write() write wrong number of bytes", NEWLINE, NULL_CHAR
    write_byte_number_mismatch_msg_len equ $-write_byte_number_mismatch_msg

    read_failed_msg db "Error: read() failed", NEWLINE, NULL_CHAR
    read_failed_msg_len equ $-read_failed_msg

section .text                                           ; секция кода

_start:                                                 ; точка входа программы
    xor r13, r13                                        ; устанавливаем код завершения r13 = 0 (успех)

    ; ---- Промпт 1 ----
    mov rax, WRITE                                      ; системный вызов write
    mov rdi, STDOUT                                     ; дескриптор stdout
    lea rsi, [rel prompt1]                              ; адрес буфера с подсказкой
    mov rdx, len_prompt1                                ; длина подсказки
    syscall                                             ; выполнить системный вызов

    test rax, rax                                       ; проверка возвращенного значения rax (кол-во записанных байт)
    js write_failed_handler                             ; если rax < 0 (ошибка), прыжок к обработчику ошибки записи

    cmp rax, rdx                                        ; проверяем, совпадает ли количество записанных байт с ожидаемым
    jne write_byte_number_mismatch_handler              ; если нет, прыжок к обработчику несоответствия байт

    ; ---- Считываем первое число ----
    lea rdi, [rel x1_str]                               ; адрес буфера ввода строки
    lea rsi, [rel x1]                                   ; адрес переменной для хранения числа
    call read_num                                       ; вызов функции чтения и конвертации числа

    ; ---- Промпт 2 ----
    mov rax, WRITE
    mov rdi, STDOUT
    lea rsi, [rel prompt2]
    mov rdx, len_prompt2
    syscall

    test rax, rax                                       ; проверка возвращенного значения rax (кол-во записанных байт)
    js write_failed_handler                             ; если rax < 0 (ошибка), прыжок к обработчику ошибки записи

    cmp rax, rdx                                        ; проверяем, совпадает ли количество записанных байт с ожидаемым
    jne write_byte_number_mismatch_handler              ; если нет, прыжок к обработчику несоответствия байт

    ; ---- Считываем второе число ----
    lea rdi, [rel x2_str]                               ; адрес буфера ввода строки
    lea rsi, [rel x2]                                   ; адрес переменной для хранения числа
    call read_num

    ; ---- Складываем числа ----
    movsx rax, word [rel x1]                            ; расширяем первое число до 64 бит с сохранением знака
    movsx rbx, word [rel x2]                            ; расширяем второе число до 64 бит с сохранением знака
    add rax, rbx                                        ; складываем числа
    mov [rel x1], ax                                    ; сохраняем результат в x1 (16 бит)

    ; ---- Вывести подсказку к результату ----
    mov rax, WRITE
    mov rdi, STDOUT
    lea rsi, [rel msg_result]
    mov rdx, len_msg_result
    syscall

    test rax, rax                                       ; проверка возвращенного значения rax (кол-во записанных байт)
    js write_failed_handler                             ; если rax < 0 (ошибка), прыжок к обработчику ошибки записи

    cmp rax, rdx                                        ; проверяем, совпадает ли количество записанных байт с ожидаемым
    jne write_byte_number_mismatch_handler              ; если нет, прыжок к обработчику несоответствия байт

    ; ---- Вывести сумму ----
    movsx rax, word [rel x1]                            ; расширяем сумму до 64 бит
    lea rsi, [rel sum_str]                              ; адрес буфера вывода
    mov rdx, MAX_OUTPUT_STR_SIZE
    call print_num                                      ; вызов функции печати числа

    ; ---- Добавить новую строку ----
    mov rax, WRITE
    mov rdi, STDOUT
    lea rsi, [rel newline]
    mov rdx, 1
    syscall

    test rax, rax                                       ; проверка возвращенного значения rax (кол-во записанных байт)
    js write_failed_handler                             ; если rax < 0 (ошибка), прыжок к обработчику ошибки записи

    cmp rax, 1                                          ; проверяем, совпадает ли количество записанных байт с ожидаемым
    jne write_byte_number_mismatch_handler              ; если нет, прыжок к обработчику несоответствия байт

    ; ---- Выход ----
    jmp exit                                            ; завершение программы

; --------------------------------------------------
; Функция read_num: чтение строки и конвертация в число
; rdi = адрес введенной строки
; rsi = адрес переменной для хранения числа
; --------------------------------------------------
read_num:
    push rbp                                            ; сохраняем rbp
    mov rbp, rsp                                        ; устанавливаем новый базовый указатель

    ; сохраняем callee-saved регистры
    push r12
    push rbx

    mov rbx, rdi                                        ; rbx = адрес буфера ввода
    mov r12, rsi                                        ; r12 = адрес переменной для хранения числа

    mov rax, READ                                       ; передаем номер системного вызова
    mov rdi, STDIN                                      ; передаём дескриптор входного потока
    mov rsi, rbx                                        ; адрес буфера для сохранения введенной строки
    mov rdx, MAX_INPUT_STR_SIZE                         ; количество байтов для чтения
    syscall                                             ; выполнить системный вызов read


    test rax, rax
    js read_failed_handler                              ; если ошибка чтения

    mov rcx, rax                                        ; сохраняем длину строки
    dec rcx                                             ; делаем указателем на последний индекс
    mov al, [rbx + rcx]                                 ; сохраняем последний символ в регистр
    cmp al, NEWLINE                                     ; проверяем на '\n'
    jne .no_newline
    mov byte [rbx + rcx], NULL_CHAR                     ; заменяем '\n' на нуль-терминатор

.no_newline:
    mov rdi, rbx
    call str_to_num                                     ; конвертация строки в число
    movsx rax, ax
    mov [r12], ax                                       ; сохраняем результат по адресу в указателе

    pop rbx
    pop r12
    pop rbp
    ret

; --------------------------------------------------
; Функция str_to_num: конвертация строки в знаковое число
; rdi = адрес строки
; --------------------------------------------------
str_to_num:
    push rbp                                            ; сохраняем rbp
    mov rbp, rsp                                        ; устанавливаем новый базовый указатель

    xor rax, rax                                        ; обнуляем rax
    xor rdx, rdx                                        ; обнуляем rdx
    mov rsi, rdi                                        ; сохраняем адрес строки

    mov bl, [rsi]                                       ; сохраняем символ по нулевому индексу
    cmp bl, '-'                                         ; проверяем на минус
    jne .parse_loop                                     ; если минуса нету, то сразу переходим к преобразованию
    mov dl, 1                                           ; устанавливаем флаг "отрицательное число" в 1
    inc rsi                                             ; пропускаем знак минуса
.parse_loop:
    mov bl, [rsi]                                       ; сохраняем текущий символ из адреса в указателе
    cmp bl, NULL_CHAR                                   ; итерируемся до null-терминатора
    je .done_parse                                      ; если дошли до '\0', то цикл заканчивается
    sub bl, '0'                                         ; переводим символ цифры в число
    imul rax, rax, 10                                   ; знаковое умножение: arg1 - регистр результата, arg2 - регистр множителя, arg3 - константа
    movzx rbx, bl                                       ; movzx - move zero extended, расширяем нулями 8-битный регистр до 64-битного
    add rax, rbx                                        ; прибавляем цифру в конец числа                 
    inc rsi                                             ; увеличиваем индекс
    jmp .parse_loop
.done_parse:
    test dl, dl                                         ; проверка флага "отрицательного числа"
    jz .finish_return
    neg rax                                             ; инвертируем знак числа
.finish_return:
    pop rbp
    ret

; --------------------------------------------------
; Функция read_num: вывод числа
; rax = число
; rsi = адрес буфера вывода
; rdi = количество байт для вывода
; --------------------------------------------------
print_num:
    push rbp
    mov rbp, rsp

    mov rdx, rdi                                        ; передаем количество байт для вывода в num_to_str
    mov rdi, rax                                        ; передаем число в num_to_str
    ; также передаём rsi и rdx
    call num_to_str                                     ; конвертация числа в строку

    mov rdi, rax                                        ; указатель на первый байт новой строки
    call strlen                                         ; вычисление длины строки
    mov rdx, rax                                        ; длина для write
    mov rsi, rdi                                        ; указатель на строку
    mov rax, WRITE
    mov rdi, STDOUT
    syscall

    test rax, rax                                       ; проверка возвращенного значения rax (кол-во записанных байт)
    js write_failed_handler                             ; если rax < 0 (ошибка), прыжок к обработчику ошибки записи

    cmp rax, rdx                                        ; проверяем, совпадает ли количество записанных байт с ожидаемым
    jne write_byte_number_mismatch_handler              ; если нет, прыжок к обработчику несоответствия байт

    pop rbp
    ret

; --------------------------------------------------
; Функция num_to_str: конвертация числа в строку
; rdi = число
; rsi = адрес строки результата
; rdx = размер строки результата
; Возвращает в rax: указатель на первый байт новой строки
; --------------------------------------------------
num_to_str:
    push rbp
    mov rbp, rsp

    mov rax, rdi                                        ; сохраняем число в rax для дальнейшего div
    mov r10, rdx                                        ; сохраняем параметр

    lea r11, [rsi + r10 - 1]                            ; сохраняем адрес последнего индекса буфера
    mov byte [r11], NULL_CHAR                           ; ставим в конец строки нуль-терминатор

    xor r9, r9                                          ; флаг отрицательного числа
    test rax, rax                                       ; проверяем число на отрицательность
    jns .parse_start

    mov r9b, 1                                          ; помещаем 1 в 8-битовый r9 регистр, остальные 56 бит не изменяются
    neg rax                                             ; конвертируем дополнительный код к обычному
.parse_start:
    cmp rax, 0                                          ; проверяем на нулевое число                 
    jne .parse_loop
    dec r11                                             ; передвигаем указатель на предпоследний индекс
    mov byte [r11], '0'                                 ; помещаем туда символ нуля
    jmp .check_sign                                     ; сразу переходим к следующему блоку обработки
.parse_loop:
    xor rdx, rdx                                        ; обнуляем rdx - верхняя половина rdx:rax перед делением и остаток после деления
    mov rcx, 10                                         ; передаем 10 в регистр для div
    div rcx                                             ; беззнаковое деление объединненного rdx:rax на другой регистр, частное записывается в rax
    add dl, '0'                                         ; прибавляем к остатку (цифре) код символа '0'
    dec r11                                             ; передвигаем указатель влево
    mov [r11], dl                                       ; сохраняем символ цифры по адресу в указателе
    test rax, rax                                       ; проверяем частное на ноль
    jnz .parse_loop
.check_sign:
    test r9b, r9b                                       ; проверяем флаг отрицательного числа
    jz .finish_return                                   ; если не установлен, выходим из функции
    dec r11                                             ; передвигаем указатель влево
    mov byte [r11], '-'                                 ; сохраняем символ минуса по адресу в указателе
.finish_return:
    mov rax, r11                                        ; возвращаем указатель на начало строки
    pop rbp
    ret

; --------------------------------------------------
; Функция strlen: вычисление длины строки
; rdi = адрес строки
; Возвращает в rax: длину строки
; --------------------------------------------------
strlen:
    push rbp
    mov rbp, rsp

    xor rax, rax
.next_chr:
    cmp byte [rdi + rax], NULL_CHAR
    je .finish_return
    inc rax
    jmp .next_chr
.finish_return:
    pop rbp
    ret

; ----------------------------
; Обработчики ошибок
; ----------------------------
write_failed_handler:                                   ; метка обработчика ошибки write()
    mov r13, rax                                        ; сохраняем код ошибки

    mov rax, WRITE                                      ; системный вызов write
    mov rdi, STDERR                                     ; дескриптор потока ошибок
    lea rsi, [rel write_failed_msg]                     ; адрес сообщения
    mov rdx, write_failed_msg_len                       ; длина сообщения
    syscall                                             ; выполняем системный вызов write

    jmp exit                                            ; завершение программы

write_byte_number_mismatch_handler:                     ; метка обработчика несоответствия байт
    mov r13, rax                                        ; сохраняем код ошибки

    mov rax, WRITE                                      ; системный вызов write
    mov rdi, STDERR                                     ; дескриптор потока ошибок
    lea rsi, [rel write_byte_number_mismatch_msg]       ; адрес сообщения
    mov rdx, write_byte_number_mismatch_msg_len         ; длина сообщения
    syscall                                             ; выполняем системный вызов write

    jmp exit                                            ; завершение программы

read_failed_handler:                                    ; метка обработчика ошибки read()
    mov r13, rax                                        ; сохраняем код ошибки

    mov rax, WRITE                                      ; системный вызов write
    mov rdi, STDERR                                     ; дескриптор потока ошибок
    lea rsi, [rel read_failed_msg]                      ; адрес сообщения
    mov rdx, read_failed_msg_len                        ; длина сообщения
    syscall                                             ; выполняем системный вызов write

    jmp exit                                            ; завершение программы

exit:                                                   ; завершение программы
    mov rdi, r13                                        ; код завершения программы
    mov rax, EXIT
    syscall
