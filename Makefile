all:
	cd src && ${MAKE} ${MFLAGS}
	cd tests && ${MAKE} ${MFLAGS}

clean:
	cd src && ${MAKE} ${MFLAGS} clean
	cd tests && ${MAKE} ${MFLAGS} clean
