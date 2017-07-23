AC_INIT(ObjXMPP, 0.1, js@webkeks.org)
BUILDSYS_INIT

AC_CONFIG_SRCDIR(src)
AC_CONFIG_AUX_DIR(build-aux)
AC_CONFIG_MACRO_DIR(build-aux/m4)

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

AX_CHECK_COMPILER_FLAGS(-Watomic-properties,
	[OBJCFLAGS="$OBJCFLAGS -Watomic-properties"])
AX_CHECK_COMPILER_FLAGS(-Wdocumentation,
	[OBJCFLAGS="$OBJCFLAGS -Wdocumentation"])

AC_ARG_ENABLE(shared,
	AS_HELP_STRING([--disable-shared], [do not build shared library]))
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

# This is an adapted version of what glib does for res_query
# It should recognize the correct library on (at least) Linux,
# NetBSD, FreeBSD, Mac OS X and Haiku
AC_MSG_CHECKING([for res_nsearch])
AC_TRY_LINK([#include <sys/types.h>
	     #include <netinet/in.h>
	     #include <arpa/nameser.h>
	     #include <resolv.h>],
	     [res_nsearch(&_res, "test", 0, 0, (void *)0, 0);],
	     [AC_MSG_RESULT([yes])],
	     [save_libs="$LIBS"
	      LIBS="$LIBS -lresolv"
	      AC_TRY_LINK([#include <sys/types.h>
			   #include <netinet/in.h>
			   #include <arpa/nameser.h>
			   #include <resolv.h>],
			   [res_nsearch(&_res, "test", 0, 0, (void *)0, 0);],
			   [AC_MSG_RESULT([in -lresolv])],
			   [LIBS="$save_libs -lnetwork"
			    AC_TRY_LINK([#include <sys/types.h>
					 #include <netinet/in.h>
					 #include <arpa/nameser.h>
					 #include <resolv.h>],
					[res_nsearch(&_res, "test", 0, 0, (void *)0, 0);],
					[AC_MSG_RESULT([in -lnetwork])],
					[LIBS="$save_libs -lbind"
					 AC_TRY_LINK([#include <resolv.h>],
						     [res_nsearch(&_res, "test", 0, 0, (void *)0, 0);],
						     [AC_MSG_RESULT([in -lbind])],
						     [AC_MSG_ERROR(not found)])])])])

AC_MSG_CHECKING([for res_ndestroy])
AC_TRY_LINK([
	#include <resolv.h>
], [
	res_ndestroy(&_res)
], [
	AC_MSG_RESULT(yes)
	AC_DEFINE(HAVE_RES_NDESTROY, 1, [Whether we have res_ndestroy])
], [
	AC_MSG_RESULT(no)
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
	AC_MSG_ERROR(You need libidn >= 2.5 installed!)
])

AS_IF([test x"$GOBJC" = x"yes"], [
	OBJCFLAGS="$OBJCFLAGS -Wwrite-strings -Wpointer-arith"
	dnl We need -Wno-deprecated-declarations as OpenSSL is deprecated on
	dnl OS X.
	OBJCFLAGS="$OBJCFLAGS -Wno-deprecated-declarations -Werror"

	old_OBJCFLAGS="$OBJCFLAGS"
	OBJCFLAGS="$OBJCFLAGS -Wcast-align"
	AC_MSG_CHECKING(whether -Wcast-align is buggy)
	AC_TRY_COMPILE([
		#import <ObjFW/OFObject.h>

		@interface Foo: OFObject
		@end

		@implementation Foo
		- (void)foo
		{
		}
		@end
	], [
	], [
		AC_MSG_RESULT(no)
	], [
		AC_MSG_RESULT(yes)
		OBJCFLAGS="$old_OBJCFLAGS"
	])
])

dnl We don't call AC_PROG_CPP, but only AC_PROG_OBJCPP and set CPP to OBJCPP
dnl and add OBJCPPFLAGS to CPPFLAGS, thus we need to AC_SUBST these ourself.
AC_SUBST(CPP)
AC_SUBST(CPPFLAGS)

AC_SUBST(PACKAGE, ObjXMPP)
AC_CONFIG_FILES([buildsys.mk extra.mk])
AC_CONFIG_HEADERS(config.h)
AC_OUTPUT
