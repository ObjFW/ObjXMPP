all:
	objfw-compile -Wall --lib 0.0 -o objxmpp *.m \
		`pkg-config --cflags --libs libidn libbsd`

clean:
	rm -f *.o *.so *.dylib *.dll
