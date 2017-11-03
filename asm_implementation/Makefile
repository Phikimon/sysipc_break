ASM=nasm
NASM_FLAGS=-felf64
LINKER=ld
LINKER_FLAGS=-Bstatic -dn -non_shared -static

all: sysipc_break

sysipc_break: sysipc_break.asm
	$(ASM) $(NASM_FLAGS) $@.asm -o $@.o
	$(LINKER) $(LINKER_FLAGS) $@.o -o $@
