; Constants for 'struct shmid_ds'
SHM_ATIME_OFFSET  equ 56
SHM_LPID_OFFSET   equ 84
SHM_NATTCH_OFFSET equ 88
SIZEOF_SHMID_DS   equ 112
; Constants for 'struct timespec'
SIZEOF_TIMESPEC_S equ 18
TV_SEC_OFFSET     equ 0
TV_NSEC_OFFSET    equ 8

%macro exit 1 ; < exit return value
    mov    rdi, %1    ; return value <- %1
    mov    rax, 3Ch   ; syscall <- exit
    syscall
%endmacro

;Entry = string address, string length
;Destr = RDI, RDX, RSI, RAX
%macro write_to_stdout 2
    mov     rdi, 1  ; file descriptor  <- stdout
    mov     rdx, %2 ; buffer size      <- %2
    mov     rsi, %1 ; buffer to print  <- %1
    mov     rax, 1  ; syscall          <- write
    syscall
    test rax, rax ; if no byte is written,
    je __exit
%endmacro

;Entry = address of allocated memory
%macro getchar 1
    mov     rdi, 0  ; file descriptor <- stdin
    mov     rsi, %1 ; buffer          <- %1
    mov     rdx, 1  ; buffer size     <- 1
    mov     rax, 0  ; syscall         <- sys_read
    syscall
    test rax, rax ; if no byte is read,
    je __exit
%endmacro

%macro define_string 2 ; < name, string
    %1: db %2
%1 %+ LEN equ $-%1
%endmacro

section .data
    define_string MSG1, "Bug found! shm_atime = "
    define_string MSG2, "; lpid = "
    define_string MSG3, "; nattch = "
    define_string MSG4, 10 ; < '\n'

section .bss
    STRUCT_DS resb SIZEOF_SHMID_DS
    STRUCT_TIMESPEC resb SIZEOF_TIMESPEC_S
    SHMID resb 8
    BUG_TO_FIND resb 1
    CHILD_SLEEP resb 1
    FOR_SLASH_N resb 1

section .text
;=========================================================================
;                               MAIN                                     ;
;=========================================================================
    global _start

_start:
    getchar BUG_TO_FIND ;< Can be equal to 'l' or 'n'
    getchar FOR_SLASH_N
    getchar CHILD_SLEEP
    getchar FOR_SLASH_N
bug_not_found:
    mov rax, 57 ; syscall <- fork
    syscall
    cmp rax, 0
    jle child
;====================================================
;                     PARENT                        ;
;====================================================
parent:
    mov rdi, rax ; key = child_pid
    mov rsi, 1   ; memsize = 1
    mov rdx, 950 ; flag = IPC_CREAT|0666
    mov rax, 29  ; syscall = shmget
    syscall
    mov [SHMID], rax
loop: ; do { ... } while (ds.shm_nattch == 0)
    mov rdi, [SHMID] ; shmid
    mov rsi, 2   ; cmd = IPC_STAT
    mov rdx, STRUCT_DS ; buf = STRUCT_DS
    mov rax, 31  ; syscall = shmctl
    syscall
cond:
    mov rax, [STRUCT_DS + SHM_NATTCH_OFFSET]
    test rax, rax
    je loop
    ; if ( ((ds.shm_atime > 0 || ds.shm_lpid == 0) && ([BUG_TO_FIND] == 'l')) ||
    ;      (        (ds.shm_nattch > 1)            && ([BUG_TO_FIND] == 'n'))  )

    ; ( (ds.shm_atime == 0 || ds.shm_lpid == 0) && ... )
    mov rax, [STRUCT_DS + SHM_ATIME_OFFSET]
    test rax, rax
    je char_equals_l
    mov eax, [STRUCT_DS + SHM_LPID_OFFSET]
    test eax, eax
    jne char_equals_n
char_equals_l: ; ( ... && [BUG_TO_FIND] == 'l') || (...)
    cmp byte [BUG_TO_FIND], 'l'
    je print_message
char_equals_n: ; (...) || ( (ds.shm_nattch > 1) && (c == 'n') )
    mov rax, [STRUCT_DS + SHM_NATTCH_OFFSET]
    cmp rax, 1
    jbe bug_not_found
    cmp byte [BUG_TO_FIND], 'n'
    jne bug_not_found

print_message:
    write_to_stdout MSG1, MSG1LEN
    mov rax, [STRUCT_DS + SHM_ATIME_OFFSET]
    call PrintDec
    ;
    write_to_stdout MSG2, MSG2LEN
    mov eax, [STRUCT_DS + SHM_LPID_OFFSET]
    call PrintDec
    ;
    write_to_stdout MSG3, MSG3LEN
    mov rax, [STRUCT_DS + SHM_NATTCH_OFFSET]
    call PrintDec
    ;
    write_to_stdout MSG4, MSG4LEN
    ;
    exit 0
;====================================================
;                     CHILD                         ;
;====================================================
child:
try_shmget:
    mov rax, 39 ; syscall = getpid
    syscall
    mov rdi, rax ; key = getpid
    mov rsi, 1   ; memsize = 1
    mov rdx, 0   ; flag = 0
    mov rax, 29  ; syscall = shmget
    syscall
    cmp rax, 0
    jl try_shmget
    mov [SHMID], rax
    ; Attach
    mov rdi, rax ; shmid
    mov rsi, 0   ; shmaddr = NULL
    mov rdx, 0   ; flag = 0
    mov rax, 30  ; syscall = shmat
    syscall
    ; rm shmem
    mov rdi, [SHMID] ; shmid
    mov rsi, 0 ; cmd = IPC_RMID
    mov rdx, 0 ; buf = 0
    mov rax, 31 ; syscall = shmctl
    syscall
    ; sleep if required
    cmp byte [CHILD_SLEEP], '0'
    je __exit
    mov qword [STRUCT_TIMESPEC + TV_SEC_OFFSET], 1
    mov qword [STRUCT_TIMESPEC + TV_NSEC_OFFSET], 0
    mov rdi, STRUCT_TIMESPEC ; rqtp
    mov rsi, 0  ; rmtp = NULL
    mov rax, 35 ; syscall = nanosleep
    syscall
__exit:
    exit 0

;=========================================================================;
;=========================================================================;
;                 ┌───────────────────────────────────────────┐           ;
;                 │ PrintDec:print unsigned number in decimal │           ;
;                 ├───────────────────────────────────────────┤           ;
;                 │ Entry - RAX - value to print              │           ;
;                 │ Destr - RDI, RDX, R15, RBX, RCX           │           ;
;                 └───────────────────────────────────────────┘           ;
;=========================================================================;
%define digit_cnt rbx
%define remainder rdx
%define val rax
%define str r15
%define numeric_base rcx
%define STRLEN 64
PrintDec:
            ; Prologue
            push rbp
            mov rbp, rsp
            sub rsp, STRLEN  ; Allocate memory for string
            ; Initializations
            mov numeric_base, 10 ; numeric base
            mov str, rsp
            xor digit_cnt, digit_cnt
            ; Loop
Pbody:
            xor remainder, remainder
            div numeric_base ; remainder = val % 10; val /= 10
            lea rdi, ['0' + remainder]
            mov byte [str + STRLEN + digit_cnt], dil
            dec digit_cnt
Pcondition:
            test val, val
            jne Pbody
            ; Print stuff
            lea r15, [str + STRLEN + digit_cnt + 1]
            neg digit_cnt
            write_to_stdout r15, digit_cnt
            ; Epilogue
            add rsp, STRLEN
            pop rbp
            ret

%undef digit_cnt
%undef remainder
%undef val
%undef str
%undef chr
%undef STRLEN
;=========================================================================
