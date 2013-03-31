/*
 * Copyright (c) 2010, 2011, 2012, Jonathan Schleifer <js@webkeks.org>
 * Copyright (c) 2011, 2012, Florian Zeitz <florob@babelmonkeys.de>
 *
 * https://webkeks.org/git/?p=objxmpp.git
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

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#define XMPP_CONNECTION_M

#include <assert.h>

#include <stringprep.h>
#include <idna.h>

#import <ObjOpenSSL/SSLSocket.h>
#import <ObjOpenSSL/SSLInvalidCertificateException.h>
#import <ObjOpenSSL/X509Certificate.h>

#import <ObjFW/OFInvalidArgumentException.h>

#import "XMPPConnection.h"
#import "XMPPCallback.h"
#import "XMPPSRVLookup.h"
#import "XMPPEXTERNALAuth.h"
#import "XMPPSCRAMAuth.h"
#import "XMPPPLAINAuth.h"
#import "XMPPStanza.h"
#import "XMPPJID.h"
#import "XMPPIQ.h"
#import "XMPPMessage.h"
#import "XMPPPresence.h"
#import "XMPPMulticastDelegate.h"
#import "XMPPExceptions.h"
#import "XMPPXMLElementBuilder.h"
#import "namespaces.h"

#import <ObjFW/macros.h>

#define BUFFER_LENGTH 512

@interface XMPPConnection_ConnectThread: OFThread
{
	OFThread *sourceThread;
	XMPPConnection *connection;
}

- initWithSourceThread: (OFThread*)sourceThread
	    connection: (XMPPConnection*)connection;
@end

@implementation XMPPConnection_ConnectThread
- initWithSourceThread: (OFThread*)sourceThread_
	    connection: (XMPPConnection*)connection_
{
	self = [super init];

	@try {
		sourceThread = [sourceThread_ retain];
		connection = [connection_ retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[sourceThread release];
	[connection release];

	[super dealloc];
}

- (void)didConnect
{
	[self join];

	[connection handleConnection];
}

- (id)main
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

	[connection connect];

	[self performSelector: @selector(didConnect)
		     onThread: sourceThread
		waitUntilDone: NO];

	[pool release];

	return nil;
}
@end

@implementation XMPPConnection
+ connection
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	@try {
		_port = 5222;
		_encrypted = NO;
		_streamOpen = NO;
		_delegates = [[XMPPMulticastDelegate alloc] init];
		_callbacks = [[OFMutableDictionary alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_socket release];
	[_parser release];
	[_elementBuilder release];
	[_username release];
	[_password release];
	[_privateKeyFile release];
	[_certificateFile release];
	[_server release];
	[_domain release];
	[_resource release];
	[_JID release];
	[_delegates release];
	[_callbacks release];
	[_authModule release];

	[super dealloc];
}

- (void)setUsername: (OFString*)username
{
	OFString *old = _username;

	if (username != nil) {
		char *node;
		Stringprep_rc rc;

		if ((rc = stringprep_profile([username UTF8String], &node,
		    "SASLprep", 0)) != STRINGPREP_OK)
			@throw [XMPPStringPrepFailedException
			    exceptionWithClass: [self class]
				    connection: self
				       profile: @"SASLprep"
					string: username];

		@try {
			_username = [[OFString alloc] initWithUTF8String: node];
		} @finally {
			free(node);
		}
	} else
		_username = nil;

	[old release];
}

- (OFString*)username
{
	return [[_username copy] autorelease];
}

- (void)setResource: (OFString*)resource
{
	OFString *old = _resource;

	if (resource != nil) {
		char *res;
		Stringprep_rc rc;

		if ((rc = stringprep_profile([resource UTF8String], &res,
		    "Resourceprep", 0)) != STRINGPREP_OK)
			@throw [XMPPStringPrepFailedException
			    exceptionWithClass: [self class]
				    connection: self
				       profile: @"Resourceprep"
					string: resource];

		@try {
			_resource = [[OFString alloc] initWithUTF8String: res];
		} @finally {
			free(res);
		}
	} else
		_resource = nil;

	[old release];
}

- (OFString*)resource
{
	return [[_resource copy] autorelease];
}

- (void)setServer: (OFString*)server
{
	OFString *old = _server;

	if (server != nil)
		_server = [self XMPP_IDNAToASCII: server];
	else
		_server = nil;

	[old release];
}

- (OFString*)server
{
	return [[_server copy] autorelease];
}

- (void)setDomain: (OFString*)domain_
{
	OFString *oldDomain = _domain;
	OFString *oldDomainToASCII = _domainToASCII;

	if (domain_ != nil) {
		char *srv;
		Stringprep_rc rc;

		if ((rc = stringprep_profile([domain_ UTF8String], &srv,
		    "Nameprep", 0)) != STRINGPREP_OK)
			@throw [XMPPStringPrepFailedException
			    exceptionWithClass: [self class]
				    connection: self
				       profile: @"Nameprep"
					string: domain_];

		@try {
			_domain = [[OFString alloc] initWithUTF8String: srv];
		} @finally {
			free(srv);
		}

		_domainToASCII = [self XMPP_IDNAToASCII: _domain];
	} else {
		_domain = nil;
		_domainToASCII = nil;
	}

	[oldDomain release];
	[oldDomainToASCII release];
}

- (OFString*)domain
{
	return [[_domain copy] autorelease];
}

- (void)setPassword: (OFString*)password
{
	OFString *old = _password;

	if (password != nil) {
		char *pass;
		Stringprep_rc rc;

		if ((rc = stringprep_profile([password UTF8String], &pass,
		    "SASLprep", 0)) != STRINGPREP_OK)
			@throw [XMPPStringPrepFailedException
			    exceptionWithClass: [self class]
				    connection: self
				       profile: @"SASLprep"
					string: password];

		@try {
			_password = [[OFString alloc] initWithUTF8String: pass];
		} @finally {
			free(pass);
		}
	} else
		_password = nil;

	[old release];
}

- (OFString*)password
{
	return [[_password copy] autorelease];
}

- (void)setPrivateKeyFile: (OFString*)privateKeyFile
{
	OF_SETTER(_privateKeyFile, privateKeyFile, YES, YES)
}

- (OFString*)privateKeyFile
{
	OF_GETTER(_privateKeyFile, YES)
}

- (void)setCertificateFile: (OFString*)certificateFile
{
	OF_SETTER(_certificateFile, certificateFile, YES, YES)
}

- (OFString*)certificateFile
{
	OF_GETTER(_certificateFile, YES)
}

- (void)connect
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	XMPPSRVEntry *candidate = nil;
	XMPPSRVLookup *SRVLookup = nil;
	OFEnumerator *enumerator;

	if (_socket != nil)
		@throw [OFAlreadyConnectedException
		    exceptionWithClass: [self class]];

	_socket = [[OFTCPSocket alloc] init];

	if (_server)
		[_socket connectToHost: _server
				  port: _port];
	else {
		@try {
			SRVLookup = [XMPPSRVLookup
			    lookupWithDomain: _domainToASCII];
		} @catch (id e) {
		}

		enumerator = [SRVLookup objectEnumerator];

		/* Iterate over SRV records, if any */
		if ((candidate = [enumerator nextObject]) != nil) {
			do {
				@try {
					[_socket
					    connectToHost: [candidate target]
						     port: [candidate port]];
					break;
				} @catch (OFAddressTranslationFailedException
				    *e) {
				} @catch (OFConnectionFailedException *e) {
				}
			} while ((candidate = [enumerator nextObject]) != nil);
		} else
			/* No SRV records -> fall back to A / AAAA record */
			[_socket connectToHost: _domainToASCII
					  port: _port];
	}

	[self XMPP_startStream];

	[pool release];
}

- (void)handleConnection
{
	char *buffer = [self allocMemoryWithSize: BUFFER_LENGTH];

	[_socket asyncReadIntoBuffer: buffer
			      length: BUFFER_LENGTH
			      target: self
			    selector: @selector(stream:didReadIntoBuffer:length:
					  exception:)];
}

- (void)asyncConnectAndHandle
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

	[[[[XMPPConnection_ConnectThread alloc]
	    initWithSourceThread: [OFThread currentThread]
		      connection: self] autorelease] start];

	[pool release];
}

-  (BOOL)XMPP_parseBuffer: (const void*)buffer
		   length: (size_t)length
{
	if ([_socket isAtEndOfStream]) {
		[_delegates broadcastSelector: @selector(connectionWasClosed:)
				   withObject: self];
		return NO;
	}

	@try {
		[_parser parseBuffer: buffer
			     length: length];
	} @catch (OFMalformedXMLException *e) {
		[self XMPP_sendStreamError: @"bad-format"
				      text: nil];
		[self close];
		return NO;
	}

	return YES;
}

- (void)parseBuffer: (const void*)buffer
	     length: (size_t)length
{
	[self XMPP_parseBuffer: buffer
			length: length];

	[_oldParser release];
	[_oldElementBuilder release];

	_oldParser = nil;
	_oldElementBuilder = nil;
}

-      (BOOL)stream: (OFStream*)stream
  didReadIntoBuffer: (char*)buffer
	     length: (size_t)length
	  exception: (OFException*)exception
{
	if (exception != nil) {
		[_delegates broadcastSelector: @selector(connection:
						   didThrowException:)
				   withObject: self
				   withObject: exception];
		[self close];
		return NO;
	}

	@try {
		if (![self XMPP_parseBuffer: buffer
				     length: length])
			return NO;
	} @catch (id e) {
		[_delegates broadcastSelector: @selector(connection:
						   didThrowException:)
				   withObject: self
				   withObject: e];
		[self close];
		return NO;
	}

	if (_oldParser != nil || _oldElementBuilder != nil) {
		[_oldParser release];
		[_oldElementBuilder release];

		_oldParser = nil;
		_oldElementBuilder = nil;

		[_socket asyncReadIntoBuffer: buffer
				      length: BUFFER_LENGTH
				      target: self
				    selector: @selector(stream:
						  didReadIntoBuffer:length:
						  exception:)];

		return NO;
	}

	return YES;
}

- (OFTCPSocket*)socket
{
	return [[_socket retain] autorelease];
}

- (BOOL)encryptionRequired
{
	return _encryptionRequired;
}

- (void)setEncryptionRequired: (BOOL)encryptionRequired
{
	_encryptionRequired = encryptionRequired;
}

- (BOOL)encrypted
{
	return _encrypted;
}

- (BOOL)streamOpen
{
	return _streamOpen;
}

- (BOOL)supportsRosterVersioning
{
	return _supportsRosterVersioning;
}

- (BOOL)supportsStreamManagement
{
	return _supportsStreamManagement;
}

- (BOOL)checkCertificateAndGetReason: (OFString**)reason
{
	X509Certificate *cert;
	OFDictionary *SANs;
	BOOL serviceSpecific = NO;

	@try {
		[_socket verifyPeerCertificate];
	} @catch (SSLInvalidCertificateException *e) {
		if (reason != NULL)
			*reason = [[[e reason] copy] autorelease];

		return NO;
	}

	cert = [_socket peerCertificate];
	SANs = [cert subjectAlternativeName];

	if ([[SANs objectForKey: @"otherName"]
		objectForKey: OID_SRVName] != nil ||
	     [SANs objectForKey: @"dNSName"] != nil ||
	     [SANs objectForKey: @"uniformResourceIdentifier"] != nil)
		serviceSpecific = YES;

	if ([cert hasSRVNameMatchingDomain: _domainToASCII
				   service: @"xmpp-client"] ||
	    [cert hasDNSNameMatchingDomain: _domainToASCII])
		return YES;

	if (!serviceSpecific &&
	    [cert hasCommonNameMatchingDomain: _domainToASCII])
		return YES;

	return NO;
}

- (void)sendStanza: (OFXMLElement*)element
{
	[_delegates broadcastSelector: @selector(connection:didSendElement:)
			   withObject: self
			   withObject: element];

	[_socket writeString: [element XMLString]];
}

-   (void)sendIQ: (XMPPIQ*)IQ
  callbackTarget: (id)target
	selector: (SEL)selector
{
	OFAutoreleasePool *pool;
	XMPPCallback *callback;

	if (![IQ ID])
		[IQ setID: [self generateStanzaID]];

	pool = [[OFAutoreleasePool alloc] init];
	callback = [XMPPCallback callbackWithTarget: target
					   selector: selector];
	[_callbacks setObject: callback
		       forKey: [IQ ID]];
	[pool release];

	[self sendStanza: IQ];
}

#ifdef OF_HAVE_BLOCKS
-  (void)sendIQ: (XMPPIQ*)IQ
  callbackBlock: (xmpp_callback_block_t)block
{
	OFAutoreleasePool *pool;
	XMPPCallback *callback;

	if (![IQ ID])
		[IQ setID: [self generateStanzaID]];

	pool = [[OFAutoreleasePool alloc] init];
	callback = [XMPPCallback callbackWithBlock: block];
	[_callbacks setObject: callback
		       forKey: [IQ ID]];
	[pool release];

	[self sendStanza: IQ];
}
#endif

- (OFString*)generateStanzaID
{
	return [OFString stringWithFormat: @"objxmpp_%u", _lastID++];
}

-    (void)parser: (OFXMLParser*)p
  didStartElement: (OFString*)name
	   prefix: (OFString*)prefix
	namespace: (OFString*)ns
       attributes: (OFArray*)attributes
{
	OFEnumerator *enumerator;
	OFXMLAttribute *attribute;

	if (![name isEqual: @"stream"]) {
		// No dedicated stream error for this, may not even be XMPP
		[self close];
		[_socket close];
		return;
	}

	if (![prefix isEqual: @"stream"]) {
		[self XMPP_sendStreamError: @"bad-namespace-prefix"
				      text: nil];
		return;
	}

	if (![ns isEqual: XMPP_NS_STREAM]) {
		[self XMPP_sendStreamError: @"invalid-namespace"
				      text: nil];
		return;
	}

	enumerator = [attributes objectEnumerator];
	while ((attribute = [enumerator nextObject]) != nil) {
		if ([[attribute name] isEqual: @"from"] &&
		    ![[attribute stringValue] isEqual: _domain]) {
			[self XMPP_sendStreamError: @"invalid-from"
					      text: nil];
			return;
		}
		if ([[attribute name] isEqual: @"version"] &&
		    ![[attribute stringValue] isEqual: @"1.0"]) {
			[self XMPP_sendStreamError: @"unsupported-version"
					      text: nil];
			return;
		}
	}

	[_parser setDelegate: _elementBuilder];
}

- (void)elementBuilder: (OFXMLElementBuilder*)builder
       didBuildElement: (OFXMLElement*)element
{
	/* Ignore whitespace elements */
	if ([element name] == nil)
		return;

	[element setDefaultNamespace: XMPP_NS_CLIENT];
	[element setPrefix: @"stream"
	      forNamespace: XMPP_NS_STREAM];

	[_delegates broadcastSelector: @selector(connection:didReceiveElement:)
			   withObject: self
			   withObject: element];

	if ([[element namespace] isEqual: XMPP_NS_CLIENT])
		[self XMPP_handleStanza: element];

	if ([[element namespace] isEqual: XMPP_NS_STREAM])
		[self XMPP_handleStream: element];

	if ([[element namespace] isEqual: XMPP_NS_STARTTLS])
		[self XMPP_handleTLS: element];

	if ([[element namespace] isEqual: XMPP_NS_SASL])
		[self XMPP_handleSASL: element];
}

- (void)elementBuilder: (OFXMLElementBuilder*)builder
  didNotExpectCloseTag: (OFString*)name
		prefix: (OFString*)prefix
	     namespace: (OFString*)ns
{
	if (![name isEqual: @"stream"] || ![prefix isEqual: @"stream"] ||
	    ![ns isEqual: XMPP_NS_STREAM])
		@throw [OFMalformedXMLException
		    exceptionWithClass: [builder class]
				parser: nil];
	else {
		[self close];
	}
}

- (void)XMPP_startStream
{
	OFString *langString = @"";

	/* Make sure we don't get any old events */
	[_parser setDelegate: nil];
	[_elementBuilder setDelegate: nil];

	/*
	 * We can't release them now, as we are currently inside them. Release
	 * them the next time the parser returns.
	 */
	_oldParser = _parser;
	_oldElementBuilder = _elementBuilder;

	_parser = [[OFXMLParser alloc] init];
	[_parser setDelegate: self];

	_elementBuilder = [[XMPPXMLElementBuilder alloc] init];
	[_elementBuilder setDelegate: self];

	if (_language != nil)
		langString = [OFString stringWithFormat: @"xml:lang='%@' ",
							 _language];

	[_socket writeFormat: @"<?xml version='1.0'?>\n"
			      @"<stream:stream to='%@' "
			      @"xmlns='" XMPP_NS_CLIENT @"' "
			      @"xmlns:stream='" XMPP_NS_STREAM @"' %@"
			      @"version='1.0'>", _domain, langString];

	_streamOpen = YES;
}

- (void)close
{
	if (_streamOpen)
		[_socket writeString: @"</stream:stream>"];


	[_oldParser release];
	_oldParser = nil;
	[_oldElementBuilder release];
	_oldElementBuilder = nil;
	[_authModule release];
	_authModule = nil;
	[_socket release];
	_socket = nil;
	[_JID release];
	_JID = nil;
	_streamOpen = _needsSession = _encrypted = NO;
	_supportsRosterVersioning = _supportsStreamManagement = NO;
	_lastID = 0;
}

- (void)XMPP_handleStanza: (OFXMLElement*)element
{
	if ([[element name] isEqual: @"iq"]) {
		[self XMPP_handleIQ: [XMPPIQ stanzaWithElement: element]];
		return;
	}

	if ([[element name] isEqual: @"message"]) {
		[self XMPP_handleMessage:
		    [XMPPMessage stanzaWithElement: element]];
		return;
	}

	if ([[element name] isEqual: @"presence"]) {
		[self XMPP_handlePresence:
		    [XMPPPresence stanzaWithElement: element]];
		return;
	}

	[self XMPP_sendStreamError: @"unsupported-stanza-type"
			      text: nil];
}


- (void)XMPP_handleStream: (OFXMLElement*)element
{
	if ([[element name] isEqual: @"features"]) {
		[self XMPP_handleFeatures: element];
		return;
	}

	if ([[element name] isEqual: @"error"]) {
		OFString *condition, *reason;
		[self close];
		[_socket close]; // Remote has already closed his stream

		if ([element elementForName: @"bad-format"
				  namespace: XMPP_NS_XMPP_STREAM])
			condition = @"bad-format";
		else if ([element elementForName: @"bad-namespace-prefix"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"bad-namespace-prefix";
		else if ([element elementForName: @"conflict"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"conflict";
		else if ([element elementForName: @"connection-timeout"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"connection-timeout";
		else if ([element elementForName: @"host-gone"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"host-gone";
		else if ([element elementForName: @"host-unknown"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"host-unknown";
		else if ([element elementForName: @"improper-addressing"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"improper-addressing";
		else if ([element elementForName: @"internal-server-error"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"internal-server-error";
		else if ([element elementForName: @"invalid-from"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"invalid-from";
		else if ([element elementForName: @"invalid-namespace"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"invalid-namespace";
		else if ([element elementForName: @"invalid-xml"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"invalid-xml";
		else if ([element elementForName: @"not-authorized"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"not-authorized";
		else if ([element elementForName: @"not-well-formed"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"not-well-formed";
		else if ([element elementForName: @"policy-violation"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"policy-violation";
		else if ([element elementForName: @"remote-connection-failed"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"remote-connection-failed";
		else if ([element elementForName: @"reset"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"reset";
		else if ([element elementForName: @"resource-constraint"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"resource-constraint";
		else if ([element elementForName: @"restricted-xml"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"restricted-xml";
		else if ([element elementForName: @"see-other-host"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"see-other-host";
		else if ([element elementForName: @"system-shutdown"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"system-shutdown";
		else if ([element elementForName: @"undefined-condition"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"undefined-condition";
		else if ([element elementForName: @"unsupported-encoding"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"unsupported-encoding";
		else if ([element elementForName: @"unsupported-feature"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"unsupported-feature";
		else if ([element elementForName: @"unsupported-stanza-type"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"unsupported-stanza-type";
		else if ([element elementForName: @"unsupported-version"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"unsupported-version";
		else
			condition = @"undefined";

		reason = [[element
		    elementForName: @"text"
			 namespace: XMPP_NS_XMPP_STREAM] stringValue];

		@throw [XMPPStreamErrorException
		    exceptionWithClass: [self class]
			    connection: self
			     condition: condition
				reason: reason];
		return;
	}

	assert(0);
}

- (void)XMPP_handleTLS: (OFXMLElement*)element
{
	if ([[element name] isEqual: @"proceed"]) {
		/* FIXME: Catch errors here */
		SSLSocket *newSock;

		[_delegates broadcastSelector: @selector(
						   connectionWillUpgradeToTLS:)
				   withObject: self];

		newSock = [[SSLSocket alloc] initWithSocket: _socket];
		[newSock setCertificateFile: _certificateFile];
		[newSock setPrivateKeyFile: _privateKeyFile];
		[newSock setPrivateKeyPassphrase: _privateKeyPassphrase];
		[newSock startTLS];
		[_socket release];
		_socket = newSock;

		_encrypted = YES;

		[_delegates broadcastSelector: @selector(
						   connectionDidUpgradeToTLS:)
				   withObject: self];

		/* Stream restart */
		[self XMPP_startStream];

		return;
	}

	if ([[element name] isEqual: @"failure"])
		/* TODO: Find/create an exception to throw here */
		@throw [OFException exceptionWithClass: [self class]];

	assert(0);
}

- (void)XMPP_handleSASL: (OFXMLElement*)element
{
	if ([[element name] isEqual: @"challenge"]) {
		OFXMLElement *responseTag;
		OFDataArray *challenge = [OFDataArray
		    dataArrayWithBase64EncodedString: [element stringValue]];
		OFDataArray *response = [_authModule
		    continueWithData: challenge];

		responseTag = [OFXMLElement elementWithName: @"response"
						  namespace: XMPP_NS_SASL];
		if (response) {
			if ([response count] == 0)
				[responseTag setStringValue: @"="];
			else
				[responseTag setStringValue:
				    [response stringByBase64Encoding]];
		}

		[self sendStanza: responseTag];
		return;
	}

	if ([[element name] isEqual: @"success"]) {
		[_authModule continueWithData: [OFDataArray
		    dataArrayWithBase64EncodedString: [element stringValue]]];

		[_delegates broadcastSelector: @selector(
						   connectionWasAuthenticated:)
				   withObject: self];

		/* Stream restart */
		[self XMPP_startStream];

		return;
	}

	if ([[element name] isEqual: @"failure"]) {
		of_log(@"Auth failed!");
		// FIXME: Do more parsing/handling
		@throw [XMPPAuthFailedException
		    exceptionWithClass: [self class]
			    connection: self
				reason: [element XMLString]];
	}

	assert(0);
}

- (void)XMPP_handleIQ: (XMPPIQ*)iq
{
	BOOL handled = NO;
	XMPPCallback *callback;

	if ((callback = [_callbacks objectForKey: [iq ID]])) {
		[callback runWithIQ: iq
			 connection: self];
		[_callbacks removeObjectForKey: [iq ID]];
		return;
	}

	handled = [_delegates broadcastSelector: @selector(
						     connection:didReceiveIQ:)
				     withObject: self
				     withObject: iq];

	if (!handled && ![[iq type] isEqual: @"error"] &&
	    ![[iq type] isEqual: @"result"]) {
		[self sendStanza: [iq errorIQWithType: @"cancel"
					    condition: @"service-unavailable"]];
	}
}

- (void)XMPP_handleMessage: (XMPPMessage*)message
{
	[_delegates broadcastSelector: @selector(connection:didReceiveMessage:)
			   withObject: self
			   withObject: message];
}

- (void)XMPP_handlePresence: (XMPPPresence*)presence
{
	[_delegates broadcastSelector: @selector(connection:didReceivePresence:)
			   withObject: self
			   withObject: presence];
}

- (void)XMPP_handleFeatures: (OFXMLElement*)element
{
	OFXMLElement *startTLS = [element elementForName: @"starttls"
					       namespace: XMPP_NS_STARTTLS];
	OFXMLElement *bind = [element elementForName: @"bind"
					   namespace: XMPP_NS_BIND];
	OFXMLElement *session = [element elementForName: @"session"
					      namespace: XMPP_NS_SESSION];
	OFXMLElement *mechs = [element elementForName: @"mechanisms"
					    namespace: XMPP_NS_SASL];
	OFMutableSet *mechanisms = [OFMutableSet set];

	if (!_encrypted && startTLS != nil) {
		[self sendStanza:
		    [OFXMLElement elementWithName: @"starttls"
					namespace: XMPP_NS_STARTTLS]];
		return;
	}

	if (_encryptionRequired && !_encrypted)
		/* TODO: Find/create an exception to throw here */
		@throw [OFException exceptionWithClass: [self class]];

	if ([element elementForName: @"ver"
			  namespace: XMPP_NS_ROSTERVER] != nil)
		_supportsRosterVersioning = YES;

	if ([element elementForName: @"sm"
			  namespace: XMPP_NS_SM] != nil)
		_supportsStreamManagement = YES;

	if (mechs != nil) {
		OFEnumerator *enumerator;
		OFXMLElement *mech;

		enumerator = [[mechs children] objectEnumerator];
		while ((mech = [enumerator nextObject]) != nil)
			[mechanisms addObject: [mech stringValue]];

		if (_privateKeyFile && _certificateFile &&
		    [mechanisms containsObject: @"EXTERNAL"]) {
			_authModule = [[XMPPEXTERNALAuth alloc] init];
			[self XMPP_sendAuth: @"EXTERNAL"];
			return;
		}

		if ([mechanisms containsObject: @"SCRAM-SHA-1-PLUS"]) {
			_authModule = [[XMPPSCRAMAuth alloc]
			    initWithAuthcid: _username
				   password: _password
				 connection: self
				       hash: [OFSHA1Hash class]
			      plusAvailable: YES];
			[self XMPP_sendAuth: @"SCRAM-SHA-1-PLUS"];
			return;
		}

		if ([mechanisms containsObject: @"SCRAM-SHA-1"]) {
			_authModule = [[XMPPSCRAMAuth alloc]
			    initWithAuthcid: _username
				   password: _password
				 connection: self
				       hash: [OFSHA1Hash class]
			      plusAvailable: NO];
			[self XMPP_sendAuth: @"SCRAM-SHA-1"];
			return;
		}

		if ([mechanisms containsObject: @"PLAIN"] && _encrypted) {
			_authModule = [[XMPPPLAINAuth alloc]
			    initWithAuthcid: _username
				   password: _password];
			[self XMPP_sendAuth: @"PLAIN"];
			return;
		}

		assert(0);
	}

	if (session != nil)
		_needsSession = YES;

	if (bind != nil) {
		[self XMPP_sendResourceBind];
		return;
	}

	assert(0);
}

- (void)XMPP_sendAuth: (OFString*)authName
{
	OFXMLElement *authTag;
	OFDataArray *initialMessage = [_authModule initialMessage];

	authTag = [OFXMLElement elementWithName: @"auth"
				      namespace: XMPP_NS_SASL];
	[authTag addAttributeWithName: @"mechanism"
			  stringValue: authName];
	if (initialMessage) {
		if ([initialMessage count] == 0)
			[authTag setStringValue: @"="];
		else
			[authTag setStringValue:
			    [initialMessage stringByBase64Encoding]];
	}

	[self sendStanza: authTag];
}

- (void)XMPP_sendResourceBind
{
	XMPPIQ *IQ;
	OFXMLElement *bind;

	IQ = [XMPPIQ IQWithType: @"set"
			     ID: [self generateStanzaID]];

	bind = [OFXMLElement elementWithName: @"bind"
				   namespace: XMPP_NS_BIND];

	if (_resource != nil)
		[bind addChild: [OFXMLElement elementWithName: @"resource"
						    namespace: XMPP_NS_BIND
						  stringValue: _resource]];

	[IQ addChild: bind];

	[self	    sendIQ: IQ
	    callbackTarget: self
		  selector: @selector(XMPP_handleResourceBindForConnection:
				IQ:)];
}

- (void)XMPP_sendStreamError: (OFString*)condition
			text: (OFString*)text
{
	OFXMLElement *error = [OFXMLElement
	    elementWithName: @"error"
		  namespace: XMPP_NS_STREAM];
	[error setPrefix: @"stream"
	    forNamespace: XMPP_NS_STREAM];
	[error addChild: [OFXMLElement elementWithName: condition
					     namespace: XMPP_NS_XMPP_STREAM]];
	if (text)
		[error addChild: [OFXMLElement
		    elementWithName: @"text"
			  namespace: XMPP_NS_XMPP_STREAM
			stringValue: text]];
	[_parser setDelegate: nil];
	[self sendStanza: error];
	[self close];
}

- (void)XMPP_handleResourceBindForConnection: (XMPPConnection*)connection
					  IQ: (XMPPIQ*)iq
{
	OFXMLElement *bindElement;
	OFXMLElement *jidElement;

	assert([[iq type] isEqual: @"result"]);

	bindElement = [iq elementForName: @"bind"
			       namespace: XMPP_NS_BIND];

	assert(bindElement != nil);

	jidElement = [bindElement elementForName: @"jid"
				       namespace: XMPP_NS_BIND];
	_JID = [[XMPPJID alloc] initWithString: [jidElement stringValue]];

	if (_needsSession) {
		[self XMPP_sendSession];
		return;
	}

	[_delegates broadcastSelector: @selector(connection:wasBoundToJID:)
			   withObject: self
			   withObject: _JID];
}

- (void)XMPP_sendSession
{
	XMPPIQ *iq;

	iq = [XMPPIQ IQWithType: @"set"
			     ID: [self generateStanzaID]];
	[iq addChild: [OFXMLElement elementWithName: @"session"
					  namespace: XMPP_NS_SESSION]];
	[self	    sendIQ: iq
	    callbackTarget: self
		  selector: @selector(XMPP_handleSessionForConnection:IQ:)];
}

- (void)XMPP_handleSessionForConnection: (XMPPConnection*)connection
				     IQ: (XMPPIQ*)iq
{
	if (![[iq type] isEqual: @"result"])
		assert(0);

	[_delegates broadcastSelector: @selector(connection:wasBoundToJID:)
			   withObject: self
			   withObject: _JID];
}

- (OFString*)XMPP_IDNAToASCII: (OFString*)domain_
{
	OFString *ret;
	char *cDomain;
	Idna_rc rc;

	if ((rc = idna_to_ascii_8z([domain_ UTF8String],
	    &cDomain, IDNA_USE_STD3_ASCII_RULES)) != IDNA_SUCCESS)
		@throw [XMPPIDNATranslationFailedException
		    exceptionWithClass: [self class]
			    connection: self
			     operation: @"ToASCII"
				string: domain_];

	@try {
		ret = [[OFString alloc] initWithUTF8String: cDomain];
	} @finally {
		free(cDomain);
	}

	return ret;
}

- (XMPPJID*)JID
{
	return [[_JID copy] autorelease];
}

- (void)setPort: (uint16_t)port
{
	_port = port;
}

- (uint16_t)port
{
	return _port;
}

- (void)setDataStorage: (id <XMPPStorage>)dataStorage
{
	if (_streamOpen)
		@throw [OFInvalidArgumentException
		    exceptionWithClass: [self class]];

	_dataStorage = dataStorage;
}

- (id <XMPPStorage>)dataStorage
{
	return _dataStorage;
}

- (void)setLanguage: (OFString*)language
{
	OF_SETTER(_language, language, YES, YES)
}

- (OFString*)language
{
	OF_GETTER(_language, YES)
}

- (void)addDelegate: (id <XMPPConnectionDelegate>)delegate
{
	[_delegates addDelegate: delegate];
}

- (void)removeDelegate: (id <XMPPConnectionDelegate>)delegate
{
	[_delegates removeDelegate: delegate];
}

- (XMPPMulticastDelegate*)XMPP_delegates
{
	return _delegates;
}
@end
