# Makefile
include variables.sh

# Compiler and linker settings
CC = clang
CFLAGS = -fobjc-arc -Wall
LDFLAGS = -dynamiclib -framework Foundation

# Use conditional statements to include/exclude patch for vm 54729
ifeq ($(VM_54729), 1)
    CFLAGS += -DVM_54729
endif

# Source files
SRC = Utils.m ../rd_route/rd_route.c HookParallels.m
HEADER = Utils.h ../rd_route/rd_route.h HookParallels.h

# Output dylib
OUT = libHookParallels.dylib

all: $(OUT)

$(OUT): $(SRC) $(HEADER)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(OUT) $(SRC)

clean:
	rm -f $(OUT)
