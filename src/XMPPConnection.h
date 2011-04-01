/*
 * Copyright (c) 2010, 2011, Jonathan Schleifer <js@webkeks.org>
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
 *
 * https://webkeks.org/hg/objxmpp/
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice is present in all copies.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import <ObjFW/ObjFW.h>

@class XMPPConnection;
@class XMPPJID;
@class XMPPIQ;
@class XMPPMessage;
@class XMPPPresence;
@class XMPPAuthenticator;
@class XMPPRoster;

#define XMPP_NS_BIND @"urn:ietf:params:xml:ns:xmpp-bind"
#define XMPP_NS_CLIENT @"jabber:client"
#define XMPP_NS_ROSTER @"jabber:iq:roster"
#define XMPP_NS_SASL @"urn:ietf:params:xml:ns:xmpp-sasl"
#define XMPP_NS_STARTTLS @"urn:ietf:params:xml:ns:xmpp-tls"
#define XMPP_NS_STANZAS @"urn:ietf:params:xml:ns:xmpp-stanzas"
#define XMPP_NS_SESSION @"urn:ietf:params:xml:ns:xmpp-session"
#define XMPP_NS_STREAM @"http://etherx.jabber.org/streams"

@protocol XMPPConnectionDelegate
#ifndef XMPP_CONNECTION_M
    <OFObject>
#endif
#ifdef OF_HAVE_OPTIONAL_PROTOCOLS
@optional
#endif
- (void)connectionWasAuthenticated: (XMPPConnection*)conn;
- (void)connection: (XMPPConnection*)conn
     wasBoundToJID: (XMPPJID*)jid;
- (void)connectionDidReceiveRoster: (XMPPConnection*)conn;
- (BOOL)connection: (XMPPConnection*)conn
      didReceiveIQ: (XMPPIQ*)iq;
-   (void)connection: (XMPPConnection*)conn
  didReceivePresence: (XMPPPresence*)pres;
-  (void)connection: (XMPPConnection*)conn
  didReceiveMessage: (XMPPMessage*)msg;
- (void)connectionWasClosed: (XMPPConnection*)conn;
@end

/**
 * \brief A class which abstracts a connection to an XMPP service.
 */
@interface XMPPConnection: OFObject
#ifdef OF_HAVE_OPTONAL_PROTOCOLS
    <OFXMLParserDelegate, OFXMLElementBuilderDelegate>
#endif
{
	OFTCPSocket *sock;
	OFXMLParser *parser;
	OFXMLElementBuilder *elementBuilder;
	OFString *username, *password, *server, *resource;
	XMPPJID *JID;
	uint16_t port;
	id <XMPPConnectionDelegate, OFObject> delegate;
	XMPPAuthenticator *authModule;
	BOOL needsSession;
	unsigned int lastID;
	OFString *bindID, *sessionID, *rosterID;
	XMPPRoster *roster;
}

#ifdef OF_HAVE_PROPERTIES
@property (copy) OFString *username, *password, *server, *resource;
@property (copy, readonly) XMPPJID *JID;
@property (assign) uint16_t port;
@property (retain) id <XMPPConnectionDelegate> delegate;
@property (readonly, retain) XMPPRoster *roster;
@property (readonly, retain, getter=socket) OFTCPSocket *sock;
#endif

/**
 * \return A new autoreleased XMPPConnection
 */
+ connection;

/**
 * Connects to the XMPP service.
 */
- (void)connect;

/**
 * Starts a loop handling incomming data.
 */
- (void)handleConnection;

/**
 * Parses the specified buffer.
 *
 * This is useful for handling multiple connections at once.
 *
 * \param buf The buffer to parse
 * \param size The size of the buffer. If size is 0, it is assumed that the
 *	       connection was closed.
 */
- (void)parseBuffer: (const char*)buf
	   withSize: (size_t)size;

/**
 * \return The socket used by the XMPPConnection
 */
- (OFTCPSocket*)socket;

/**
 * Sends an OFXMLElement, usually an XMPPStanza.
 *
 * \param elem The element to send
 */
- (void)sendStanza: (OFXMLElement*)elem;

/**
 * Generates a new, unique stanza ID.
 *
 * \return A new, generated, unique stanza ID.
 */
- (OFString*)generateStanzaID;

/**
 * Requests the roster.
 */
- (void)requestRoster;

- (void)setUsername: (OFString*)username;
- (OFString*)username;
- (void)setPassword: (OFString*)password;
- (OFString*)password;
- (void)setServer: (OFString*)server;
- (OFString*)server;
- (void)setResource: (OFString*)resource;
- (OFString*)resource;
- (XMPPJID*)JID;
- (void)setPort: (uint16_t)port;
- (uint16_t)port;
- (void)setDelegate: (id <XMPPConnectionDelegate>)delegate;
- (id <XMPPConnectionDelegate>)delegate;
- (XMPPRoster*)roster;

- (void)XMPP_startStream;
- (void)XMPP_handleStanza: (OFXMLElement*)elem;
- (void)XMPP_sendAuth: (OFString*)name;
- (void)XMPP_handleIQ: (XMPPIQ*)iq;
- (void)XMPP_handleMessage: (XMPPMessage*)msg;
- (void)XMPP_handlePresence: (XMPPPresence*)pres;
- (void)XMPP_handleFeatures: (OFXMLElement*)elem;
- (void)XMPP_sendResourceBind;
- (void)XMPP_handleResourceBind: (XMPPIQ*)iq;
- (void)XMPP_sendSession;
- (void)XMPP_handleSession: (XMPPIQ*)iq;
- (void)XMPP_handleRoster: (XMPPIQ*)iq;
@end

@interface OFObject (XMPPConnectionDelegate) <XMPPConnectionDelegate>
@end
