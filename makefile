	
sekelton: skeleton.o
	ld -m elf_i386 -o skeleton skeleton.o
	
skeleton.o: skeleton.s
	nasm -g -f elf32 -o skeleton.o skeleton.s
.PHONY: clean

clean:
	rm -f *.o sekelton