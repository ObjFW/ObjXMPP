all:
	objfw-compile -Wall -g --lib 0.0 -o objxmpp *.m \
		`pkg-config --cflags --libs libidn` -lobjgnutls

clean:
	rm -f *.o *.so *.dylib *.dll
