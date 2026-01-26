CC := cc
CFLAGS := -O2 -Wall -Wextra -std=c11 -I../src
LDLIBS := -lm

.PHONY: sim clean

sim:
	$(CC) $(CFLAGS) ../src/attitude.c ../src/control.c sim.c -o sim $(LDLIBS)

clean:
	rm -f sim
