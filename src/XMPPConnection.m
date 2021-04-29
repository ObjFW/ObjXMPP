/*
 * Copyright (c) 2010, 2011, 2012, 2013, 2015, 2016, 2017, 2018, 2019, 2021
 *   Jonathan Schleifer <js@nil.im>
 * Copyright (c) 2011, 2012, Florian Zeitz <florob@babelmonkeys.de>
 *
 * https://heap.zone/objxmpp/
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

#include "config.h"

#define XMPP_CONNECTION_M

#include <assert.h>

#include <stringprep.h>
#include <idna.h>

#import <ObjOpenSSL/SSLSocket.h>
#import <ObjOpenSSL/SSLInvalidCertificateException.h>
#import <ObjOpenSSL/X509Certificate.h>

#import <ObjFW/OFInvalidArgumentException.h>

#import "XMPPConnection.h"
#import "XMPPANONYMOUSAuth.h"
#import "XMPPCallback.h"
#import "XMPPEXTERNALAuth.h"
#import "XMPPExceptions.h"
#import "XMPPIQ.h"
#import "XMPPJID.h"
#import "XMPPMessage.h"
#import "XMPPMulticastDelegate.h"
#import "XMPPPLAINAuth.h"
#import "XMPPPresence.h"
#import "XMPPSCRAMAuth.h"
#import "XMPPStanza.h"
#import "XMPPXMLElementBuilder.h"

#import "namespaces.h"

#import <ObjFW/macros.h>

@interface XMPPConnection () <OFDNSResolverQueryDelegate, OFTCPSocketDelegate,
    OFXMLParserDelegate, OFXMLElementBuilderDelegate>
- (void)xmpp_tryNextSRVRecord;
-  (bool)xmpp_parseBuffer: (const void *)buffer length: (size_t)length;
- (void)xmpp_startStream;
- (void)xmpp_handleStanza: (OFXMLElement *)element;
- (void)xmpp_handleStream: (OFXMLElement *)element;
- (void)xmpp_handleTLS: (OFXMLElement *)element;
- (void)xmpp_handleSASL: (OFXMLElement *)element;
- (void)xmpp_handleIQ: (XMPPIQ *)IQ;
- (void)xmpp_handleMessage: (XMPPMessage *)message;
- (void)xmpp_handlePresence: (XMPPPresence *)presence;
- (void)xmpp_handleFeatures: (OFXMLElement *)element;
- (void)xmpp_sendAuth: (OFString *)authName;
- (void)xmpp_sendResourceBind;
- (void)xmpp_sendStreamError: (OFString *)condition text: (OFString *)text;
- (void)xmpp_handleResourceBindForConnection: (XMPPConnection *)connection
					  IQ: (XMPPIQ *)IQ;
- (void)xmpp_sendSession;
- (void)xmpp_handleSessionForConnection: (XMPPConnection *)connection
				     IQ: (XMPPIQ *)IQ;
- (OFString *)xmpp_IDNAToASCII: (OFString *)domain;
- (XMPPMulticastDelegate *)xmpp_delegates;
@end

@implementation XMPPConnection
@synthesize username = _username, resource = _resource, server = _server;
@synthesize domain = _domain, password = _password, JID = _JID, port = _port;
@synthesize usesAnonymousAuthentication = _usesAnonymousAuthentication;
@synthesize language = _language, privateKeyFile = _privateKeyFile;
@synthesize certificateFile = _certificateFile, socket = _socket;
@synthesize encryptionRequired = _encryptionRequired, encrypted = _encrypted;
@synthesize supportsRosterVersioning = _supportsRosterVersioning;
@synthesize supportsStreamManagement = _supportsStreamManagement;

+ (instancetype)connection
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	self = [super init];

	@try {
		_port = 5222;
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
	[_nextSRVRecords release];
	[_delegates release];
	[_callbacks release];
	[_authModule release];

	[super dealloc];
}

- (void)setUsername: (OFString *)username
{
	OFString *old = _username;

	if (username != nil) {
		char *node;
		Stringprep_rc rc;

		if ((rc = stringprep_profile(username.UTF8String, &node,
		    "SASLprep", 0)) != STRINGPREP_OK)
			@throw [XMPPStringPrepFailedException
			    exceptionWithConnection: self
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

- (void)setResource: (OFString *)resource
{
	OFString *old = _resource;

	if (resource != nil) {
		char *res;
		Stringprep_rc rc;

		if ((rc = stringprep_profile(resource.UTF8String, &res,
		    "Resourceprep", 0)) != STRINGPREP_OK)
			@throw [XMPPStringPrepFailedException
			    exceptionWithConnection: self
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

- (void)setServer: (OFString *)server
{
	OFString *old = _server;

	if (server != nil)
		_server = [self xmpp_IDNAToASCII: server];
	else
		_server = nil;

	[old release];
}

- (void)setDomain: (OFString *)domain
{
	OFString *oldDomain = _domain;
	OFString *oldDomainToASCII = _domainToASCII;

	if (domain != nil) {
		char *srv;
		Stringprep_rc rc;

		if ((rc = stringprep_profile(domain.UTF8String, &srv,
		    "Nameprep", 0)) != STRINGPREP_OK)
			@throw [XMPPStringPrepFailedException
			    exceptionWithConnection: self
					    profile: @"Nameprep"
					     string: domain];

		@try {
			_domain = [[OFString alloc] initWithUTF8String: srv];
		} @finally {
			free(srv);
		}

		_domainToASCII = [self xmpp_IDNAToASCII: _domain];
	} else {
		_domain = nil;
		_domainToASCII = nil;
	}

	[oldDomain release];
	[oldDomainToASCII release];
}

- (void)setPassword: (OFString *)password
{
	OFString *old = _password;

	if (password != nil) {
		char *pass;
		Stringprep_rc rc;

		if ((rc = stringprep_profile(password.UTF8String, &pass,
		    "SASLprep", 0)) != STRINGPREP_OK)
			@throw [XMPPStringPrepFailedException
			    exceptionWithConnection: self
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

-     (void)socket: (OFTCPSocket *)sock
  didConnectToHost: (OFString *)host
	      port: (uint16_t)port
	 exception: (id)exception
{
	if (exception != nil) {
		if (_nextSRVRecords.count > 0) {
			[self xmpp_tryNextSRVRecord];
			return;
		}

		[_delegates broadcastSelector: @selector(connection:
						   didThrowException:)
				   withObject: self
				   withObject: exception];
		return;
	}

	[self xmpp_startStream];

	[_socket asyncReadIntoBuffer: _buffer
			      length: XMPPConnectionBufferLength];
}

- (void)xmpp_tryNextSRVRecord
{
	OFSRVDNSResourceRecord *record =
	    [[[_nextSRVRecords objectAtIndex: 0] copy] autorelease];

	if (_nextSRVRecords.count == 0) {
		[_nextSRVRecords release];
		_nextSRVRecords = nil;
	}

	[_socket asyncConnectToHost: record.target port: record.port];
}

-  (void)resolver: (OFDNSResolver *)resolver
  didPerformQuery: (OFString *)domainName
	 response: (OFDNSResponse *)response
	exception: (id)exception
{
	OFMutableArray *records = [OFMutableArray array];

	if (exception != nil)
		response = nil;

	for (OFDNSResourceRecord *record in
	    [response.answerRecords objectForKey: domainName])
		if ([record isKindOfClass: [OFSRVDNSResourceRecord class]])
		       [records addObject: record];

	/* TODO: Sort records */
	[records makeImmutable];

	if (records.count == 0) {
		/* Fall back to A / AAAA record. */
		[_socket asyncConnectToHost: _domainToASCII port: _port];
		return;
	}

	[_nextSRVRecords release];
	_nextSRVRecords = nil;
	_nextSRVRecords = [records mutableCopy];
	[self xmpp_tryNextSRVRecord];
}

- (void)asyncConnect
{
	void *pool = objc_autoreleasePoolPush();

	if (_socket != nil)
		@throw [OFAlreadyConnectedException exception];

	_socket = [[OFTCPSocket alloc] init];
	[_socket setDelegate: self];

	if (_server != nil)
		[_socket asyncConnectToHost: _server port: _port];
	else {
		OFString *SRVDomain = [_domainToASCII
		    stringByPrependingString: @"_xmpp-client._tcp."];
		OFDNSQuery *query = [OFDNSQuery
		    queryWithDomainName: SRVDomain
			       DNSClass: OFDNSClassIN
			     recordType: OFDNSRecordTypeSRV];
		[[OFThread DNSResolver] asyncPerformQuery: query
						 delegate: self];
	}

	objc_autoreleasePoolPop(pool);
}

-  (bool)xmpp_parseBuffer: (const void *)buffer
		   length: (size_t)length
{
	if (_socket.atEndOfStream) {
		[_delegates broadcastSelector: @selector(connectionWasClosed:
						   error:)
				   withObject: self
				   withObject: nil];
		return false;
	}

	@try {
		[_parser parseBuffer: buffer length: length];
	} @catch (OFMalformedXMLException *e) {
		[self xmpp_sendStreamError: @"bad-format" text: nil];
		[self close];
		return false;
	}

	return true;
}

- (void)parseBuffer: (const void *)buffer length: (size_t)length
{
	[self xmpp_parseBuffer: buffer length: length];

	[_oldParser release];
	[_oldElementBuilder release];

	_oldParser = nil;
	_oldElementBuilder = nil;
}

-      (bool)stream: (OF_KINDOF(OFStream *))stream
  didReadIntoBuffer: (void *)buffer
	     length: (size_t)length
	  exception: (id)exception
{
	if (exception != nil) {
		[_delegates broadcastSelector: @selector(connection:
						   didThrowException:)
				   withObject: self
				   withObject: exception];
		[self close];
		return false;
	}

	@try {
		if (![self xmpp_parseBuffer: buffer length: length])
			return false;
	} @catch (id e) {
		[_delegates broadcastSelector: @selector(connection:
						   didThrowException:)
				   withObject: self
				   withObject: e];
		[self close];
		return false;
	}

	if (_oldParser != nil || _oldElementBuilder != nil) {
		[_oldParser release];
		[_oldElementBuilder release];

		_oldParser = nil;
		_oldElementBuilder = nil;

		[_socket asyncReadIntoBuffer: _buffer
				      length: XMPPConnectionBufferLength];
		return false;
	}

	return true;
}

- (bool)streamOpen
{
	return _streamOpen;
}

- (bool)checkCertificateAndGetReason: (OFString **)reason
{
	X509Certificate *cert;
	OFDictionary *SANs;
	bool serviceSpecific = false;
	SSLSocket *socket = (SSLSocket *)_socket;

	@try {
		[socket verifyPeerCertificate];
	} @catch (SSLInvalidCertificateException *e) {
		if (reason != NULL)
			*reason = e.reason;

		return false;
	}

	cert = socket.peerCertificate;
	SANs = cert.subjectAlternativeName;

	if ([[SANs objectForKey: @"otherName"]
	    objectForKey: OID_SRVName] != nil ||
	    [SANs objectForKey: @"dNSName"] != nil ||
	    [SANs objectForKey: @"uniformResourceIdentifier"] != nil)
		serviceSpecific = true;

	if ([cert hasSRVNameMatchingDomain: _domainToASCII
				   service: @"xmpp-client"] ||
	    [cert hasDNSNameMatchingDomain: _domainToASCII])
		return true;

	if (!serviceSpecific &&
	    [cert hasCommonNameMatchingDomain: _domainToASCII])
		return true;

	return false;
}

- (void)sendStanza: (OFXMLElement *)element
{
	[_delegates broadcastSelector: @selector(connection:didSendElement:)
			   withObject: self
			   withObject: element];

	[_socket writeString: element.XMLString];
}

-   (void)sendIQ: (XMPPIQ *)IQ
  callbackTarget: (id)target
	selector: (SEL)selector
{
	void *pool = objc_autoreleasePoolPush();
	XMPPCallback *callback;
	OFString *ID, *key;

	if ((ID = IQ.ID) == nil) {
		ID = [self generateStanzaID];
		IQ.ID = ID;
	}

	if ((key = IQ.to.fullJID) == nil)
		key = _JID.bareJID;
	if (key == nil) // Only happens for resource bind
		key = @"bind";
	key = [key stringByAppendingString: ID];

	callback = [XMPPCallback callbackWithTarget: target selector: selector];
	[_callbacks setObject: callback forKey: key];

	objc_autoreleasePoolPop(pool);

	[self sendStanza: IQ];
}

#ifdef OF_HAVE_BLOCKS
-  (void)sendIQ: (XMPPIQ *)IQ callbackBlock: (XMPPCallbackBlock)block
{
	void *pool = objc_autoreleasePoolPush();
	XMPPCallback *callback;
	OFString *ID, *key;

	if ((ID = IQ.ID) == nil) {
		ID = [self generateStanzaID];
		IQ.ID = ID;
	}

	if ((key = IQ.to.fullJID) == nil)
		key = _JID.bareJID;
	if (key == nil) // Connection not yet bound, can't send stanzas
		@throw [OFInvalidArgumentException exception];
	key = [key stringByAppendingString: ID];

	callback = [XMPPCallback callbackWithBlock: block];
	[_callbacks setObject: callback forKey: key];

	objc_autoreleasePoolPop(pool);

	[self sendStanza: IQ];
}
#endif

- (OFString *)generateStanzaID
{
	return [OFString stringWithFormat: @"objxmpp_%u", _lastID++];
}

-    (void)parser: (OFXMLParser *)parser
  didStartElement: (OFString *)name
	   prefix: (OFString *)prefix
	namespace: (OFString *)namespace
       attributes: (OFArray *)attributes
{
	if (![name isEqual: @"stream"]) {
		// No dedicated stream error for this, may not even be XMPP
		[self close];
		[_socket close];
		return;
	}

	if (![prefix isEqual: @"stream"]) {
		[self xmpp_sendStreamError: @"bad-namespace-prefix" text: nil];
		return;
	}

	if (![namespace isEqual: XMPPStreamNS]) {
		[self xmpp_sendStreamError: @"invalid-namespace" text: nil];
		return;
	}

	for (OFXMLAttribute *attribute in attributes) {
		if ([attribute.name isEqual: @"from"] &&
		    ![attribute.stringValue isEqual: _domain]) {
			[self xmpp_sendStreamError: @"invalid-from" text: nil];
			return;
		}
		if ([attribute.name isEqual: @"version"] &&
		    ![attribute.stringValue isEqual: @"1.0"]) {
			[self xmpp_sendStreamError: @"unsupported-version"
					      text: nil];
			return;
		}
	}

	parser.delegate = _elementBuilder;
}

- (void)elementBuilder: (OFXMLElementBuilder *)builder
       didBuildElement: (OFXMLElement *)element
{
	/* Ignore whitespace elements */
	if (element.name == nil)
		return;

	element.defaultNamespace = XMPPClientNS;
	[element setPrefix: @"stream" forNamespace: XMPPStreamNS];

	[_delegates broadcastSelector: @selector(connection:didReceiveElement:)
			   withObject: self
			   withObject: element];

	if ([element.namespace isEqual: XMPPClientNS])
		[self xmpp_handleStanza: element];

	if ([element.namespace isEqual: XMPPStreamNS])
		[self xmpp_handleStream: element];

	if ([element.namespace isEqual: XMPPStartTLSNS])
		[self xmpp_handleTLS: element];

	if ([element.namespace isEqual: XMPPSASLNS])
		[self xmpp_handleSASL: element];
}

- (void)elementBuilder: (OFXMLElementBuilder *)builder
  didNotExpectCloseTag: (OFString *)name
		prefix: (OFString *)prefix
	     namespace: (OFString *)ns
{
	if (![name isEqual: @"stream"] || ![prefix isEqual: @"stream"] ||
	    ![ns isEqual: XMPPStreamNS])
		@throw [OFMalformedXMLException exception];
	else
		[self close];
}

- (void)xmpp_startStream
{
	OFString *langString = @"";

	/* Make sure we don't get any old events */
	_parser.delegate = nil;
	_elementBuilder.delegate = nil;

	/*
	 * We can't release them now, as we are currently inside them. Release
	 * them the next time the parser returns.
	 */
	_oldParser = _parser;
	_oldElementBuilder = _elementBuilder;

	_parser = [[OFXMLParser alloc] init];
	_parser.delegate = self;

	_elementBuilder = [[XMPPXMLElementBuilder alloc] init];
	_elementBuilder.delegate = self;

	if (_language != nil)
		langString = [OFString stringWithFormat: @"xml:lang='%@' ",
							 _language];

	[_socket writeFormat: @"<?xml version='1.0'?>\n"
			      @"<stream:stream to='%@' "
			      @"xmlns='%@' "
			      @"xmlns:stream='%@' %@"
			      @"version='1.0'>",
			      _domain, 
			      XMPPClientNS,
			      XMPPStreamNS,
			      langString];

	_streamOpen = true;
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
	_streamOpen = _needsSession = _encrypted = false;
	_supportsRosterVersioning = _supportsStreamManagement = false;
	_lastID = 0;
}

- (void)xmpp_handleStanza: (OFXMLElement *)element
{
	if ([element.name isEqual: @"iq"]) {
		[self xmpp_handleIQ: [XMPPIQ stanzaWithElement: element]];
		return;
	}

	if ([element.name isEqual: @"message"]) {
		[self xmpp_handleMessage:
		    [XMPPMessage stanzaWithElement: element]];
		return;
	}

	if ([element.name isEqual: @"presence"]) {
		[self xmpp_handlePresence:
		    [XMPPPresence stanzaWithElement: element]];
		return;
	}

	[self xmpp_sendStreamError: @"unsupported-stanza-type" text: nil];
}


- (void)xmpp_handleStream: (OFXMLElement *)element
{
	if ([element.name isEqual: @"features"]) {
		[self xmpp_handleFeatures: element];
		return;
	}

	if ([element.name isEqual: @"error"]) {
		OFString *condition, *reason;
		[self close];

		[_delegates broadcastSelector: @selector(connectionWasClosed:)
				   withObject: self
				   withObject: element];

		condition = [[element elementsForNamespace: XMPPXMPPStreamNS]
		    .firstObject name];

		if (condition == nil)
			condition = @"undefined";

		reason = [element elementForName: @"text"
				       namespace: XMPPXMPPStreamNS].stringValue;

		@throw [XMPPStreamErrorException
		    exceptionWithConnection: self
				  condition: condition
				     reason: reason];
		return;
	}

	assert(0);
}

- (void)xmpp_handleTLS: (OFXMLElement *)element
{
	if ([element.name isEqual: @"proceed"]) {
		/* FIXME: Catch errors here */
		SSLSocket *newSock;

		[_delegates broadcastSelector: @selector(
						   connectionWillUpgradeToTLS:)
				   withObject: self];

		newSock = [[SSLSocket alloc] initWithSocket: _socket];
		newSock.verifiesCertificates = false;
#if 0
		/* FIXME: Not yet implemented by ObjOpenSSL */
		[newSock setCertificateFile: _certificateFile];
		[newSock setPrivateKeyFile: _privateKeyFile];
		[newSock setPrivateKeyPassphrase: _privateKeyPassphrase];
#endif
		[newSock startTLSWithExpectedHost: nil];
		[_socket release];
		_socket = newSock;
		[_socket setDelegate: self];

		_encrypted = true;

		[_delegates broadcastSelector: @selector(
						   connectionDidUpgradeToTLS:)
				   withObject: self];

		/* Stream restart */
		[self xmpp_startStream];

		return;
	}

	if ([element.name isEqual: @"failure"])
		/* TODO: Find/create an exception to throw here */
		@throw [OFException exception];

	assert(0);
}

- (void)xmpp_handleSASL: (OFXMLElement *)element
{
	if ([element.name isEqual: @"challenge"]) {
		OFXMLElement *responseTag;
		OFData *challenge =
		    [OFData dataWithBase64EncodedString: element.stringValue];
		OFData *response = [_authModule continueWithData: challenge];

		responseTag = [OFXMLElement elementWithName: @"response"
						  namespace: XMPPSASLNS];
		if (response) {
			if (response.count == 0)
				responseTag.stringValue = @"=";
			else
				responseTag.stringValue =
				    response.stringByBase64Encoding;
		}

		[self sendStanza: responseTag];
		return;
	}

	if ([element.name isEqual: @"success"]) {
		[_authModule continueWithData: [OFData
		    dataWithBase64EncodedString: element.stringValue]];

		[_delegates broadcastSelector: @selector(
						   connectionWasAuthenticated:)
				   withObject: self];

		/* Stream restart */
		[self xmpp_startStream];

		return;
	}

	if ([element.name isEqual: @"failure"]) {
		/* FIXME: Do more parsing/handling */
		@throw [XMPPAuthFailedException
		    exceptionWithConnection: self
				     reason: element.XMLString];
	}

	assert(0);
}

- (void)xmpp_handleIQ: (XMPPIQ *)IQ
{
	bool handled = false;
	XMPPCallback *callback;
	OFString *key;

	if ((key = IQ.from.fullJID) == nil)
		key = _JID.bareJID;
	if (key == nil) // Only happens for resource bind
		key = @"bind";
	key = [key stringByAppendingString: IQ.ID];

	if ((callback = [_callbacks objectForKey: key])) {
		[callback runWithIQ: IQ connection: self];
		[_callbacks removeObjectForKey: key];
		return;
	}

	handled = [_delegates broadcastSelector: @selector(
						     connection:didReceiveIQ:)
				     withObject: self
				     withObject: IQ];

	if (!handled && ![IQ.type isEqual: @"error"] &&
	    ![IQ.type isEqual: @"result"]) {
		[self sendStanza: [IQ errorIQWithType: @"cancel"
					    condition: @"service-unavailable"]];
	}
}

- (void)xmpp_handleMessage: (XMPPMessage *)message
{
	[_delegates broadcastSelector: @selector(connection:didReceiveMessage:)
			   withObject: self
			   withObject: message];
}

- (void)xmpp_handlePresence: (XMPPPresence *)presence
{
	[_delegates broadcastSelector: @selector(connection:didReceivePresence:)
			   withObject: self
			   withObject: presence];
}

- (void)xmpp_handleFeatures: (OFXMLElement *)element
{
	OFXMLElement *startTLS = [element elementForName: @"starttls"
					       namespace: XMPPStartTLSNS];
	OFXMLElement *bind = [element elementForName: @"bind"
					   namespace: XMPPBindNS];
	OFXMLElement *session = [element elementForName: @"session"
					      namespace: XMPPSessionNS];
	OFXMLElement *mechs = [element elementForName: @"mechanisms"
					    namespace: XMPPSASLNS];
	OFMutableSet *mechanisms = [OFMutableSet set];

	if (!_encrypted && startTLS != nil) {
		[self sendStanza:
		    [OFXMLElement elementWithName: @"starttls"
					namespace: XMPPStartTLSNS]];
		return;
	}

	if (_encryptionRequired && !_encrypted)
		/* TODO: Find/create an exception to throw here */
		@throw [OFException exception];

	if ([element elementForName: @"ver" namespace: XMPPRosterVerNS] != nil)
		_supportsRosterVersioning = true;

	if ([element elementForName: @"sm" namespace: XMPPSMNS] != nil)
		_supportsStreamManagement = true;

	if (mechs != nil) {
		for (OFXMLElement *mech in mechs.children)
			[mechanisms addObject: mech.stringValue];

		if (_usesAnonymousAuthentication) {
			if (![mechanisms containsObject: @"ANONYMOUS"])
				@throw [XMPPAuthFailedException
				    exceptionWithConnection: self
						     reason: @"No supported "
							     @"auth mechanism"];

			_authModule = [[XMPPANONYMOUSAuth alloc] init];
			[self xmpp_sendAuth: @"ANONYMOUS"];
			return;
		}

		if (_privateKeyFile != nil && _certificateFile != nil &&
		    [mechanisms containsObject: @"EXTERNAL"]) {
			_authModule = [[XMPPEXTERNALAuth alloc] init];
			[self xmpp_sendAuth: @"EXTERNAL"];
			return;
		}

		if ([mechanisms containsObject: @"SCRAM-SHA-1-PLUS"]) {
			_authModule = [[XMPPSCRAMAuth alloc]
			    initWithAuthcid: _username
				   password: _password
				 connection: self
				       hash: [OFSHA1Hash class]
			      plusAvailable: true];
			[self xmpp_sendAuth: @"SCRAM-SHA-1-PLUS"];
			return;
		}

		if ([mechanisms containsObject: @"SCRAM-SHA-1"]) {
			_authModule = [[XMPPSCRAMAuth alloc]
			    initWithAuthcid: _username
				   password: _password
				 connection: self
				       hash: [OFSHA1Hash class]
			      plusAvailable: false];
			[self xmpp_sendAuth: @"SCRAM-SHA-1"];
			return;
		}

		if ([mechanisms containsObject: @"PLAIN"] && _encrypted) {
			_authModule = [[XMPPPLAINAuth alloc]
			    initWithAuthcid: _username
				   password: _password];
			[self xmpp_sendAuth: @"PLAIN"];
			return;
		}

		@throw [XMPPAuthFailedException
		    exceptionWithConnection: self
				     reason: @"No supported auth mechanism"];

	}

	if (session != nil && [session elementForName: @"optional"
					    namespace: XMPPSessionNS] == nil)
		_needsSession = true;

	if (bind != nil) {
		[self xmpp_sendResourceBind];
		return;
	}

	assert(0);
}

- (void)xmpp_sendAuth: (OFString *)authName
{
	OFXMLElement *authTag;
	OFData *initialMessage = [_authModule initialMessage];

	authTag = [OFXMLElement elementWithName: @"auth" namespace: XMPPSASLNS];
	[authTag addAttributeWithName: @"mechanism" stringValue: authName];
	if (initialMessage != nil) {
		if (initialMessage.count == 0)
			authTag.stringValue = @"=";
		else
			authTag.stringValue =
			    initialMessage.stringByBase64Encoding;
	}

	[self sendStanza: authTag];
}

- (void)xmpp_sendResourceBind
{
	XMPPIQ *IQ;
	OFXMLElement *bind;

	IQ = [XMPPIQ IQWithType: @"set" ID: [self generateStanzaID]];

	bind = [OFXMLElement elementWithName: @"bind" namespace: XMPPBindNS];

	if (_resource != nil)
		[bind addChild: [OFXMLElement elementWithName: @"resource"
						    namespace: XMPPBindNS
						  stringValue: _resource]];

	[IQ addChild: bind];

	[self	    sendIQ: IQ
	    callbackTarget: self
		  selector: @selector(xmpp_handleResourceBindForConnection:
				IQ:)];
}

- (void)xmpp_sendStreamError: (OFString *)condition
			text: (OFString *)text
{
	OFXMLElement *error = [OFXMLElement
	    elementWithName: @"error"
		  namespace: XMPPStreamNS];
	[error setPrefix: @"stream" forNamespace: XMPPStreamNS];
	[error addChild: [OFXMLElement elementWithName: condition
					     namespace: XMPPXMPPStreamNS]];
	if (text)
		[error	   addChild: [OFXMLElement
		    elementWithName: @"text"
			  namespace: XMPPXMPPStreamNS
			stringValue: text]];
	_parser.delegate = nil;
	[self sendStanza: error];
	[self close];
}

- (void)xmpp_handleResourceBindForConnection: (XMPPConnection *)connection
					  IQ: (XMPPIQ *)IQ
{
	OFXMLElement *bindElement, *JIDElement;

	assert([IQ.type isEqual: @"result"]);

	bindElement = [IQ elementForName: @"bind" namespace: XMPPBindNS];

	assert(bindElement != nil);

	JIDElement = [bindElement elementForName: @"jid" namespace: XMPPBindNS];
	_JID = [[XMPPJID alloc] initWithString: JIDElement.stringValue];

	if (_needsSession) {
		[self xmpp_sendSession];
		return;
	}

	[_delegates broadcastSelector: @selector(connection:wasBoundToJID:)
			   withObject: self
			   withObject: _JID];
}

- (void)xmpp_sendSession
{
	XMPPIQ *IQ = [XMPPIQ IQWithType: @"set" ID: [self generateStanzaID]];

	[IQ addChild: [OFXMLElement elementWithName: @"session"
					  namespace: XMPPSessionNS]];

	[self	    sendIQ: IQ
	    callbackTarget: self
		  selector: @selector(xmpp_handleSessionForConnection:IQ:)];
}

- (void)xmpp_handleSessionForConnection: (XMPPConnection *)connection
				     IQ: (XMPPIQ *)IQ
{
	if (![IQ.type isEqual: @"result"])
		OFEnsure(0);

	[_delegates broadcastSelector: @selector(connection:wasBoundToJID:)
			   withObject: self
			   withObject: _JID];
}

- (OFString *)xmpp_IDNAToASCII: (OFString *)domain
{
	OFString *ret;
	char *cDomain;
	Idna_rc rc;

	if ((rc = idna_to_ascii_8z(domain.UTF8String,
	    &cDomain, IDNA_USE_STD3_ASCII_RULES)) != IDNA_SUCCESS)
		@throw [XMPPIDNATranslationFailedException
		    exceptionWithConnection: self
				  operation: @"ToASCII"
				     string: domain];

	@try {
		ret = [[OFString alloc] initWithUTF8String: cDomain];
	} @finally {
		free(cDomain);
	}

	return ret;
}

- (void)setDataStorage: (id <XMPPStorage>)dataStorage
{
	if (_streamOpen)
		/* FIXME: Find a better exception! */
		@throw [OFInvalidArgumentException exception];

	_dataStorage = dataStorage;
}

- (id <XMPPStorage>)dataStorage
{
	return _dataStorage;
}

- (void)addDelegate: (id <XMPPConnectionDelegate>)delegate
{
	[_delegates addDelegate: delegate];
}

- (void)removeDelegate: (id <XMPPConnectionDelegate>)delegate
{
	[_delegates removeDelegate: delegate];
}

- (XMPPMulticastDelegate *)xmpp_delegates
{
	return _delegates;
}
@end
