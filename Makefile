compile:
	nasm -f elf64 heat-simulation.asm
	gcc -Wall -Wextra heat-simulation.c heat-simulation.o -o heat-simulation

clean:
	@rm heat-simulation.o heat-simulation &> /dev/null

