; Задача №2.1. Разворот входящей строки

; Объявление констант
%define MAX_INPUT_STR_SIZE 100  ; максимальный размер входной строки 100 символов

%define EXIT 60                 ; 60 - номер системного вызова exit
%define READ 0                  ; 0 - номер системного вызова read
%define WRITE 1                 ; 1 - номер системного вызова write

%define STDIN 0                 ; 0 - дескриптор стандартного ввода
%define STDOUT 1                ; 1 - дескриптор стандартного вывода
%define STDERR 2                ; 2 - дескриптор стандартного потока ошибок

%define NULL_CHAR 0             ; код символа '\0'
%define NEWLINE 0x0A            ; код символа перевода строки '\n'

global _start   ; делаем точку входа _start видимой для линковщика

section .bss    ; Секция BSS — для глобальных неинициализированных переменных
    input_str resb MAX_INPUT_STR_SIZE               ; буфер для ввода строки
    reverse_str resb MAX_INPUT_STR_SIZE             ; буфер для развернутой строки

section .data                                       ; секция данных
    ; Подсказки в консоли
    prompt1 db "Enter your string: ", NULL_CHAR     ; подсказка для ввода строки
    len_prompt1 equ $-prompt1                       ; длина подсказки 1

    msg_result db "Reversed: ", NULL_CHAR           ; подсказка для вывода перевернутой строки
    len_msg_result equ $-msg_result                 ; длина подсказки результата

    ; Сообщения об ошибках
    write_failed_msg db "Error: write() failed", NEWLINE, NULL_CHAR                                     ; сообщение об ошибке write
    write_failed_msg_len equ $ - write_failed_msg                                                       ; длина сообщения
    write_byte_number_mismatch_msg db "Error: write() write wrong number of bytes", NEWLINE, NULL_CHAR  ; ошибка записи неправильного количества байт
    write_byte_number_mismatch_msg_len equ $ - write_byte_number_mismatch_msg                           ; длина сообщения

    read_failed_msg db "Error: read() failed", NEWLINE, NULL_CHAR                                       ; сообщение об ошибке read
    read_failed_msg_len equ $ - read_failed_msg                                                         ; длина сообщения

section .text

_start:     ; точка входа программы
    xor r13, r13                            ; устанавливаем код завершения r13 = 0 (успех)

    ; ---- Промпт 1 ----
    mov rax, WRITE
    mov rdi, STDOUT
    lea rsi, [rel prompt1]
    mov rdx, len_prompt1
    syscall

    test rax, rax                           ; проверка возвращенного значения rax (кол-во записанных байт)
    js write_failed_handler                 ; если rax < 0 (ошибка), прыжок к обработчику ошибки записи

    cmp rax, rdx                            ; проверяем, совпадает ли количество записанных байт с ожидаемым
    jne write_byte_number_mismatch_handler  ; если нет, прыжок к обработчику несоответствия байт

    ; Чтение строки с клавиатуры
    mov rax, READ                           ; номер системного вызова read
    mov rdi, STDIN                          ; дескриптор входного потока (stdin)
    mov rsi, input_str                      ; адрес буфера для сохранения введенной строки
    mov rdx, MAX_INPUT_STR_SIZE             ; количество байтов для чтения
    syscall                                 ; выполнить системный вызов read

    test rax, rax                           ; проверяем возвращенное значение rax (кол-во прочитанных байт)
    js read_failed_handler                  ; если rax < 0 (ошибка), прыжок к обработчику ошибки чтения

    mov rbx, rax                            ; сохраняем длину введённой строки в rbx

    mov rdi, rbx                            ; передаем длину в rdi для функции reverse_string
    mov rsi, NEWLINE                        ; передаем завершающий байт
    call reverse_string                     ; вызываем функцию разворота строки
    mov rbx, rdi                            ; обновляем длину строки после разворота (rdi возвращает длину)

    ; ---- Вывести подсказку к результату ----
    mov rax, WRITE
    mov rdi, STDOUT
    lea rsi, [rel msg_result]
    mov rdx, len_msg_result
    syscall

    test rax, rax                           ; проверка возвращенного значения rax (кол-во записанных байт)
    js write_failed_handler                 ; если rax < 0 (ошибка), прыжок к обработчику ошибки записи

    cmp rax, rdx                            ; проверяем, совпадает ли количество записанных байт с ожидаемым
    jne write_byte_number_mismatch_handler  ; если нет, прыжок к обработчику несоответствия байт

    ; Запись развернутой строки на стандартный вывод
    mov rax, WRITE                          ; системный вызов write
    mov rdx, rbx                            ; количество байт для записи
    mov rdi, STDOUT                         ; дескриптор stdout
    mov rsi, reverse_str                    ; адрес буфера с развернутой строкой
    syscall                                 ; выполняем системный вызов write

    test rax, rax                           ; проверка возвращенного значения rax (кол-во записанных байт)
    js write_failed_handler                 ; если rax < 0 (ошибка), прыжок к обработчику ошибки записи

    cmp rax, rbx                            ; проверяем, совпадает ли количество записанных байт с ожидаемым
    jne write_byte_number_mismatch_handler  ; если нет, прыжок к обработчику несоответствия байт

    jmp exit                                ; завершение программы

; --------------------------------------------------
; Функция reverse_string:
; rdi = длина строки
; rsi = завершающий байт
; Использует input_str и reverse_str из .bss
; --------------------------------------------------
reverse_string:
    push rbp                                ; сохраняем базовый указатель прошлого стекового фрейма
    mov rbp, rsp                            ; устанавливаем новый базовый указатель

    test rdi, rdi                           ; rdi & rdi, 0 - пустая строка
    jz .end_if                              ; если строка пустая, то отступ делать не надо

    dec rdi                                 ; делаем отступ к последнему индексу строки
    cmp byte [input_str + rdi], NEWLINE     ; проверяем послендний индекс на символ '\n'
    je .end_byte_present                    
    cmp byte [input_str + rdi], NULL_CHAR   ; проверяем послендний индекс на символ '\0'
    jz .end_byte_present

    jmp .end_if                             ; у строки нет заканчивающего байта, отступ делать не надо

    .end_byte_present:
    dec rdi                                 ; отступ для пропуска '\0' или '\n' в конце строки

    .end_if:

    xor r10, r10                            ; r10 = 0, индекс для записи в reverse_str

.loop:                                      ; локальная метка начала цикла
    cmp r10, rdi                            ; проверяем, достигли ли конца строки
    jg .done                                ; jump if greater or equal, если r10 > последнего индекса, завершить цикл

    mov rax, rdi                            ; rax = последний индекс строки
    sub rax, r10                            ; rax = последний индекс, смещенный на r10 влево
    mov bl, [input_str + rax]               ; читаем символ с конца input_str
    mov byte [reverse_str + r10], bl        ; записываем символ в reverse_str

    inc r10                                 ; увеличиваем индекс назначения
    jmp .loop                               ; повторяем цикл

.done:                                      ; локальная метка окончания цикла
    inc rdi                                 ; увеличиваем индекс на 1
    mov [reverse_str + rdi], rsi            ; добавляем завершающий байт в конец reverse_str

    inc rdi                                 ; увеличиваем индекс на 1 для возврата длины строки

    pop rbp                                 ; восстанавливаем базовый указатель стека
    ret                                     ; возвращаем управление вызывающей функции

; ----------------------------
; Обработчики ошибок
; ----------------------------
write_failed_handler:                       ; метка обработчика ошибки write()
    mov r13, rax                            ; сохраняем код ошибки

    mov rax, WRITE                          ; системный вызов write
    mov rdi, STDERR                         ; дескриптор потока ошибок
    mov rsi, write_failed_msg               ; адрес сообщения
    mov rdx, write_failed_msg_len           ; длина сообщения
    syscall                                 ; выполняем системный вызов write

    jmp exit                                ; завершение программы

write_byte_number_mismatch_handler:         ; метка обработчика несоответствия байт
    mov r13, rax                            ; сохраняем код ошибки

    mov rax, WRITE                              ; системный вызов write
    mov rdi, STDERR                             ; дескриптор потока ошибок
    mov rsi, write_byte_number_mismatch_msg     ; адрес сообщения
    mov rdx, write_byte_number_mismatch_msg_len ; длина сообщения
    syscall                                     ; выполняем системный вызов write

    jmp exit                                ; завершение программы

read_failed_handler:                        ; метка обработчика ошибки read()
    mov r13, rax                            ; сохраняем код ошибки

    mov rax, WRITE                          ; системный вызов write
    mov rdi, STDERR                         ; дескриптор потока ошибок
    mov rsi, read_failed_msg                ; адрес сообщения
    mov rdx, read_failed_msg_len            ; длина сообщения
    syscall                                 ; выполняем системный вызов write

    jmp exit                                ; завершение программы

exit:                                       ; метка выхода из программы
    mov rdi, r13                            ; код завершения программы
    mov rax, EXIT                           ; системный вызов exit
    syscall                                 ; выполняем системный вызов
