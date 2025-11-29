; (*) Ошибки обработчиков ошибок не обрабатываются
; (*) r13 зарезервирован под код выполнения программы:
;   r13 = 0 - Успешное выполнение программы
;   r13 > 0 - Количество записанных байт не соотвествует ожидаемому значению
;   r13 < 0 - Системный вызов провалился

%define EXIT 60         ; 60 - номер системного вызова exit
%define WRITE 1         ; 1 - номер системного вызова write

%define STDOUT 1        ; 1 - дескриптор стандартного вывода
%define STDERR 2        ; 2 - дескриптор стандартного потока ошибок

%define NULL_CHAR 0     ; код символа '\0'
%define NEWLINE 0x0A    ; код символа перевода строки '\n'

global _start                                           ; делаем метку _start видимой извне

section .data                                           ; секция данных
    hello_msg db "Hello World!", NEWLINE                ; строка для вывода на консоль
    hello_msg_len equ $ - hello_msg

    write_failed_msg db "Error: write() failed", NEWLINE, NULL_CHAR                                     ; сообщение об ошибке write
    write_failed_msg_len equ $ - write_failed_msg                                                       ; длина сообщения
    write_byte_number_mismatch_msg db "Error: write() write wrong number of bytes", NEWLINE, NULL_CHAR  ; ошибка записи неправильного количества байт
    write_byte_number_mismatch_msg_len equ $ - write_byte_number_mismatch_msg                           ; длина сообщения

section .text                                           ; объявление секции кода
_start:                                                 ; точка входа в программу
    xor r13, r13                                        ; обнуляем r13, резервируем его для хранения кода ошибки

    ; Блок записи данных в файл
    mov rax, WRITE                                      ; указываем код системного вызова
    mov rdi, STDOUT                                     ; передаём код дескриптора
    mov rsi, hello_msg                                  ; адрес строки для вывода
    mov rdx, hello_msg_len                              ; количество байтов
    syscall                                             ; выполняем системный вызов

    test rax, rax                                       ; проверяем знаковый флаг
    js write_failed_handler                             ; js - "jump if sign flag is set"

    cmp rax, rdx
    jne write_byte_number_mismatch_handler

    ; Блок выхода из программы
    jmp exit

write_failed_handler:
    mov r13, rax                                        ; сохраняем отрицательный код ошибки

    mov rax, WRITE                                      ; указываем код системного вызова
    mov rdi, STDERR                                     ; передаём код дескриптора
    mov rsi, write_failed_msg                           ; адрес строки для вывода
    mov rdx, write_failed_msg_len                       ; количество байтов
    syscall                                             ; выполняем системный вызов

    jmp exit

write_byte_number_mismatch_handler:                     ; метка обработчика несоответствия байт
    mov r13, rax                                        ; сохраняем код ошибки

    mov rax, WRITE                                      ; указываем код системного вызова
    mov rdi, STDERR                                     ; передаём код дескриптора
    mov rsi, write_byte_number_mismatch_msg             ; адрес сообщения
    mov rdx, write_byte_number_mismatch_msg_len         ; длина сообщения
    syscall                                             ; выполняем системный вызов

    jmp exit                                            ; завершение программы

exit:                                                   ; метка выхода
    mov rdi, r13                                        ; передаём код выполнения программы
    mov rax, EXIT                                       ; указываем код системного вызова
    syscall                                             ; выполняем системный вызов
