PROG_NOINST = tests${PROG_SUFFIX}
SRCS = test.m

include ../buildsys.mk

CPPFLAGS += -I../src
LIBS := -L../src -lobjxmpp ${LIBS}
LD = ${OBJC}
