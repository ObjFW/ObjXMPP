all: tests/tests

tests/tests: tests/test.m src/XMPPConnection.m src/XMPPStanza.m
	objfw-compile -o $@ $^ -lidn -Wall -Werror -Isrc

clean:
	rm -f src/*.o tests/*.o tests/tests
