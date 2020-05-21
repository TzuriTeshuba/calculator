prog = calculator

all: $(prog)

$(prog): myCalc.o
	gcc -m32 -Wall -g myCalc.o -o $(prog)
	rm -f myCalc.o

myCalc.o: calculator.s
	nasm -f elf calculator.s -o myCalc.o

.PHONY: clean

clean:
	rm -f *.o  $(prog)