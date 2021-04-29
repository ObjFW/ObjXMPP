include ../extra.mk

SHARED_LIB = ${OBJXMPP_SHARED_LIB}
STATIC_LIB = ${OBJXMPP_STATIC_LIB}
FRAMEWORK = ${OBJXMPP_FRAMEWORK}
LIB_MAJOR = 0
LIB_MINOR = 0

SRCS = XMPPANONYMOUSAuth.m	\
       XMPPAuthenticator.m	\
       XMPPCallback.m		\
       XMPPConnection.m		\
       XMPPContact.m		\
       XMPPContactManager.m	\
       XMPPDiscoEntity.m	\
       XMPPDiscoIdentity.m	\
       XMPPDiscoNode.m		\
       XMPPExceptions.m		\
       XMPPEXTERNALAuth.m	\
       XMPPIQ.m			\
       XMPPJID.m		\
       XMPPFileStorage.m	\
       XMPPMessage.m		\
       XMPPMulticastDelegate.m	\
       XMPPPLAINAuth.m		\
       XMPPPresence.m		\
       XMPPRoster.m		\
       XMPPRosterItem.m		\
       XMPPSCRAMAuth.m		\
       XMPPStanza.m		\
       XMPPStreamManagement.m	\
       XMPPXMLElementBuilder.m	\
       namespaces.m

INCLUDES = ${SRCS:.m=.h}	\
	   ObjXMPP.h		\
	   XMPPStorage.h

include ../buildsys.mk

CPPFLAGS += -I..
LD = ${OBJC}
FRAMEWORK_LIBS := ${OBJOPENSSL_FRAMEWORK_LIBS} ${OBJFW_FRAMEWORK_LIBS} ${LIBS}
LIBS := ${OBJOPENSSL_LIBS} ${OBJFW_LIBS} ${LIBS}
