/*
 * Copyright (c) 2010, 2011, 2012, 2013, 2016, 2017, 2018, 2021, 2025
 *   Jonathan Schleifer <js@nil.im>
 * Copyright (c) 2011, 2012, Florian Zeitz <florob@babelmonkeys.de>
 *
 * https://nil.im/objxmpp/
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

OF_ASSUME_NONNULL_BEGIN

#define XMPPConnectionBufferLength 512

@class XMPPConnection;
@class XMPPJID;
@class XMPPIQ;
@class XMPPMessage;
@class XMPPPresence;
@class XMPPAuthenticator;
@class SSLSocket;
@class XMPPMulticastDelegate;

/*!
 * @brief A protocol that should be (partially) implemented by delegates of a
 *	  @ref XMPPConnection
 */
@protocol XMPPConnectionDelegate
@optional
/*!
 * @brief This callback is called when the connection received an element.
 *
 * @param connection The connection that received the element
 * @param element The element that was received
 */
-  (void)connection: (XMPPConnection *)connection
  didReceiveElement: (OFXMLElement *)element;

/*!
 * @brief This callback is called when the connection sent an element.
 *
 * @param connection The connection that sent the element
 * @param element The element that was sent
 */
- (void)connection: (XMPPConnection *)connection
    didSendElement: (OFXMLElement *)element;

/*!
 * @brief This callback is called when the connection sucessfully authenticated.
 *
 * @param connection The connection that was authenticated
 */
- (void)connectionWasAuthenticated: (XMPPConnection *)connection;

/*!
 * @brief This callback is called when the connection was bound to a JID.
 *
 * @param connection The connection that was bound to a JID
 * @param JID The JID the conecction was bound to
 */
- (void)connection: (XMPPConnection *)connection wasBoundToJID: (XMPPJID *)JID;

/*!
 * @brief This callback is called when the connection received an IQ stanza.
 *
 * @param connection The connection that received the stanza
 * @param IQ The IQ stanza that was received
 */
- (bool)connection: (XMPPConnection *)connection didReceiveIQ: (XMPPIQ *)IQ;

/*!
 * @brief This callback is called when the connection received a presence
 *	  stanza.
 *
 * @param connection The connection that received the stanza
 * @param presence The presence stanza that was received
 */
-   (void)connection: (XMPPConnection *)connection
  didReceivePresence: (XMPPPresence *)presence;

/*!
 * @brief This callback is called when the connection received a message stanza.
 *
 * @param connection The connection that received the stanza
 * @param message The message stanza that was received
 */
-  (void)connection: (XMPPConnection *)connection
  didReceiveMessage: (XMPPMessage *)message;

/*!
 * @brief This callback is called when the connection was closed.
 *
 * @param connection The connection that was closed
 * @param error The error XML element the stream encountered or nil
 */
- (void)connectionWasClosed: (XMPPConnection *)connection
		      error: (nullable OFXMLElement *)error;

/*!
 * @brief This callback is called when the connection threw an exception.
 *
 * @param connection The connection which threw an exception
 * @param exception The exception the connection threw
 */
-  (void)connection: (XMPPConnection *)connection
  didThrowException: (id)exception;

/*!
 * @brief This callback is called when the connection is about to upgrade to
 *	  TLS.
 *
 * @param connection The connection that will upgraded to TLS
 */
- (void)connectionWillUpgradeToTLS: (XMPPConnection *)connection;

/*!
 * @brief This callback is called when the connection was upgraded to use TLS.
 *
 * @param connection The connection that was upgraded to TLS
 */
- (void)connectionDidUpgradeToTLS: (XMPPConnection *)connection;
@end

/*!
 * @brief A class which abstracts a connection to an XMPP service.
 */
@interface XMPPConnection: OFObject
{
	OF_KINDOF(OFStream *) _stream;
	char _buffer[XMPPConnectionBufferLength];
	OFXMLParser *_parser, *_oldParser;
	OFXMLElementBuilder *_elementBuilder, *_oldElementBuilder;
	OFString *_Nullable _username, *_Nullable _password, *_Nullable _server;
	OFString *_Nullable _resource;
	bool _usesAnonymousAuthentication;
	OFArray OF_GENERIC(OFX509Certificate *) *_Nullable _certificateChain;
	OFString *_Nullable _domain, *_Nullable _domainToASCII;
	XMPPJID *_Nullable _JID;
	uint16_t _port;
	id <XMPPStorage> _Nullable _dataStorage;
	OFString *_Nullable _language;
	OFMutableArray *_nextSRVRecords;
	XMPPMulticastDelegate *_delegates;
	OFMutableDictionary OF_GENERIC(OFString *, XMPPCallback *) *_callbacks;
	XMPPAuthenticator *_authModule;
	bool _streamOpen, _needsSession, _encryptionRequired, _encrypted;
	bool _supportsRosterVersioning, _supportsStreamManagement;
	unsigned int _lastID;
}

/*!
 * @brief The username to use for authentication.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy) OFString *username;

/*!
 * @brief The password to use for authentication.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy) OFString *password;

/*!
 * @brief The server to use for the connection.
 *
 * This is useful if the address of the server is different from the domain.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy) OFString *server;

/*!
 * @brief The domain to connect to.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy) OFString *domain;

/*!
 * @brief The resource to request for the connection.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy) OFString *resource;

/*!
 * @brief Whether the connection uses SASL ANONYMOUS authentication.
 */
@property (nonatomic) bool usesAnonymousAuthentication;

/*!
 * @brief The language to request for the connection.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy) OFString *language;

/*!
 * @brief The certificate chain to use.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, copy)
    OFArray OF_GENERIC(OFX509Certificate *) *certificateChain;

/*!
 * @brief The JID the server assigned to the connection after binding.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) XMPPJID *JID;

/*!
 * @brief The port to connect to.
 */
@property (nonatomic) uint16_t port;

/*!
 * @brief An object for data storage, conforming to the XMPPStorage protocol.
 */
@property OF_NULLABLE_PROPERTY (nonatomic, assign) id <XMPPStorage> dataStorage;

/*!
 * @brief The stream used for the connection.
 */
@property (readonly, nonatomic) OF_KINDOF(OFStream *) stream;

/*!
 * @brief Whether encryption is required.
 */
@property (nonatomic) bool encryptionRequired;

/*!
 * @brief Whether the connection is encrypted.
 */
@property (readonly, nonatomic) bool encrypted;

/*!
 * @brief Whether roster versioning is supported.
 */
@property (readonly, nonatomic) bool supportsRosterVersioning;

/*!
 * @brief Whether stream management is supported.
 */
@property (readonly, nonatomic) bool supportsStreamManagement;

/*!
 * @brief Creates a new autoreleased XMPPConnection.
 *
 * @return A new autoreleased XMPPConnection
 */
+ (instancetype)connection;

/*!
 * @brief Adds the specified delegate.
 *
 * @param delegate The delegate to add
 */
- (void)addDelegate: (id <XMPPConnectionDelegate>)delegate;

/*!
 * @brief Removes the specified delegate.
 *
 * @param delegate The delegate to remove
 */
- (void)removeDelegate: (id <XMPPConnectionDelegate>)delegate;

/*!
 * @brief Closes the stream to the XMPP service
 */
- (void)close;

/*!
 * @brief Asynchronously connects to the server.
 */
- (void)asyncConnect;

/*!
 * @brief Parses the specified buffer.
 *
 * This is useful for handling multiple connections at once.
 *
 * @param buffer The buffer to parse
 * @param length The length of the buffer. If length is 0, it is assumed that
 *		 the connection was closed.
 */
- (void)parseBuffer: (const void *)buffer length: (size_t)length;

/*!
 * @brief Sends an OFXMLElement, usually an XMPPStanza.
 *
 * @param element The element to send
 */
- (void)sendStanza: (OFXMLElement *)element;

/*!
 * @brief Sends an XMPPIQ, registering a callback method.
 *
 * @param IQ The IQ to send
 * @param target The object that contains the callback method
 * @param selector The selector of the callback method,
 *		   must take exactly one parameter of type `XMPPIQ *`
 */
-   (void)sendIQ: (XMPPIQ *)IQ
  callbackTarget: (id)target
	selector: (SEL)selector;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Sends an XMPPIQ, registering a callback block.
 *
 * @param IQ The IQ to send
 * @param block The callback block
 */
-  (void)sendIQ: (XMPPIQ *)IQ callbackBlock: (XMPPCallbackBlock)block;
#endif

/*!
 * @brief Generates a new, unique stanza ID.
 *
 * @return A new, generated, unique stanza ID.
 */
- (OFString *)generateStanzaID;
@end

OF_ASSUME_NONNULL_END
