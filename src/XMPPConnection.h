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

@protocol XMPPConnectionDelegate
@optional
- (void)connectionWasClosed: (XMPPConnection*)conn;
- (void)connection: (XMPPConnection*)conn
      didReceiveIQ: (XMPPIQ*)iq;
-   (void)connection: (XMPPConnection*)conn
  didReceivePresence: (XMPPPresence*)pres;
-  (void)connection: (XMPPConnection*)conn
  didReceiveMessage: (XMPPMessage*)msg;
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
	/// The username to connect with
	OFString *username;
	/// The password to connect with
	OFString *password;
	/// The server to connect to
	OFString *server;
	/// The resource to connect with
	OFString *resource;
	/// The JID bound to this connection (this is determined by the server)
	XMPPJID *JID;
	/// The port to connect to
	short port;
	/// Whether to use TLS
	BOOL useTLS;
	id <XMPPConnectionDelegate> delegate;
	XMPPAuthenticator *authModule;
}

@property (copy) OFString *username;
@property (copy) OFString *password;
@property (copy) OFString *server;
@property (copy) OFString *resource;
@property (copy, readonly) XMPPJID *JID;
@property (assign) short port;
@property (assign) BOOL useTLS;
@property (retain) id <XMPPConnectionDelegate> delegate;

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
@end
