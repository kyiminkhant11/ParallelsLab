CC = gcc
CFLAGS = -Wall -std=c17

all: make_mask apply_mask

make_mask: make_mask.c
	$(CC) $(CFLAGS) -o make_mask make_mask.c

apply_mask: apply_mask.c
	$(CC) $(CFLAGS) -o apply_mask apply_mask.c

clean:
	rm -f make_mask apply_mask