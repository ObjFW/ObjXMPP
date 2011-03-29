all:
	objfw-compile -Wall -Werror -g --lib 0.0 -o objxmpp *.m \
		`pkg-config --cflags --libs libidn` -lobjopenssl

clean:
	rm -f *.o *.so *.dylib *.dll
