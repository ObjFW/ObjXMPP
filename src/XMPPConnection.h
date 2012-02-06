/*
 * Copyright (c) 2010, 2011, 2012, Jonathan Schleifer <js@webkeks.org>
 * Copyright (c) 2011, 2012, Florian Zeitz <florob@babelmonkeys.de>
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

#import "XMPPCallback.h"
#import "XMPPStorage.h"

@class XMPPConnection;
@class XMPPJID;
@class XMPPIQ;
@class XMPPMessage;
@class XMPPPresence;
@class XMPPAuthenticator;
@class SSLSocket;
@class XMPPMulticastDelegate;

/**
 * \brief A protocol that should be (partially) implemented
 *	  by delegates of a XMPPConnection
 */
@protocol XMPPConnectionDelegate
#ifndef XMPP_CONNECTION_M
    <OFObject>
#endif
#ifdef OF_HAVE_OPTIONAL_PROTOCOLS
@optional
#endif

/**
 * \brief This callback is called when the connection received an element.
 *
 * \param connection The connection that received the element
 * \param element The element that was received
 */
-  (void)connection: (XMPPConnection*)connection
  didReceiveElement: (OFXMLElement*)element;

/**
 * \brief This callback is called when the connection sent an element.
 *
 * \param connection The connection that sent the element
 * \param element The element that was sent
 */
- (void)connection: (XMPPConnection*)connection
    didSendElement: (OFXMLElement*)element;

/**
 * \brief This callback is called when the connection sucessfully authenticated.
 *
 * \param connection The connection that was authenticated
 */
- (void)connectionWasAuthenticated: (XMPPConnection*)connection;

/**
 * \brief This callback is called when the connection was bound to a JID.
 *
 * \param connection The connection that was bound to a JID
 * \param JID The JID the conecction was bound to
 */
- (void)connection: (XMPPConnection*)connection
     wasBoundToJID: (XMPPJID*)JID;

/**
 * \brief This callback is called when the connection received an IQ stanza.
 *
 * \param connection The connection that received the stanza
 * \param iq The IQ stanza that was received
 */
- (BOOL)connection: (XMPPConnection*)connection
      didReceiveIQ: (XMPPIQ*)iq;

/**
 * \brief This callback is called when the connection received a presence
 *	  stanza.
 *
 * \param connection The connection that received the stanza
 * \param presence The presence stanza that was received
 */
-   (void)connection: (XMPPConnection*)connection
  didReceivePresence: (XMPPPresence*)presence;

/**
 * \brief This callback is called when the connection received a message stanza.
 *
 * \param connection The connection that received the stanza
 * \param message The message stanza that was received
 */
-  (void)connection: (XMPPConnection*)connection
  didReceiveMessage: (XMPPMessage*)message;

/**
 * \brief This callback is called when the connection was closed.
 *
 * \param connection The connection that was closed
 */
- (void)connectionWasClosed: (XMPPConnection*)connection;

/**
 * \brief This callback is called when the connection is about to upgrade to
 *	  TLS.
 *
 * \param connection The connection that will upgraded to TLS
 */
- (void)connectionWillUpgradeToTLS: (XMPPConnection*)connection;

/**
 * \brief This callback is called when the connection was upgraded to use TLS.
 *
 * \param connection The connection that was upgraded to TLS
 */
- (void)connectionDidUpgradeToTLS: (XMPPConnection*)connection;
@end

/**
 * \brief A class which abstracts a connection to an XMPP service.
 */
@interface XMPPConnection: OFObject
#ifdef OF_HAVE_OPTONAL_PROTOCOLS
    <OFXMLParserDelegate, OFXMLElementBuilderDelegate>
#endif
{
/// \cond internal
	id sock;
	OFXMLParser *parser, *oldParser;
	OFXMLElementBuilder *elementBuilder, *oldElementBuilder;
	OFString *username, *password, *server, *resource;
	OFString *privateKeyFile, *certificateFile;
	OFString *domain, *domainToASCII;
	XMPPJID *JID;
	uint16_t port;
	id <XMPPStorage> dataStorage;
	OFString *language;
	XMPPMulticastDelegate *delegates;
	OFMutableDictionary *callbacks;
	XMPPAuthenticator *authModule;
	BOOL streamOpen;
	BOOL needsSession;
	BOOL encryptionRequired, encrypted;
	BOOL rosterVersioningSupported;
	unsigned int lastID;
/// \endcond
}

#ifdef OF_HAVE_PROPERTIES
/// \brief The username to use for authentication
@property (copy) OFString *username;
/// \brief The password to use for authentication
@property (copy) OFString *password;
/**
 * \brief The server to use for the connection
 *
 * This is useful if the address of the server is different from the domain.
 */
@property (copy) OFString *server;
/// \brief The domain to connect to
@property (copy) OFString *domain;
/// \brief The resource to request for the connection
@property (copy) OFString *resource;
/// \brief The language to request for the connection
@property (copy) OFString *language;
/// \brief A private key file to use for authentication
@property (copy) OFString *privateKeyFile;
/// \brief A certificate file to use for authentication
@property (copy) OFString *certificateFile;
/// \brief The JID the server assigned to the connection after binding
@property (copy, readonly) XMPPJID *JID;
/// \brief The port to connect to
@property uint16_t port;
/// \brief An object for data storage, conforming to the XMPPStorage protocol
@property (assign) id <XMPPStorage> dataStorage;
/// \brief The socket used for the connection
@property (readonly, retain, getter=socket) OFTCPSocket *sock;
/// \brief Whether encryption is required
@property BOOL encryptionRequired;
/// \brief Whether the connection is encrypted
@property (readonly) BOOL encrypted;
/// \brief Whether roster versioning is supported
@property (readonly) BOOL rosterVersioningSupported;
#endif

/**
 * \brief Creates a new autoreleased XMPPConnection.
 *
 * \return A new autoreleased XMPPConnection
 */
+ connection;

/**
 * \brief Adds the specified delegate.
 *
 * \param delegate The delegate to add
 */
- (void)addDelegate: (id <XMPPConnectionDelegate>)delegate;

/**
 * \brief Removes the specified delegate.
 *
 * \param delegate The delegate to remove
 */
- (void)removeDelegate: (id <XMPPConnectionDelegate>)delegate;

/**
 * \brief Connects to the XMPP service.
 */
- (void)connect;

/**
 * \brief Closes the stream to the XMPP service
 */
- (void)close;

/**
 * \brief Checks the certificate presented by the server and sets the specified
 *	  pointer to the reason why the certificate is not valid
 *
 * \param reason A pointer to an OFString which is set to a reason in case the
 *		 certificate is not valid (otherwise, it does not touch it).
 *		 Passing NULL means the reason is not stored anywhere.
 * \return Whether the certificate is valid
 */
- (BOOL)checkCertificateAndGetReason: (OFString**)reason;

/**
 * \brief Starts a loop handling incomming data.
 */
- (void)handleConnection;

/**
 * \brief Parses the specified buffer.
 *
 * This is useful for handling multiple connections at once.
 *
 * \param buffer The buffer to parse
 * \param length The length of the buffer. If length is 0, it is assumed that
 *		 the connection was closed.
 */
- (void)parseBuffer: (const char*)buffer
	 withLength: (size_t)length;

/**
 * \brief Returns the socket used by the XMPPConnection.
 *
 * \return The socket used by the XMPPConnection
 */
- (OFTCPSocket*)socket;

/**
 * \brief Returns whether encryption is encrypted.
 *
 * \return Whether encryption is encrypted
 */
- (BOOL)encryptionRequired;

/**
 * \brief Sets whether encryption is required.
 *
 * \param required Whether encryption is required
 */
- (void)setEncryptionRequired: (BOOL)required;

/**
 * \brief Returns whether the connection is encrypted.
 *
 * \return Whether the connection is encrypted
 */
- (BOOL)encrypted;

/**
 * \brief Sends an OFXMLElement, usually an XMPPStanza.
 *
 * \param element The element to send
 */
- (void)sendStanza: (OFXMLElement*)element;

/**
 * \brief Sends an XMPPIQ, registering a callback method.
 *
 * \param object The object that contains the callback method
 * \param selector The selector of the callback method,
 *		   must take exactly one parameter of type XMPPIQ*
 */
-	(void)sendIQ: (XMPPIQ*)iq
  withCallbackObject: (id)object
	    selector: (SEL)selector;

#ifdef OF_HAVE_BLOCKS
/**
 * \brief Sends an XMPPIQ, registering a callback block.
 *
 * \param callback The callback block
 */
-      (void)sendIQ: (XMPPIQ*)iq
  withCallbackBlock: (xmpp_callback_block_t)block;
#endif

/**
 * \brief Generates a new, unique stanza ID.
 *
 * \return A new, generated, unique stanza ID.
 */
- (OFString*)generateStanzaID;

- (void)setUsername: (OFString*)username;
- (OFString*)username;
- (void)setPassword: (OFString*)password;
- (OFString*)password;
- (void)setServer: (OFString*)server;
- (OFString*)server;
- (void)setDomain: (OFString*)domain;
- (OFString*)domain;
- (void)setResource: (OFString*)resource;
- (OFString*)resource;
- (XMPPJID*)JID;
- (void)setPort: (uint16_t)port;
- (uint16_t)port;
- (void)setDataStorage: (id <XMPPStorage>)dataStorage;
- (id <XMPPStorage>)dataStorage;
- (void)setLanguage: (OFString*)language;
- (OFString*)language;

/// \cond internal
- (void)XMPP_startStream;
- (void)XMPP_handleStream: (OFXMLElement*)element;
- (void)XMPP_handleTLS: (OFXMLElement*)element;
- (void)XMPP_handleSASL: (OFXMLElement*)element;
- (void)XMPP_handleStanza: (OFXMLElement*)element;
- (void)XMPP_sendAuth: (OFString*)authName;
- (void)XMPP_sendResourceBind;
- (void)XMPP_sendStreamError: (OFString*)condition
			text: (OFString*)text;
- (void)XMPP_handleIQ: (XMPPIQ*)iq;
- (void)XMPP_handleMessage: (XMPPMessage*)message;
- (void)XMPP_handlePresence: (XMPPPresence*)presence;
- (void)XMPP_handleFeatures: (OFXMLElement*)element;
- (void)XMPP_handleResourceBindForConnection: (XMPPConnection*)connection
				      withIQ: (XMPPIQ*)iq;
- (void)XMPP_sendSession;
- (void)XMPP_handleSessionForConnection: (XMPPConnection*)connection
				 withIQ: (XMPPIQ*)iq;
- (OFString*)XMPP_IDNAToASCII: (OFString*)domain;
- (XMPPMulticastDelegate*)XMPP_delegates;
/// \endcond
@end

@interface OFObject (XMPPConnectionDelegate) <XMPPConnectionDelegate>
@end
