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
#import "namespaces.h"

@implementation XMPPConnection
+ connection
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	@try {
		sock = [[OFTCPSocket alloc] init];
		port = 5222;
		encrypted = NO;
		streamOpen = NO;
		delegates = [[XMPPMulticastDelegate alloc] init];
		callbacks = [[OFMutableDictionary alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[sock release];
	[parser release];
	[elementBuilder release];
	[username release];
	[password release];
	[privateKeyFile release];
	[certificateFile release];
	[server release];
	[domain release];
	[resource release];
	[JID release];
	[delegates release];
	[callbacks release];
	[authModule release];

	[super dealloc];
}

- (void)setUsername: (OFString*)username_
{
	OFString *old = username;
	char *node;
	Stringprep_rc rc;

	if ((rc = stringprep_profile([username_ UTF8String], &node,
	    "SASLprep", 0)) != STRINGPREP_OK)
		@throw [XMPPStringPrepFailedException
		    exceptionWithClass: isa
			    connection: self
			       profile: @"SASLprep"
				string: username_];

	@try {
		username = [[OFString alloc] initWithUTF8String: node];
	} @finally {
		free(node);
	}

	[old release];
}

- (OFString*)username
{
	return [[username copy] autorelease];
}

- (void)setResource: (OFString*)resource_
{
	OFString *old = resource;
	char *res;
	Stringprep_rc rc;

	if ((rc = stringprep_profile([resource_ UTF8String], &res,
	    "Resourceprep", 0)) != STRINGPREP_OK)
		@throw [XMPPStringPrepFailedException
		    exceptionWithClass: isa
			    connection: self
			       profile: @"Resourceprep"
				string: resource_];

	@try {
		resource = [[OFString alloc] initWithUTF8String: res];
	} @finally {
		free(res);
	}

	[old release];
}

- (OFString*)resource
{
	return [[resource copy] autorelease];
}

- (void)setServer: (OFString*)server_
{
	OFString *old = server;
	server = [self XMPP_IDNAToASCII: server_];
	[old release];
}

- (OFString*)server
{
	return [[server copy] autorelease];
}

- (void)setDomain: (OFString*)domain_
{
	OFString *oldDomain = domain;
	OFString *oldDomainToASCII = domainToASCII;
	char *srv;
	Stringprep_rc rc;

	if ((rc = stringprep_profile([domain_ UTF8String], &srv,
	    "Nameprep", 0)) != STRINGPREP_OK)
		@throw [XMPPStringPrepFailedException
		    exceptionWithClass: isa
			    connection: self
			       profile: @"Nameprep"
				string: domain_];

	@try {
		domain = [[OFString alloc] initWithUTF8String: srv];
	} @finally {
		free(srv);
	}
	[oldDomain release];

	domainToASCII = [self XMPP_IDNAToASCII: domain];
	[oldDomainToASCII release];
}

- (OFString*)domain
{
	return [[domain copy] autorelease];
}

- (void)setPassword: (OFString*)password_
{
	OFString *old = password;
	char *pass;
	Stringprep_rc rc;

	if ((rc = stringprep_profile([password_ UTF8String], &pass,
	    "SASLprep", 0)) != STRINGPREP_OK)
		@throw [XMPPStringPrepFailedException
		    exceptionWithClass: isa
			    connection: self
			       profile: @"SASLprep"
				string: password_];

	@try {
		password = [[OFString alloc] initWithUTF8String: pass];
	} @finally {
		free(pass);
	}

	[old release];
}

- (OFString*)password
{
	return [[password copy] autorelease];
}

- (void)setPrivateKeyFile: (OFString*)file
{
	OF_SETTER(privateKeyFile, file, YES, YES)
}

- (OFString*)privateKeyFile
{
	OF_GETTER(privateKeyFile, YES)
}

- (void)setCertificateFile: (OFString*)file
{
	OF_SETTER(certificateFile, file, YES, YES)
}

- (OFString*)certificateFile
{
	OF_GETTER(certificateFile, YES)
}

- (void)connect
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	XMPPSRVEntry *candidate = nil;
	XMPPSRVLookup *SRVLookup = nil;
	OFEnumerator *enumerator;

	if (server)
		[sock connectToHost: server
			       port: port];
	else {
		@try {
			SRVLookup = [XMPPSRVLookup
			    lookupWithDomain: domainToASCII];
		} @catch (id e) {
		}

		enumerator = [SRVLookup objectEnumerator];

		/* Iterate over SRV records, if any */
		if ((candidate = [enumerator nextObject]) != nil) {
			do {
				@try {
					[sock connectToHost: [candidate target]
						       port: [candidate port]];
					break;
				} @catch (OFAddressTranslationFailedException
				    *e) {
				} @catch (OFConnectionFailedException *e) {
				}
			} while ((candidate = [enumerator nextObject]) != nil);
		} else
			/* No SRV records -> fall back to A / AAAA record */
			[sock connectToHost: domainToASCII
				       port: port];
	}

	[self XMPP_startStream];

	[pool release];
}

- (void)handleConnection
{
	char buffer[512];

	for (;;) {
		size_t length = [sock readNBytes: 512
				      intoBuffer: buffer];

		[self parseBuffer: buffer
		       withLength: length];

		if (length < 1)
			return;
	}
}

- (void)parseBuffer: (const char*)buffer
	 withLength: (size_t)length
{
	if (length < 1) {
		[delegates broadcastSelector: @selector(connectionWasClosed:)
			       forConnection: self];
		return;
	}

	[parser parseBuffer: buffer
		 withLength: length];

	[oldParser release];
	[oldElementBuilder release];

	oldParser = nil;
	oldElementBuilder = nil;
}

- (OFTCPSocket*)socket
{
	return [[sock retain] autorelease];
}

- (BOOL)encryptionRequired
{
	return encryptionRequired;
}

- (void)setEncryptionRequired: (BOOL)required
{
	encryptionRequired = required;
}

- (BOOL)encrypted
{
	return encrypted;
}

- (BOOL)streamOpen
{
	return streamOpen;
}

- (void)checkCertificate
{
	X509Certificate *cert;
	OFDictionary *SANs;
	BOOL serviceSpecific = NO;

	[sock verifyPeerCertificate];
	cert = [sock peerCertificate];
	SANs = [cert subjectAlternativeName];

	if ([[SANs objectForKey: @"otherName"]
		objectForKey: OID_SRVName] ||
	     [SANs objectForKey: @"dNSName"] ||
	     [SANs objectForKey: @"uniformResourceIdentifier"])
		serviceSpecific = YES;

	if ([cert hasSRVNameMatchingDomain: domainToASCII
				   service: @"xmpp-client"] ||
	    [cert hasDNSNameMatchingDomain: domainToASCII])
		return;

	if (serviceSpecific ||
	    ![cert hasCommonNameMatchingDomain: domainToASCII])
		@throw [SSLInvalidCertificateException
		    exceptionWithClass: isa
				reason: @"No matching identifier"];
}

- (void)sendStanza: (OFXMLElement*)element
{
	[delegates broadcastSelector: @selector(connection:didSendElement:)
		       forConnection: self
			  withObject: element];

	[sock writeString: [element XMLString]];
}

-	(void)sendIQ: (XMPPIQ*)iq
  withCallbackObject: (id)object
	    selector: (SEL)selector
{
	OFAutoreleasePool *pool;
	XMPPCallback *callback;

	if (![iq ID])
		[iq setID: [self generateStanzaID]];

	pool = [[OFAutoreleasePool alloc] init];
	callback = [XMPPCallback callbackWithCallbackObject: object
						   selector: selector];
	[callbacks setObject: callback
		      forKey: [iq ID]];
	[pool release];

	[self sendStanza: iq];
}

#ifdef OF_HAVE_BLOCKS
-      (void)sendIQ: (XMPPIQ*)iq
  withCallbackBlock: (xmpp_callback_block_t)block;
{
	OFAutoreleasePool *pool;
	XMPPCallback *callback;

	if (![iq ID])
		[iq setID: [self generateStanzaID]];

	pool = [[OFAutoreleasePool alloc] init];
	callback = [XMPPCallback callbackWithCallbackBlock: block];
	[callbacks setObject: callback
		      forKey: [iq ID]];
	[pool release];

	[self sendStanza: iq];
}
#endif

- (OFString*)generateStanzaID
{
	return [OFString stringWithFormat: @"objxmpp_%u", lastID++];
}

-    (void)parser: (OFXMLParser*)p
  didStartElement: (OFString*)name
       withPrefix: (OFString*)prefix
	namespace: (OFString*)ns
       attributes: (OFArray*)attributes
{
	OFEnumerator *enumerator;
	OFXMLAttribute *attribute;

	if (![name isEqual: @"stream"]) {
		// No dedicated stream error for this, may not even be XMPP
		[self close];
		[sock close];
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
		    ![[attribute stringValue] isEqual: domain]) {
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

	[parser setDelegate: elementBuilder];
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

	[delegates broadcastSelector: @selector(connection:didReceiveElement:)
		       forConnection: self
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

- (void)elementBuilder: (OFXMLElementBuilder *)builder
  didNotExpectCloseTag: (OFString *)name
	    withPrefix: (OFString *)prefix
	     namespace: (OFString *)ns
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
	/* Make sure we don't get any old events */
	[parser setDelegate: nil];
	[elementBuilder setDelegate: nil];

	/*
	 * We can't release them now, as we are currently inside them. Release
	 * them the next time the parser returns.
	 */
	oldParser = parser;
	oldElementBuilder = elementBuilder;

	parser = [[OFXMLParser alloc] init];
	[parser setDelegate: self];

	elementBuilder = [[OFXMLElementBuilder alloc] init];
	[elementBuilder setDelegate: self];

	[sock writeFormat: @"<?xml version='1.0'?>\n"
			   @"<stream:stream to='%@' "
			   @"xmlns='" XMPP_NS_CLIENT @"' "
			   @"xmlns:stream='" XMPP_NS_STREAM @"' "
			   @"version='1.0'>", domain];
	streamOpen = YES;
}

- (void)close
{
	if (streamOpen) {
		[sock writeString: @"</stream:stream>"];
		streamOpen = NO;
	}
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
		[sock close]; // Remote has already closed his stream

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

		@throw [XMPPStreamErrorException exceptionWithClass: isa
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

		[delegates broadcastSelector: @selector(
						  connectionWillUpgradeToTLS:)
			       forConnection: self];

		newSock = [[SSLSocket alloc] initWithSocket: sock
					     privateKeyFile: privateKeyFile
					    certificateFile: certificateFile];
		[sock release];
		sock = newSock;

		encrypted = YES;

		[delegates broadcastSelector: @selector(
						  connectionDidUpgradeToTLS:)
			       forConnection: self];

		/* Stream restart */
		[self XMPP_startStream];

		return;
	}

	if ([[element name] isEqual: @"failure"])
		/* TODO: Find/create an exception to throw here */
		@throw [OFException exceptionWithClass: isa];

	assert(0);
}

- (void)XMPP_handleSASL: (OFXMLElement*)element
{
	if ([[element name] isEqual: @"challenge"]) {
		OFXMLElement *responseTag;
		OFDataArray *challenge = [OFDataArray
		    dataArrayWithBase64EncodedString: [element stringValue]];
		OFDataArray *response = [authModule
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
		[authModule continueWithData: [OFDataArray
		    dataArrayWithBase64EncodedString: [element stringValue]]];

		[delegates broadcastSelector: @selector(
						  connectionWWasAuthenticated:)
			       forConnection: self];

		/* Stream restart */
		[self XMPP_startStream];

		return;
	}

	if ([[element name] isEqual: @"failure"]) {
		of_log(@"Auth failed!");
		// FIXME: Do more parsing/handling
		@throw [XMPPAuthFailedException
		    exceptionWithClass: isa
			    connection: self
				reason: [element XMLString]];
	}

	assert(0);
}

- (void)XMPP_handleIQ: (XMPPIQ*)iq
{
	BOOL handled = NO;
	XMPPCallback *callback;

	if ((callback = [callbacks objectForKey: [iq ID]])) {
		[callback runWithIQ: iq];
		[callbacks removeObjectForKey: [iq ID]];
		return;
	}

	handled = [delegates broadcastSelector: @selector(
						    connection:didReceiveIQ:)
				 forConnection: self
				    withObject: iq];

	if (!handled && ![[iq type] isEqual: @"error"] &&
	    ![[iq type] isEqual: @"result"]) {
		[self sendStanza: [iq errorIQWithType: @"cancel"
					    condition: @"service-unavailable"]];
	}
}

- (void)XMPP_handleMessage: (XMPPMessage*)message
{
	[delegates broadcastSelector: @selector(connection:didReceiveMessage:)
		       forConnection: self
			  withObject: message];
}

- (void)XMPP_handlePresence: (XMPPPresence*)presence
{
	[delegates broadcastSelector: @selector(connection:didReceivePresence:)
		       forConnection: self
			  withObject: presence];
}

- (void)XMPP_handleFeatures: (OFXMLElement*)element
{
	OFXMLElement *starttls = [element elementForName: @"starttls"
					       namespace: XMPP_NS_STARTTLS];
	OFXMLElement *bind = [element elementForName: @"bind"
					   namespace: XMPP_NS_BIND];
	OFXMLElement *session = [element elementForName: @"session"
					      namespace: XMPP_NS_SESSION];
	OFXMLElement *mechs = [element elementForName: @"mechanisms"
					    namespace: XMPP_NS_SASL];
	OFMutableSet *mechanisms = [OFMutableSet set];

	if (starttls != nil) {
		[self sendStanza:
		    [OFXMLElement elementWithName: @"starttls"
					namespace: XMPP_NS_STARTTLS]];
		return;
	}

	if (encryptionRequired && !encrypted)
		/* TODO: Find/create an exception to throw here */
		@throw [OFException exceptionWithClass: isa];

	if (mechs != nil) {
		OFEnumerator *enumerator;
		OFXMLElement *mech;

		enumerator = [[mechs children] objectEnumerator];
		while ((mech = [enumerator nextObject]) != nil)
			[mechanisms addObject: [mech stringValue]];

		if (privateKeyFile && certificateFile &&
		    [mechanisms containsObject: @"EXTERNAL"]) {
			authModule = [[XMPPEXTERNALAuth alloc] init];
			[self XMPP_sendAuth: @"EXTERNAL"];
			return;
		}

		if ([mechanisms containsObject: @"SCRAM-SHA-1-PLUS"]) {
			authModule = [[XMPPSCRAMAuth alloc]
			    initWithAuthcid: username
				   password: password
				 connection: self
				       hash: [OFSHA1Hash class]
			      plusAvailable: YES];
			[self XMPP_sendAuth: @"SCRAM-SHA-1-PLUS"];
			return;
		}

		if ([mechanisms containsObject: @"SCRAM-SHA-1"]) {
			authModule = [[XMPPSCRAMAuth alloc]
			    initWithAuthcid: username
				   password: password
				 connection: self
				       hash: [OFSHA1Hash class]
			      plusAvailable: NO];
			[self XMPP_sendAuth: @"SCRAM-SHA-1"];
			return;
		}

		if ([mechanisms containsObject: @"PLAIN"] && encrypted) {
			authModule = [[XMPPPLAINAuth alloc]
			    initWithAuthcid: username
				   password: password];
			[self XMPP_sendAuth: @"PLAIN"];
			return;
		}

		assert(0);
	}

	if (session != nil)
		needsSession = YES;

	if (bind != nil) {
		[self XMPP_sendResourceBind];
		return;
	}

	assert(0);
}

- (void)XMPP_sendAuth: (OFString*)authName
{
	OFXMLElement *authTag;
	OFDataArray *initialMessage = [authModule initialMessage];

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
	XMPPIQ *iq;
	OFXMLElement *bind;

	iq = [XMPPIQ IQWithType: @"set"
			     ID: [self generateStanzaID]];

	bind = [OFXMLElement elementWithName: @"bind"
				   namespace: XMPP_NS_BIND];

	if (resource != nil)
		[bind addChild: [OFXMLElement elementWithName: @"resource"
						    namespace: XMPP_NS_BIND
						  stringValue: resource]];

	[iq addChild: bind];

	[self		sendIQ: iq
	    withCallbackObject: self
		      selector: @selector(XMPP_handleResourceBind:)];
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
	[parser setDelegate: nil];
	[self sendStanza: error];
	[self close];
}

- (void)XMPP_handleResourceBind: (XMPPIQ*)iq
{
	OFXMLElement *bindElement;
	OFXMLElement *jidElement;

	assert([[iq type] isEqual: @"result"]);

	bindElement = [iq elementForName: @"bind"
			       namespace: XMPP_NS_BIND];

	assert(bindElement != nil);

	jidElement = [bindElement elementForName: @"jid"
				       namespace: XMPP_NS_BIND];
	JID = [[XMPPJID alloc] initWithString: [jidElement stringValue]];

	if (needsSession) {
		[self XMPP_sendSession];
		return;
	}

	[delegates broadcastSelector: @selector(connection:wasBoundToJID:)
		       forConnection: self
			  withObject: JID];
}

- (void)XMPP_sendSession
{
	XMPPIQ *iq;

	iq = [XMPPIQ IQWithType: @"set"
			     ID: [self generateStanzaID]];
	[iq addChild: [OFXMLElement elementWithName: @"session"
					  namespace: XMPP_NS_SESSION]];
	[self		sendIQ: iq
	    withCallbackObject: self
		      selector: @selector(XMPP_handleSession:)];
}

- (void)XMPP_handleSession: (XMPPIQ*)iq
{
	if (![[iq type] isEqual: @"result"])
		assert(0);

	[delegates broadcastSelector: @selector(connection:wasBoundToJID:)
		       forConnection: self
			  withObject: JID];
}

- (OFString*)XMPP_IDNAToASCII: (OFString*)domain_
{
	OFString *ret;
	char *cDomain;
	Idna_rc rc;

	if ((rc = idna_to_ascii_8z([domain_ UTF8String],
	    &cDomain, IDNA_USE_STD3_ASCII_RULES)) != IDNA_SUCCESS)
		@throw [XMPPIDNATranslationFailedException
		    exceptionWithClass: isa
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
	return [[JID copy] autorelease];
}

- (void)setPort: (uint16_t)port_
{
	port = port_;
}

- (uint16_t)port
{
	return port;
}

- (void)addDelegate: (id <XMPPConnectionDelegate>)delegate
{
	[delegates addDelegate: delegate];
}

- (void)removeDelegate: (id <XMPPConnectionDelegate>)delegate
{
	[delegates removeDelegate: delegate];
}

- (XMPPMulticastDelegate*)XMPP_delegates
{
	return delegates;
}
@end

@implementation OFObject (XMPPConnectionDelegate)
-  (void)connection: (XMPPConnection*)connection
  didReceiveElement: (OFXMLElement*)element
{
}

- (void)connection: (XMPPConnection*)connection
    didSendElement: (OFXMLElement*)element
{
}

- (void)connectionWasAuthenticated: (XMPPConnection*)connection
{
}

- (void)connection: (XMPPConnection*)connection
     wasBoundToJID: (XMPPJID*)JID
{
}

- (BOOL)connection: (XMPPConnection*)connection
      didReceiveIQ: (XMPPIQ*)iq
{
	return NO;
}

-   (void)connection: (XMPPConnection*)connection
  didReceivePresence: (XMPPPresence*)presence
{
}

-  (void)connection: (XMPPConnection*)connection
  didReceiveMessage: (XMPPMessage*)message
{
}

- (void)connectionWasClosed: (XMPPConnection*)connection
{
}

- (void)connectionWillUpgradeToTLS: (XMPPConnection*)connection
{
}

- (void)connectionDidUpgradeToTLS: (XMPPConnection*)connection
{
}
@end
