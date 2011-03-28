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
@optional
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
@interface XMPPConnection: OFObject <OFXMLParserDelegate,
    OFXMLElementBuilderDelegate>
{
	OFTCPSocket *sock;
	OFXMLParser *parser;
	OFXMLElementBuilder *elementBuilder;
	OFString *username, *password, *server, *resource;
	XMPPJID *JID;
	uint16_t port;
	/// Whether to use TLS
	BOOL useTLS;
	id <XMPPConnectionDelegate, OFObject> delegate;
	XMPPAuthenticator *authModule;
	BOOL needsSession;
	unsigned int lastID;
	OFString *bindID, *sessionID, *rosterID;
	XMPPRoster *roster;
}

@property (copy) OFString *username, *password, *server, *resource;
@property (copy, readonly) XMPPJID *JID;
@property (assign) uint16_t port;
@property (assign) BOOL useTLS;
@property (retain) id <XMPPConnectionDelegate> delegate;
@property (readonly, retain) XMPPRoster *roster;

/**
 * Connects to the XMPP service.
 */
- (void)connect;

/**
 * Starts a loop handling incomming data.
 */
- (void)handleConnection;

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
@end
