run: a.out
	./a.out

a.out: main.o
	ld main.o -o a.out

main.o: main.asm
	nasm -felf64 -gdwarf -Wall main.asm -o main.o

clean:
	rm -f main.o a.out
