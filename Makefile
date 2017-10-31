CC=gcc
SOURCES=main.c
HEADERS=

all: compile

compile:
	$(CC) $(FLAGS) $(SOURCES) -o ./kernel_bug

clean:
	rm ./log* > /dev/null 2> /dev/null || true

kill:
	pkill kernel_bug > /dev/null 2> /dev/null || true
