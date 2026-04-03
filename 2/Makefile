NASM_FLAGS = -felf64 -gdwarf -Wall
ORDER ?= asc

ifeq ($(ORDER), desc)
    $(info Order: descending)
    NASM_FLAGS += -dDESCENDING
else
    $(info Order: ascending)
endif

all: a.out

run: a.out
	./a.out

a.out: main.o
	ld main.o -o a.out

main.o: main.asm .order_$(ORDER)
	nasm $(NASM_FLAGS) main.asm -o main.o

.order_$(ORDER):
	rm -f .order_*
	touch .order_$(ORDER)
clean:
	rm -f *.o a.out
