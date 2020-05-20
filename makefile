oFile = calculator.o
sFile = calculator.s
prog = calculator

all: exec

exec: $(cFile)
	nasm -f elf32 $(sFile) -o $(oFile)
	ld -m elf_i386 $(oFile) -o $(prog)
	rm -rf ./*.o

.PHONY: clean
clean:
	rm -rf ./*.o $(prog)