run: a.out
	./a.out

a.out: main.o
	gcc -no-pie main.o -o a.out -lm

main.o: main.asm
	nasm -felf64 -gdwarf -Wall main.asm -o main.o

clean:
	rm -f main.o a.out
