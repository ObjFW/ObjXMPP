include ../extra.mk

LIB = ${OBJXMPP_SHARED_LIB}
LIB_MAJOR = 0
LIB_MINOR = 0
STATIC_LIB = ${OBJXMPP_STATIC_LIB}

SRCS = XMPPAuthenticator.m	\
       XMPPConnection.m		\
       XMPPExceptions.m		\
       XMPPIQ.m			\
       XMPPJID.m		\
       XMPPMessage.m		\
       XMPPPLAINAuth.m		\
       XMPPPresence.m		\
       XMPPRoster.m		\
       XMPPRosterItem.m		\
       XMPPSCRAMAuth.m		\
       XMPPStanza.m

INCLUDES = ${SRCS:.m=.h}	\
	   namespaces.h		\
	   ObjXMPP.h

include ../buildsys.mk

LD = ${OBJC}
