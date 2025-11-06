; Задача №2.2. Сумма двух чисел

%define MAX_INPUT_STR_SIZE 6        ; максимальная длина строки ввода
%define MAX_OUTPUT_STR_SIZE 100     ; максимальная длина буфера вывода

%define READ 0                       ; номер системного вызова read
%define WRITE 1                      ; номер системного вызова write
%define EXIT 60                      ; номер системного вызова exit

%define STDIN 0                      ; дескриптор стандартного ввода
%define STDOUT 1                     ; дескриптор стандартного вывода
%define STDERR 2                     ; дескриптор стандартного потока ошибок

%define NULL_CHAR 0                  ; нуль-терминатор
%define NEWLINE 0x0A                 ; символ перевода строки '\n'
%define ZERO_CHAR '0'                ; символ '0'
%define DASH_CHAR '-'                ; символ '-'

global _start                        ; точка входа программы

section .bss                         ; секция для глобальных неинициализированных переменных
    x1_str resb MAX_INPUT_STR_SIZE   ; буфер для первой введённой строки
    x2_str resb MAX_INPUT_STR_SIZE   ; буфер для второй введённой строки
    x1 resw 1                        ; переменная для хранения первого числа (16 бит)
    x2 resw 1                        ; переменная для хранения второго числа (16 бит)
    sum_str resb MAX_OUTPUT_STR_SIZE ; буфер для строки с суммой

section .data                        ; секция для константных данных
prompt1 db "Enter 1 number: ", 0     ; подсказка для ввода первого числа
len_prompt1 equ $-prompt1            ; длина подсказки 1

prompt2 db "Enter 2 number: ", 0     ; подсказка для ввода второго числа
len_prompt2 equ $-prompt2            ; длина подсказки 2

msg_result db "Answer: ", 0          ; сообщение перед выводом результата
len_msg_result equ $-msg_result      ; длина сообщения

newline db 0x0A                       ; символ новой строки

; Сообщения об ошибках
write_failed_msg db "Error: write() failed", 10, 0
write_failed_msg_len equ $-write_failed_msg

write_byte_number_mismatch_msg db "Error: write() write wrong number of bytes", 10, 0
write_byte_number_mismatch_msg_len equ $-write_byte_number_mismatch_msg

read_failed_msg db "Error: read() failed", 10, 0
read_failed_msg_len equ $-read_failed_msg

section .text                        ; секция кода

_start:                               ; точка входа программы
    xor r13, r13                      ; устанавливаем код завершения r13 = 0 (успех)

    ; ---- Prompt 1 ----
    mov rax, WRITE                     ; системный вызов write
    mov rdi, STDOUT                    ; дескриптор stdout
    lea rsi, [rel prompt1]             ; адрес буфера с подсказкой
    mov rdx, len_prompt1               ; длина подсказки
    syscall                             ; выполнить системный вызов
    test rax, rax                       ; проверяем возвращённое значение
    js write_failed_handler             ; если < 0, перейти к обработчику ошибки
    cmp rax, rdx                        ; проверяем, сколько байт записано
    jne write_byte_number_mismatch_handler ; если меньше ожидаемого, ошибка

    ; ---- Read first number ----
    lea rdi, [rel x1_str]              ; адрес буфера ввода строки
    lea rsi, [rel x1]                   ; адрес переменной для хранения числа
    call read_num                        ; вызов функции чтения и конвертации числа

    ; ---- Prompt 2 ----
    mov rax, WRITE
    mov rdi, STDOUT
    lea rsi, [rel prompt2]
    mov rdx, len_prompt2
    syscall
    test rax, rax
    js write_failed_handler
    cmp rax, rdx
    jne write_byte_number_mismatch_handler

    ; ---- Read second number ----
    lea rdi, [rel x2_str]
    lea rsi, [rel x2]
    call read_num

    ; ---- Add numbers ----
    movsx rax, word [rel x1]           ; расширяем первое число до 64 бит с сохранением знака
    movsx rbx, word [rel x2]           ; расширяем второе число до 64 бит с сохранением знака
    add rax, rbx                        ; складываем числа
    mov [rel x1], ax                     ; сохраняем результат в x1 (16 бит)

    ; ---- Print result message ----
    mov rax, WRITE
    mov rdi, STDOUT
    lea rsi, [rel msg_result]
    mov rdx, len_msg_result
    syscall
    test rax, rax
    js write_failed_handler
    cmp rax, rdx
    jne write_byte_number_mismatch_handler

    ; ---- Print sum ----
    movsx rax, word [rel x1]            ; расширяем сумму до 64 бит
    lea rsi, [rel sum_str]               ; адрес буфера вывода
    mov rdx, MAX_OUTPUT_STR_SIZE
    call print_num                       ; вызов функции печати числа

    ; ---- Print newline ----
    mov rax, WRITE
    mov rdi, STDOUT
    lea rsi, [rel newline]
    mov rdx, 1
    syscall
    test rax, rax
    js write_failed_handler
    cmp rax, 1
    jne write_byte_number_mismatch_handler

    ; ---- Exit ----
    jmp exit                             ; завершение программы

;; ---------------------------
;; read_num: чтение строки и конвертация в число
read_num:
    push rbp                             ; сохраняем rbp
    mov rbp, rsp                          ; устанавливаем новый базовый указатель
    push r12                              ; сохраняем r12
    mov r12, rsi                           ; r12 = адрес переменной для хранения числа
    mov rbx, rdi                           ; rbx = адрес буфера ввода

    mov rax, READ
    mov rdi, STDIN
    mov rsi, rbx
    mov rdx, MAX_INPUT_STR_SIZE
    syscall
    test rax, rax
    js read_failed_handler               ; если ошибка чтения

    mov rcx, rax
    dec rcx
    mov al, [rbx + rcx]
    cmp al, NEWLINE
    jne .no_newline
    mov byte [rbx + rcx], 0             ; заменяем '\n' на нуль-терминатор
.no_newline:
    mov rdi, rbx
    call str_to_num                      ; конвертация строки в число
    movsx rax, ax
    mov [r12], ax                         ; сохраняем результат

    pop r12
    pop rbp
    ret

;; ---------------------------
;; str_to_num: конвертация строки в знаковое число
str_to_num:
    push rbp
    mov rbp, rsp
    xor rax, rax
    xor rdx, rdx
    mov rsi, rdi
    mov bl, [rsi]
    cmp bl, DASH_CHAR
    jne .parse_loop
    mov dl, 1
    inc rsi
.parse_loop:
    mov bl, [rsi]
    cmp bl, NULL_CHAR
    je .done_parse
    sub bl, ZERO_CHAR
    imul rax, rax, 10
    movzx rbx, bl
    add rax, rbx
    inc rsi
    jmp .parse_loop
.done_parse:
    test dl, dl
    jz .ret_parse
    neg rax
.ret_parse:
    pop rbp
    ret

;; ---------------------------
;; print_num: вывод числа
print_num:
    push rbp
    mov rbp, rsp
    mov rdi, rax                         ; число для вывода
    lea rsi, [rel sum_str]               ; буфер для строки
    mov rdx, MAX_OUTPUT_STR_SIZE
    call num_to_str                       ; конвертация числа в строку
    mov rdi, rax                          ; указатель на строку
    call strlen                            ; вычисление длины строки
    mov rdx, rax                          ; длина для write
    mov rsi, rdi                          ; указатель на строку
    mov rax, WRITE
    mov rdi, STDOUT
    syscall
    test rax, rax
    js write_failed_handler
    cmp rax, rdx
    jne write_byte_number_mismatch_handler
    pop rbp
    ret

;; ---------------------------
strlen:
    push rbp
    mov rbp, rsp
    xor rax, rax
.next_chr:
    cmp byte [rdi + rax], 0
    je .done_strlen
    inc rax
    jmp .next_chr
.done_strlen:
    pop rbp
    ret

num_to_str:
    push rbp
    mov rbp, rsp
    mov rax, rdi                          ; число
    mov r10, rsi                           ; буфер
    mov r11, rdx                           ; размер буфера
    lea r12, [r10 + r11 - 1]               ; конец буфера
    mov byte [r12], 0                       ; нуль-терминатор
    xor r9, r9                              ; флаг отрицательного числа
    test rax, rax
    jns .conv_start
    mov r9b, 1
    neg rax
.conv_start:
    cmp rax, 0
    jne .loop_div
    dec r12
    mov byte [r12], '0'
    jmp .maybe_sign
.loop_div:
    xor rdx, rdx
    mov rcx, 10
    div rcx
    add dl, ZERO_CHAR
    dec r12
    mov [r12], dl
    test rax, rax
    jnz .loop_div
.maybe_sign:
    test r9b, r9b
    jz .finish_return
    dec r12
    mov byte [r12], DASH_CHAR
.finish_return:
    mov rax, r12                          ; возвращаем указатель на начало строки
    pop rbp
    ret

; ----------------------------
; Обработчики ошибок
; ----------------------------
write_failed_handler:                     ; ошибка write()
    mov r13, rax                          ; сохраняем код ошибки
    mov rax, WRITE
    mov rdi, STDERR
    mov rsi, write_failed_msg
    mov rdx, write_failed_msg_len
    syscall
    jmp exit

write_byte_number_mismatch_handler:       ; ошибка несоответствия количества байт
    mov r13, rax
    mov rax, WRITE
    mov rdi, STDERR
    mov rsi, write_byte_number_mismatch_msg
    mov rdx, write_byte_number_mismatch_msg_len
    syscall
    jmp exit

read_failed_handler:                       ; ошибка read()
    mov r13, rax
    mov rax, WRITE
    mov rdi, STDERR
    mov rsi, read_failed_msg
    mov rdx, read_failed_msg_len
    syscall
    jmp exit

exit:                                     ; завершение программы
    mov rdi, r13                           ; код завершения программы
    mov rax, EXIT
    syscall
