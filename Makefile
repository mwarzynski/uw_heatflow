compile:
	nasm -f elf64 heatflow.asm
	gcc -Wall -no-pie -Wextra simulation.c heatflow.o -o simulation

clean:
	@rm heatflow.o simulation &> /dev/null

