; Ошибки обработчиков ошибок не обрабатываются

global _start                                           ; делаем метку _start видимой извне

section .data                                           ; секция данных
    hello_msg db "Hello World!", 10                     ; строка для вывода на консоль, 10 - ascii код переноса строки
    hello_msg_len equ $ - hello_msg

    outputfile db "hello_world.txt", 0                  ; объявление имени файла в формате asciz, 0 - ascii код null terminator

    open_error_msg db "Error: open() failed", 10, 0
    open_error_msg_len equ $ - open_error_msg

    write_error_msg db "Error: write() failed", 10, 0
    write_error_msg_len equ $ - write_error_msg

    close_error_msg db "Error: close() failed", 10, 0
    close_error_msg_len equ $ - close_error_msg

section .text                                           ; объявление секции кода
_start:                                                 ; точка входа в программу
    xor r13, r13                                        ; обнуляем r13, резервируем его для хранения кода ошибки

    ; Блок создания файла
    mov rax, 2                                          ; 2 - номер системного вызова функции open
    mov rdi, outputfile                                 ; передаём имя файла
    ; O_WRONLY - режим write-only
    ; O_CREAT - если файла нету, то создать новый
    ; O_TRUNC - если файл существует, то удалить содержимое
    mov rsi, 0x241                                      ; сумма флагов: O_CREAT | O_WRONLY | O_TRUNC (0x1 + 0x40 + 0x200)
    ; rw- разрешаем создателю read и write,
    ; r-- и r-- остальным read-only
    mov rdx, 0644o                                      ; разрешения: rw-r--r--
    syscall                                             ; выполняем системный вызов

    ; Обрабатываем ошибку
    test rax, rax                                       ; проверяем знаковый флаг
    js open_error_handler                               ; js - "jump if sign flat is set"
    mov r12, rax                                        ; сохраняем идентификатор файла

    ; Блок записи данных в файл
    mov rax, 1                                          ; 1 - номер системного вызова функции write
    mov rdi, r12                                        ; передаём идентификатор файла, полученный после выполнения open
    mov rsi, hello_msg                                  ; адрес строки для вывода
    mov rdx, hello_msg_len                              ; количество байтов
    syscall                                             ; выполняем системный вызов

    test rax, rax                                       ; проверяем знаковый флаг
    js write_error_handler                              ; js - "jump if sign flat is set"

    ; Блок закрытия файла
    jmp close_file

open_error_handler:
    mov r13, rax                                        ; сохраняем код ошибки

    mov rax, 1                                          ; 1 - номер системного вызова функции write
    mov rdi, 2                                          ; 2 - дескриптор файла стандартного вызова stderr
    mov rsi, open_error_msg                             ; адрес строки для вывода
    mov rdx, open_error_msg_len                         ; количество байтов
    syscall                                             ; выполняем системный вызов

    mov rax, r13
    jmp exit

write_error_handler:
    mov r13, rax                                        ; сохраняем код ошибки

    mov rax, 1                                          ; 1 - номер системного вызова функции write
    mov rdi, 2
    mov rsi, write_error_msg
    mov rdx, write_error_msg_len
    syscall                                             ; выполняем системный вызов

    jmp close_file

close_error_handler:
    mov r13, rax

    mov rax, 1                                          ; 1 - номер системного вызова функции write
    mov rdi, 2
    mov rsi, close_error_msg
    mov rdx, close_error_msg_len
    syscall                                             ; выполняем системный вызов

    mov rax, r13
    jmp exit

close_file:
    ; Блок закрытия файла
    mov rax, 3                                          ; 3 - номер системного вызова функции close
    mov rdi, r12                                        ; указываем идентификатор файла
    syscall                                             ; выполняем системный вызов

    test rax, rax
    js close_error_handler

    test r13, r13
    js save_write_error_code

    jmp exit

save_write_error_code:
    mov rax, r13
    jmp exit

exit:                                                   ; метка выхода
    mov rdi, rax                                        ; rax - хранит код выполнения программы
    mov rax, 60                                         ; 60 - номер системного вызова exit()
    syscall                                             ; выполняем системный вызов
