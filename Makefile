# Build and run QUESTLOG with GnuCOBOL (cobc)
COBC     ?= cobc
COBFLAGS ?= -x -std=default -Wall -I copybooks
BIN      := bin/questlog

.PHONY: all run test clean

all: $(BIN)

$(BIN): src/QUESTLOG.cbl copybooks/*.cpy
	@mkdir -p bin
	$(COBC) $(COBFLAGS) -o $@ src/QUESTLOG.cbl

run: $(BIN)
	@mkdir -p out
	./$(BIN)
	@cat out/chronicle.txt

test: run
	diff -u tests/expected-chronicle.txt out/chronicle.txt
	@echo "PASS: chronicle matches expected output"

clean:
	rm -rf bin out
