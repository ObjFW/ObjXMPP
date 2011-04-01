AC_INIT(ObjXMPP, 0.1, js@webkeks.org)
AC_CONFIG_SRCDIR(src)

AC_CHECK_TOOL(OBJFW_CONFIG, objfw-config)
AS_IF([test x"$OBJFW_CONFIG" = x""], [
       AC_MSG_ERROR(You need ObjFW and objfw-config installed!)
])

test x"$OBJC" = x"" && OBJC="$($OBJFW_CONFIG --objc)"

AC_LANG([Objective C])
AC_PROG_OBJC
AC_PROG_OBJCPP
AC_PROG_LN_S
AC_PROG_INSTALL

CPP="$OBJCPP"
CPPFLAGS="$CPPFLAGS $OBJCPPFLAGS $($OBJFW_CONFIG --cppflags)"
OBJCFLAGS="$OBJCFLAGS -Wall $($OBJFW_CONFIG --objcflags)"
LDFLAGS="$LDFLAGS $($OBJFW_CONFIG --ldflags)"
LIBS="$LIBS $($OBJFW_CONFIG --libs)"

AC_ARG_ENABLE(shared,
	AS_HELP_STRING([--disabel-shared], [do not build shared library]))
AS_IF([test x"$enable_shared" != x"no"], [
	BUILDSYS_SHARED_LIB
	AC_SUBST(OBJXMPP_SHARED_LIB, "${LIB_PREFIX}objxmpp${LIB_SUFFIX}")
])
AC_ARG_ENABLE(static, AS_HELP_STRING([--enable-static], [build static library]))
AS_IF([test x"$enable_static" = x"yes" -o x"$enable_shared" = x"no"], [
	AC_PATH_TOOL(AR, ar)
	AC_PROG_RANLIB
	AC_SUBST(OBJXMPP_STATIC_LIB, "libobjxmpp.a")
])

AC_CHECK_LIB(objopenssl, main, [
	LIBS="$LIBS -lobjopenssl -lcrypto"
], [
	AC_MSG_ERROR(You need ObjOpenSSL installed!)
])

PKG_CHECK_MODULES(libidn, [libidn >= 0.25], [
	CPPFLAGS="$CPPFLAGS $libidn_CFLAGS"
	LIBS="$LIBS $libidn_LIBS"
], [
	AC_MSG_ERROR(You need at least libidn 2.5 installed!)
])

AS_IF([test x"$GOBJC" = x"yes"], [
	OBJCFLAGS="$OBJCFLAGS -Wwrite-strings -Wcast-align -Wpointer-arith"
	OBJCFLAGS="$OBJCFLAGS -Werror"
])

BUILDSYS_INIT
BUILDSYS_TOUCH_DEPS

dnl We don't call AC_PROG_CPP, but only AC_PROG_OBJCPP and set CPP to OBJCPP
dnl and add OBJCPPA.FLAGS to CPPFLAGS, thus we need to AC_SUBST these ourself
AC_SUBST(CPP)
AC_SUBST(CPPFLAGS)

AC_SUBST(PACKAGE, ObjXMPP)
AC_CONFIG_FILES([buildsys.mk extra.mk])
AC_OUTPUT
