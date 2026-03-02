run: a.out
	./a.out

a.out: hello.o
	ld hello.o -o a.out

hello.o: hello.asm
	nasm -felf64 -gdwarf -Wall hello.asm -o hello.o

clean:
	rm -f hello.o a.out

