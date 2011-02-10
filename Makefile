all: tests

tests: test.m XMPPConnection.m XMPPStanza.m
	objfw-compile -o $@ $^ -lidn -Wall -Werror
